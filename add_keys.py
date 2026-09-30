import json

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

def update_arb(file_path, new_translations, with_params=False):
    with open(file_path, 'r', encoding='utf-8') as f:
        arb = json.load(f)

    for k, v in new_translations.items():
        if k not in arb:
            arb[k] = v
            if with_params and "v{version}" in v:
                arb[f"@{k}"] = {
                    "description": "Current version display",
                    "placeholders": {
                        "version": {
                            "type": "String",
                            "example": "1.0.0"
                        }
                    }
                }

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(arb, f, indent=2, ensure_ascii=False)
        f.write('\n')

en_translations = {
    "settingsWhatsNew": "What's New",
    "settingsCurrentVersion": "Current Version: v{version}",
    "settingsNoPermissionsFound": "No permissions found.",
    "settingsFeature": "Feature",
    "languageEnglish": "English",
    "languageFrench": "Français",
    "languageArabic": "العربية",
    "languageItalian": "Italiano"
}

fr_translations = {
    "settingsWhatsNew": "Nouveautés",
    "settingsCurrentVersion": "Version actuelle : v{version}",
    "settingsNoPermissionsFound": "Aucune autorisation trouvée.",
    "settingsFeature": "Fonctionnalité",
    "languageEnglish": "English",
    "languageFrench": "Français",
    "languageArabic": "العربية",
    "languageItalian": "Italiano"
}

ar_translations = {
    "settingsWhatsNew": "ما الجديد",
    "settingsCurrentVersion": "الإصدار الحالي: v{version}",
    "settingsNoPermissionsFound": "لم يتم العثور على أذونات.",
    "settingsFeature": "الميزة",
    "languageEnglish": "English",
    "languageFrench": "Français",
    "languageArabic": "العربية",
    "languageItalian": "Italiano"
}

it_translations = {
    "settingsWhatsNew": "Novità",
    "settingsCurrentVersion": "Versione attuale: v{version}",
    "settingsNoPermissionsFound": "Nessuna autorizzazione trovata.",
    "settingsFeature": "Funzionalità",
    "languageEnglish": "English",
    "languageFrench": "Français",
    "languageArabic": "العربية",
    "languageItalian": "Italiano"
}

update_arb('lib/src/l10n/app_en.arb', en_translations, True)
update_arb('lib/src/l10n/app_fr.arb', fr_translations, False)
update_arb('lib/src/l10n/app_ar.arb', ar_translations, False)
update_arb('lib/src/l10n/app_it.arb', it_translations, False)
