import os

replacements = [
    (
        "lib/src/features/settings/settings_screen.dart",
        "Text(\"What's New\", style: theme.textTheme.headlineSmall)",
        "Text(AppLocalizations.of(context)!.t('settingsWhatsNew'), style: theme.textTheme.headlineSmall)"
    ),
    (
        "lib/src/features/settings/settings_screen.dart",
        "Text('Current Version: v$appVersion', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary))",
        "Text(AppLocalizations.of(context)!.tParams('settingsCurrentVersion', {'version': appVersion}), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary))"
    ),
    (
        "lib/src/features/settings/settings_screen.dart",
        "DropdownMenuItem(value: Locale('en'), child: Text('English'))",
        "DropdownMenuItem(value: const Locale('en'), child: Text(AppLocalizations.of(context)!.t('languageEnglish')))"
    ),
    (
        "lib/src/features/settings/settings_screen.dart",
        "DropdownMenuItem(value: Locale('fr'), child: Text('Français'))",
        "DropdownMenuItem(value: const Locale('fr'), child: Text(AppLocalizations.of(context)!.t('languageFrench')))"
    ),
    (
        "lib/src/features/settings/settings_screen.dart",
        "DropdownMenuItem(value: Locale('ar'), child: Text('العربية'))",
        "DropdownMenuItem(value: const Locale('ar'), child: Text(AppLocalizations.of(context)!.t('languageArabic')))"
    ),
    (
        "lib/src/features/settings/settings_screen.dart",
        "DropdownMenuItem(value: Locale('it'), child: Text('Italiano'))",
        "DropdownMenuItem(value: const Locale('it'), child: Text(AppLocalizations.of(context)!.t('languageItalian')))"
    ),
    (
        "lib/src/features/auth/login_screen.dart",
        "DropdownMenuItem(value: 'en', child: Text('EN'))",
        "DropdownMenuItem(value: 'en', child: Text(l10n.t('languageEnglish')))"
    ),
    (
        "lib/src/features/auth/login_screen.dart",
        "DropdownMenuItem(value: 'fr', child: Text('FR'))",
        "DropdownMenuItem(value: 'fr', child: Text(l10n.t('languageFrench')))"
    ),
    (
        "lib/src/features/auth/login_screen.dart",
        "DropdownMenuItem(value: 'ar', child: Text('AR'))",
        "DropdownMenuItem(value: 'ar', child: Text(l10n.t('languageArabic')))"
    ),
    (
        "lib/src/features/auth/login_screen.dart",
        "DropdownMenuItem(value: 'it', child: Text('IT'))",
        "DropdownMenuItem(value: 'it', child: Text(l10n.t('languageItalian')))"
    ),
    (
        "lib/src/features/settings/role_permissions_screen.dart",
        "return const Center(child: Text(\"No permissions found.\"));",
        "return Center(child: Text(AppLocalizations.of(context)!.t('settingsNoPermissionsFound')));"
    ),
    (
        "lib/src/features/settings/role_permissions_screen.dart",
        "DataColumn(label: Text('Feature', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)))",
        "DataColumn(label: Text(AppLocalizations.of(context)!.t('settingsFeature'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)))"
    )
]

for file_path, search_str, replace_str in replacements:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    if search_str in content:
        content = content.replace(search_str, replace_str)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Replaced in {file_path}")
    else:
        print(f"NOT FOUND in {file_path}: {search_str}")
