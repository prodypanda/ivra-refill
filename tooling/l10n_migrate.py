#!/usr/bin/env python3
"""One-shot migration helper.

Parses the hand-maintained `_values` map in
`lib/src/l10n/app_localizations.dart` and emits:
  - lib/src/l10n/app_en.arb, app_fr.arb, app_ar.arb, app_it.arb
  - lib/src/l10n/app_localizations_values.g.dart  (the same data as a Dart
    map, used by the back-compat `t()` shim so existing call sites keep
    working without churn).

It also prints, per non-English locale, which keys were missing relative to
English and therefore backfilled with the English source string.

This is a mechanical conversion: string values are preserved byte-for-byte.
"""

import json
import re
import sys
from collections import OrderedDict

SRC = "lib/src/l10n/app_localizations_values.g.dart"
LOCALES = ["en", "fr", "ar", "it"]


def read_source():
    with open(SRC, "r", encoding="utf-8") as f:
        return f.read()


def find_block(text, locale):
    """Return the substring between `'<locale>': {` and its matching `}`."""
    start_marker = "  '%s': {" % locale
    idx = text.index(start_marker)
    # position right after the opening brace line
    brace_start = text.index("{", idx)
    depth = 0
    i = brace_start
    in_str = False
    quote = ""
    escape = False
    while i < len(text):
        c = text[i]
        if in_str:
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == quote:
                in_str = False
        else:
            if c in ("'", '"'):
                in_str = True
                quote = c
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return text[brace_start + 1 : i]
        i += 1
    raise RuntimeError("Unterminated block for locale %s" % locale)


def parse_dart_string(text, i):
    """Parse a Dart single- or double-quoted string starting at index i
    (which must point at the opening quote). Returns (value, next_index).
    Handles escapes and adjacent string concatenation (implicit) is NOT
    handled here; see parse_value for multi-literal concatenation."""
    quote = text[i]
    assert quote in ("'", '"')
    i += 1
    out = []
    while i < len(text):
        c = text[i]
        if c == "\\":
            if i + 1 >= len(text):
                raise RuntimeError("Unexpected end of input after backslash in string literal")
            nxt = text[i + 1]
            mapping = {
                "n": "\n",
                "t": "\t",
                "r": "\r",
                "\\": "\\",
                "'": "'",
                '"': '"',
                "$": "$",
                "b": "\b",
                "f": "\f",
            }
            if nxt == "u":
                if text[i + 2] == "{":
                    end = text.index("}", i + 2)
                    code = int(text[i + 3 : end], 16)
                    out.append(chr(code))
                    i = end + 1
                    continue
                else:
                    code = int(text[i + 2 : i + 6], 16)
                    out.append(chr(code))
                    i += 6
                    continue
            elif nxt in mapping:
                out.append(mapping[nxt])
                i += 2
                continue
            else:
                out.append(nxt)
                i += 2
                continue
        elif c == quote:
            return "".join(out), i + 1
        else:
            out.append(c)
            i += 1
    raise RuntimeError("Unterminated string literal")


def parse_block(block):
    """Parse `'key': 'value',` entries (value may span multiple adjacent
    string literals joined by Dart implicit concatenation)."""
    result = OrderedDict()
    i = 0
    n = len(block)
    while i < n:
        c = block[i]
        if c in " \t\r\n,":
            i += 1
            continue
        if c in ("'", '"'):
            key, i = parse_dart_string(block, i)
            # skip whitespace then ':'
            while block[i] in " \t\r\n":
                i += 1
            assert block[i] == ":", "expected ':' after key %r" % key
            i += 1
            # parse value: one or more adjacent string literals
            parts = []
            while True:
                while i < n and block[i] in " \t\r\n":
                    i += 1
                if i < n and block[i] in ("'", '"'):
                    part, i = parse_dart_string(block, i)
                    parts.append(part)
                else:
                    break
            result[key] = "".join(parts)
            # skip to comma
            while i < n and block[i] != ",":
                if block[i] not in " \t\r\n":
                    raise RuntimeError("unexpected token after value for %r: %r" % (key, block[i]))
                i += 1
        else:
            raise RuntimeError("unexpected token at %d: %r" % (i, c))
    return result


PLACEHOLDER_RE = re.compile(r"\{(\w+)\}")


def placeholders_for(value):
    seen = []
    for m in PLACEHOLDER_RE.finditer(value):
        if m.group(1) not in seen:
            seen.append(m.group(1))
    return seen


def build_arb(locale, data, is_template):
    arb = OrderedDict()
    arb["@@locale"] = locale
    for key, value in data.items():
        arb[key] = value
        if is_template:
            phs = placeholders_for(value)
            if phs:
                meta = OrderedDict()
                meta["placeholders"] = OrderedDict(
                    (p, {"type": "String"}) for p in phs
                )
                arb["@" + key] = meta
    return arb


def main():
    text = read_source()
    blocks = {loc: parse_block(find_block(text, loc)) for loc in LOCALES}

    en = blocks["en"]

    # Audit + backfill
    report = {}
    for loc in ["fr", "ar", "it"]:
        missing = [k for k in en if k not in blocks[loc]]
        report[loc] = missing
        for k in missing:
            blocks[loc][k] = en[k]  # backfill with English source
        # also surface extra keys (present in locale but not en) for info
    extras = {}
    for loc in ["fr", "ar", "it"]:
        extras[loc] = [k for k in blocks[loc] if k not in en]

    # Re-order every locale to match en key order for clean diffs.
    for loc in LOCALES:
        ordered = OrderedDict()
        for k in en:
            ordered[k] = blocks[loc][k]
        # append any locale-only extras at the end (preserve them)
        for k in blocks[loc]:
            if k not in ordered:
                ordered[k] = blocks[loc][k]
        blocks[loc] = ordered

    # Write ARB files
    for loc in LOCALES:
        arb = build_arb(loc, blocks[loc], is_template=(loc == "en"))
        path = "lib/src/l10n/app_%s.arb" % loc
        with open(path, "w", encoding="utf-8") as f:
            json.dump(arb, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print("wrote %s (%d keys)" % (path, len(blocks[loc])))

    # Write the Dart values map used by the t() shim.
    write_values_dart(blocks)

    # Print audit report
    print("\n=== MISSING KEYS REPORT (backfilled with English) ===")
    for loc in ["fr", "ar", "it"]:
        print("\n[%s] missing %d key(s):" % (loc, len(report[loc])))
        for k in report[loc]:
            print("  - %s" % k)
    print("\n=== LOCALE-ONLY EXTRA KEYS (kept) ===")
    for loc in ["fr", "ar", "it"]:
        if extras[loc]:
            print("[%s] extra: %s" % (loc, ", ".join(extras[loc])))

    # Save machine-readable report
    with open("tooling/l10n_missing_report.json", "w", encoding="utf-8") as f:
        json.dump({"missing": report, "extras": extras}, f, ensure_ascii=False, indent=2)
        f.write("\n")


def dart_escape(s):
    s = s.replace("\\", "\\\\")
    s = s.replace("'", "\\'")
    s = s.replace("\n", "\\n")
    s = s.replace("\r", "\\r")
    s = s.replace("\t", "\\t")
    s = s.replace("$", "\\$")
    return s


def write_values_dart(blocks):
    lines = []
    lines.append("// GENERATED FILE - DO NOT EDIT BY HAND.")
    lines.append("//")
    lines.append("// Regenerate with: python3 tooling/l10n_migrate.py")
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
    path = "lib/src/l10n/app_localizations_values.g.dart"
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("wrote %s" % path)


if __name__ == "__main__":
    main()
