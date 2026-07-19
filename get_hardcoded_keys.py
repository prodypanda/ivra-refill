import json

arb = json.load(open('lib/src/l10n/app_en.arb', 'r'))
keys = arb.keys()

new_keys = {
    "settingsWhatsNew": "What's New",
    "settingsCurrentVersion": "Current Version: v{version}",
    "settingsNoPermissionsFound": "No permissions found.",
    "settingsFeature": "Feature",
    "languageEnglish": "English",
    "languageFrench": "Français",
    "languageArabic": "العربية",
    "languageItalian": "Italiano"
}

for k, v in new_keys.items():
    if k not in keys:
        print(f'"{k}": "{v}",')
