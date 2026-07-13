import json
import re

def load_arb(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        return json.load(f)

en_arb = load_arb('lib/src/l10n/app_en.arb')
fr_arb = load_arb('lib/src/l10n/app_fr.arb')
ar_arb = load_arb('lib/src/l10n/app_ar.arb')
it_arb = load_arb('lib/src/l10n/app_it.arb')

def get_icu_params(text):
    # Match basic {param} and also {param, plural, ...} and {param, select, ...}
    # It just looks for word characters right after '{'
    if not isinstance(text, str):
        return set()
    return set(re.findall(r'\{([a-zA-Z0-9_]+)', text))

print("Checking ICU parameters...")
keys = [k for k in en_arb.keys() if not k.startswith('@')]
for key in keys:
    en_val = en_arb[key]
    en_params = get_icu_params(en_val)

    fr_val = fr_arb.get(key, '')
    fr_params = get_icu_params(fr_val)
    if en_params != fr_params:
        print(f"Mismatch in FR for key '{key}': EN={en_params}, FR={fr_params}")

    ar_val = ar_arb.get(key, '')
    ar_params = get_icu_params(ar_val)
    if en_params != ar_params:
        print(f"Mismatch in AR for key '{key}': EN={en_params}, AR={ar_params}")

    it_val = it_arb.get(key, '')
    it_params = get_icu_params(it_val)
    if en_params != it_params:
        print(f"Mismatch in IT for key '{key}': EN={en_params}, IT={it_params}")
