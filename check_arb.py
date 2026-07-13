import json

def load_arb(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        return json.load(f)

en_arb = load_arb('lib/src/l10n/app_en.arb')
fr_arb = load_arb('lib/src/l10n/app_fr.arb')
ar_arb = load_arb('lib/src/l10n/app_ar.arb')
it_arb = load_arb('lib/src/l10n/app_it.arb')

en_keys = {k for k in en_arb.keys() if not k.startswith('@')}
fr_keys = {k for k in fr_arb.keys() if not k.startswith('@')}
ar_keys = {k for k in ar_arb.keys() if not k.startswith('@')}
it_keys = {k for k in it_arb.keys() if not k.startswith('@')}

print("Missing in FR:", en_keys - fr_keys)
print("Missing in AR:", en_keys - ar_keys)
print("Missing in IT:", en_keys - it_keys)

print("Orphan in FR:", fr_keys - en_keys)
print("Orphan in AR:", ar_keys - en_keys)
print("Orphan in IT:", it_keys - en_keys)
