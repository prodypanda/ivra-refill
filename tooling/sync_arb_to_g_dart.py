#!/usr/bin/env python3
import json
import os

LOCALES = ["en", "fr", "ar", "it"]
BASE_DIR = "lib/src/l10n"
G_DART_PATH = os.path.join(BASE_DIR, "app_localizations_values.g.dart")

def dart_escape(s):
    s = s.replace("\\", "\\\\")
    s = s.replace("'", "\\'")
    s = s.replace("\n", "\\n")
    s = s.replace("\r", "\\r")
    s = s.replace("\t", "\\t")
    s = s.replace("$", "\\$")
    return s

def main():
    blocks = {}
    
    # Read each ARB file
    for loc in LOCALES:
        path = os.path.join(BASE_DIR, f"app_{loc}.arb")
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        # Filter out metadata keys (starting with @)
        filtered = {k: v for k, v in data.items() if not k.startswith("@") and k != "@@locale"}
        blocks[loc] = filtered
        print(f"Loaded {path} with {len(filtered)} keys.")

    # We use 'en' as the reference for ordering and backfilling
    en_keys = list(blocks["en"].keys())

    # Backfill missing keys in other locales with the English value
    for loc in ["fr", "ar", "it"]:
        missing = [k for k in en_keys if k not in blocks[loc]]
        if missing:
            print(f"Locale '{loc}' is missing {len(missing)} keys. Backfilling with English values:")
            for k in missing:
                blocks[loc][k] = blocks["en"][k]
                print(f"  - {k}")
        
        # Ensure exact same key order as 'en' for consistency
        ordered = {}
        for k in en_keys:
            ordered[k] = blocks[loc][k]
        
        # Append any extra keys present only in that locale
        for k in blocks[loc]:
            if k not in ordered:
                ordered[k] = blocks[loc][k]
                
        blocks[loc] = ordered

    # Re-verify and align English itself
    ordered_en = {k: blocks["en"][k] for k in en_keys}
    blocks["en"] = ordered_en

    # Write out the generated dart file
    lines = []
    lines.append("// GENERATED FILE - DO NOT EDIT BY HAND.")
    lines.append("//")
    lines.append("// Regenerate with: python tooling/sync_arb_to_g_dart.py")
    lines.append("//")
    lines.append("// This map mirrors the ARB files in this directory and backs the")
    lines.append("// backward-compatible AppLocalizations.t()/tParams() shim so existing")
    lines.append("// call sites keep working after the ARB + gen_l10n migration.")
    lines.append("")
    lines.append("const Map<String, Map<String, String>> kL10nValues = {")
    for loc in LOCALES:
        lines.append("  '%s': {" % loc)
        for k, v in blocks[loc].items():
            lines.append("    '%s': '%s'," % (dart_escape(k), dart_escape(v)))
        lines.append("  },")
    lines.append("};")
    lines.append("")

    with open(G_DART_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
        
    print(f"Successfully wrote {G_DART_PATH}!")

if __name__ == "__main__":
    main()
