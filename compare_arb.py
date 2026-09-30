import json
import sys

def load_arb(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

en = load_arb('lib/src/l10n/app_en.arb')
fr = load_arb('lib/src/l10n/app_fr.arb')
ar = load_arb('lib/src/l10n/app_ar.arb')
it = load_arb('lib/src/l10n/app_it.arb')

def get_keys(arb):
    return {k for k in arb.keys() if not k.startswith('@')}

en_keys = get_keys(en)
fr_keys = get_keys(fr)
ar_keys = get_keys(ar)
it_keys = get_keys(it)

print("Keys missing in fr:", en_keys - fr_keys)
print("Keys missing in ar:", en_keys - ar_keys)
print("Keys missing in it:", en_keys - it_keys)

print("Orphan keys in fr:", fr_keys - en_keys)
print("Orphan keys in ar:", ar_keys - en_keys)
print("Orphan keys in it:", it_keys - en_keys)
