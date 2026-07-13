import json

def update_arb(filename, updates):
    with open(filename, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(updates)
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

en_updates = {
    "roleFeatureColumnLabel": "Feature",
    "@roleFeatureColumnLabel": {"description": "Column header for features in role permissions"},
    "roleNoPermissionsFound": "No permissions found.",
    "@roleNoPermissionsFound": {"description": "Empty state when no permissions match"},
    "settingsWhatsNew": "What's New",
    "@settingsWhatsNew": {"description": "Header for release notes"},
    "settingsCurrentVersion": "Current Version: v{version}",
    "@settingsCurrentVersion": {
        "description": "Shows current app version",
        "placeholders": {
            "version": {
                "type": "String",
                "example": "1.0.8"
            }
        }
    },
    "appShellBranding": "iVRA Refill, by Pulire Tunisia",
    "@appShellBranding": {"description": "Brand name in bottom sheet"},
    "authResetLinkSent": "Password reset link sent to {email}",
    "@authResetLinkSent": {
        "description": "Success message when reset link is sent",
        "placeholders": {
            "email": {
                "type": "String",
                "example": "user@example.com"
            }
        }
    }
}

fr_updates = {
    "roleFeatureColumnLabel": "Fonctionnalité",
    "roleNoPermissionsFound": "Aucune autorisation trouvée.",
    "settingsWhatsNew": "Quoi de neuf",
    "settingsCurrentVersion": "Version actuelle : v{version}",
    "appShellBranding": "iVRA Refill, par Pulire Tunisia",
    "authResetLinkSent": "Lien de réinitialisation envoyé à {email}"
}

ar_updates = {
    "roleFeatureColumnLabel": "الميزة",
    "roleNoPermissionsFound": "لم يتم العثور على أذونات.",
    "settingsWhatsNew": "ما الجديد",
    "settingsCurrentVersion": "الإصدار الحالي: v{version}",
    "appShellBranding": "iVRA Refill، بواسطة Pulire Tunisia",
    "authResetLinkSent": "تم إرسال رابط إعادة تعيين كلمة المرور إلى {email}"
}

it_updates = {
    "roleFeatureColumnLabel": "Funzionalità",
    "roleNoPermissionsFound": "Nessun permesso trovato.",
    "settingsWhatsNew": "Novità",
    "settingsCurrentVersion": "Versione attuale: v{version}",
    "appShellBranding": "iVRA Refill, da Pulire Tunisia",
    "authResetLinkSent": "Link di reimpostazione della password inviato a {email}"
}

update_arb('lib/src/l10n/app_en.arb', en_updates)
update_arb('lib/src/l10n/app_fr.arb', fr_updates)
update_arb('lib/src/l10n/app_ar.arb', ar_updates)
update_arb('lib/src/l10n/app_it.arb', it_updates)
