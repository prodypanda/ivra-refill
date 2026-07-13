1. Run `cat << 'INNER_EOF' > update_arb.py
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
INNER_EOF
python3 update_arb.py`
2. Run `git diff lib/src/l10n/` to verify the ARB file additions and modifications.
3. Run `flutter gen-l10n` to compile ARB files.
4. Run `python tooling/sync_arb_to_g_dart.py` to update `app_localizations_values.g.dart`.
5. Run `sed -i "s/Text('Feature'/Text(AppLocalizations.of(context)!.t('roleFeatureColumnLabel')/g" lib/src/features/settings/role_permissions_screen.dart` and `sed -i "s/const Center(child: Text(\"No permissions found.\"))/Center(child: Text(AppLocalizations.of(context)!.t('roleNoPermissionsFound')))/g" lib/src/features/settings/role_permissions_screen.dart`.
6. Run `git diff lib/src/features/settings/role_permissions_screen.dart` to verify the replacements.
7. Run `sed -i "s/Text(\"What's New\"/Text(l10n.t('settingsWhatsNew')/g" lib/src/features/settings/settings_screen.dart` and `sed -i "s/Text('Current Version: v\$appVersion'/Text(l10n.tParams('settingsCurrentVersion', {'version': appVersion.toString()})/g" lib/src/features/settings/settings_screen.dart`.
8. Run `git diff lib/src/features/settings/settings_screen.dart` to verify the replacements.
9. Run `sed -i "s/Text('\${l10n.t('authResetLinkSent')} \$email')/Text(l10n.tParams('authResetLinkSent', {'email': email.toString()}))/g" lib/src/features/auth/login_screen.dart`.
10. Run `git diff lib/src/features/auth/login_screen.dart` to verify the replacements.
11. Run `perl -0777 -pi -e "s/Text\(\s*'v\\\$appVersion'/Text(\n            l10n.tParams('settingsCurrentVersion', {'version': appVersion.toString()})/g" lib/src/features/shell/app_shell.dart` and `perl -0777 -pi -e "s/const Text\(\s*'iVRA Refill, by Pulire Tunisia'/Text(\n            l10n.t('appShellBranding')/g" lib/src/features/shell/app_shell.dart`.
12. Run `git diff lib/src/features/shell/app_shell.dart` to verify the replacements.
13. Run `pwsh .\scripts\verify_local.ps1 -Demo`.
14. Run `sed -i 's/version: 1.2.0+76/version: 1.2.0+77/g' pubspec.yaml` to bump version in `pubspec.yaml`, then run `pwsh ./scripts/generate_version.ps1`.
15. Run `git diff pubspec.yaml lib/src/version.dart` to verify version bump.
16. Run `flutter analyze` to ensure no syntax errors.
17. Run `flutter test test/l10n_completeness_test.dart` and verify no missing values.
18. Run `flutter test` to satisfy Completeness Rule.
19. Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
20. Run `git add .`, `git commit -m 'i18n: weekly localization sync — extracted 5 keys, verified RTL compatibility'`, and `gh pr create --base main --head resume-unfinished-devin-session` in `run_in_bash_session`.
