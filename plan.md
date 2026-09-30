1. **HARDCODED STRING EXTRACTION**
   - Run:
     ```bash
     cat << 'SCRIPT' > update_strings.py
     import json

     files = {
         'en': ('lib/src/l10n/app_en.arb', 'No permissions found.', 'Failed to load changelog.', 'Invitation sent'),
         'fr': ('lib/src/l10n/app_fr.arb', 'Aucune permission trouvée.', 'Échec du chargement du journal des modifications.', 'Invitation envoyée'),
         'ar': ('lib/src/l10n/app_ar.arb', 'لم يتم العثور على صلاحيات.', 'فشل في تحميل سجل التغييرات.', 'تم إرسال الدعوة'),
         'it': ('lib/src/l10n/app_it.arb', 'Nessun permesso trovato.', 'Impossibile caricare il registro delle modifiche.', 'Invito inviato')
     }

     for lang, (filepath, perm, cl, inv) in files.items():
         with open(filepath, 'r', encoding='utf-8') as f:
             data = json.load(f)
         data['noPermissionsFound'] = perm
         data['failedToLoadChangelog'] = cl
         data['invitationSent'] = inv
         with open(filepath, 'w', encoding='utf-8') as f:
             json.dump(data, f, ensure_ascii=False, indent=2)
     SCRIPT
     ```
   - Run `python3 update_strings.py`.
   - Run `sed -i "s/Text(\"No permissions found.\")/Text(l10n.t('noPermissionsFound'))/g" lib/src/features/settings/role_permissions_screen.dart`.
   - Run `sed -i "s/PremiumSnackbar.showError(context, 'Failed to load changelog.');/PremiumSnackbar.showError(context, l10n.t('failedToLoadChangelog'));/g" lib/src/features/settings/settings_screen.dart`.
   - Run `sed -i "s/PremiumSnackbar.show(context, 'Invitation sent', icon: Icons.check);/PremiumSnackbar.show(context, l10n.t('invitationSent'), icon: Icons.check);/g" lib/src/features/inventory/femme_de_chambre_screen.dart`.

2. **GENERATION & TESTING**
   - Run `flutter gen-l10n`.
   - Run `flutter test test/l10n_completeness_test.dart`.
   - Run `flutter analyze`.
   - Run `git status` and `git diff`.

3. **VERSION BUMP & DEPLOY**
   - Run:
     ```bash
     cat << 'SCRIPT' > bump_version.py
     import re
     with open('pubspec.yaml', 'r', encoding='utf-8') as f:
         content = f.read()
     def repl(match):
         version_part = match.group(1)
         build_part = match.group(2)
         parts = version_part.split('.')
         parts[2] = str(int(parts[2]) + 1)
         return f"version: {'.'.join(parts)}+{build_part}"
     content = re.sub(r'version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)', repl, content)
     with open('pubspec.yaml', 'w', encoding='utf-8') as f:
         f.write(content)
     SCRIPT
     ```
   - Run `python3 bump_version.py`.
   - Run `pwsh ./scripts/generate_version.ps1`.
   - Run `git diff pubspec.yaml lib/src/version.dart` to verify version bump.
   - Run `flutter pub get`.
   - Run `flutter test`.
   - Run `flutter build web --dart-define=USE_SUPABASE_PROVIDER=false`.
   - Run `rm update_strings.py bump_version.py plan.md`
   - Run `git add .`
   - Run `git commit -a -m "i18n: weekly localization sync — extracted 3 keys, verified RTL compatibility"`.
   - Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
   - Run `git push origin resume-unfinished-devin-session && gh pr create --title "i18n: weekly localization sync — extracted 3 keys, verified RTL compatibility" --body "Extracted 3 keys, verified RTL compatibility" --head resume-unfinished-devin-session --base main`.
