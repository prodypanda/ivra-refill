import json
import re
import sys

def parse_icu(text):
    # Find {var, type, ...}
    params = set()
    matches = re.findall(r'\{([a-zA-Z0-9_]+),\s*(plural|select)\s*,', text)
    for m in matches:
        params.add(m[0])

    # Find simple {var}
    matches2 = re.findall(r'\{([a-zA-Z0-9_]+)\}', text)
    for m in matches2:
        params.add(m)

    return params

def main():
    en = json.load(open('lib/src/l10n/app_en.arb', 'r', encoding='utf-8'))
    fr = json.load(open('lib/src/l10n/app_fr.arb', 'r', encoding='utf-8'))
    ar = json.load(open('lib/src/l10n/app_ar.arb', 'r', encoding='utf-8'))
    it = json.load(open('lib/src/l10n/app_it.arb', 'r', encoding='utf-8'))

    locales = [('fr', fr), ('ar', ar), ('it', it)]

    for key, en_val in en.items():
        if key.startswith('@'):
            continue

        en_params = parse_icu(en_val)

        for name, arb in locales:
            if key in arb:
                val = arb[key]
                params = parse_icu(val)
                if en_params != params:
                    print(f"Mismatch in {name} for key '{key}': EN={en_params}, {name.upper()}={params}")
                    print(f"EN: {en_val}")
                    print(f"{name.upper()}: {val}")
                    print("---")

if __name__ == '__main__':
    main()
