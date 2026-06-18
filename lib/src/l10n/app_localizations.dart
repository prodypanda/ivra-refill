import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/app_enums.dart';
import 'app_localizations_values.g.dart';

/// Backwards-compatibility shim over the ARB + `gen_l10n` localization system.
///
/// The app's string data now lives in the ARB files in this directory
/// (`app_en.arb`, `app_fr.arb`, `app_ar.arb`, `app_it.arb`). Running
/// `flutter gen-l10n` (also triggered by `flutter pub get` because
/// `flutter: generate: true` is set) produces a typed `AppL10n` class from
/// those ARB files.
///
/// This class is kept so the hundreds of existing call sites that use
/// `AppLocalizations.of(context).t('key')`, `.tParams(...)`, and the custom
/// enum-label helpers continue to work unchanged. Its runtime data comes from
/// [kL10nValues], which is generated from the exact same ARB files by
/// `tooling/l10n_migrate.py`, so the two stay in lockstep.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('it'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String t(String key) {
    return kL10nValues[locale.languageCode]?[key] ??
        kL10nValues['en']![key] ??
        key;
  }

  /// Resolves [key] and substitutes any `{name}` placeholders from [params].
  String tParams(String key, Map<String, String> params) {
    var value = t(key);
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  /// Localized label for an `AlertType` so the alert-type chip in the alerts
  /// list doesn't display hardcoded English to French/Arabic/Italian users.
  String alertTypeLabel(AlertType type) {
    switch (type) {
      case AlertType.lowBidonStock:
        return t('alertTypeLowBidonStock');
      case AlertType.lowBottleStock:
        return t('alertTypeLowBottleStock');
      case AlertType.bottleAgeLimit:
        return t('alertTypeBottleAgeLimit');
      case AlertType.refillLimit:
        return t('alertTypeRefillLimit');
      case AlertType.pendingApproval:
        return t('alertTypePendingApproval');
      case AlertType.suspiciousActivity:
        return t('alertTypeSuspiciousActivity');
      case AlertType.inactiveHotel:
        return t('alertTypeInactiveHotel');
    }
  }

  /// Localized label for a raw team-invitation status string (`pending`,
  /// `accepted`, `cancelled`, `expired`). Unknown values fall back to the
  /// original string so we never silently swallow new statuses from the
  /// backend, but the known set is translated.
  String invitationStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return t('invitationStatusPending');
      case 'accepted':
        return t('invitationStatusAccepted');
      case 'cancelled':
        return t('invitationStatusCancelled');
      case 'expired':
        return t('invitationStatusExpired');
      default:
        return status;
    }
  }

  /// Localized label for a `UserRole`. The raw enum value (`hotel_staff`,
  /// `app_admin`, etc.) is a serialization detail and should never be shown
  /// directly to end users.
  String userRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.appAdmin:
        return t('userRoleAppAdmin');
      case UserRole.appManager:
        return t('userRoleAppManager');
      case UserRole.hotelManager:
        return t('userRoleHotelManager');
      case UserRole.hotelStaff:
        return t('userRoleHotelStaff');
    }
  }

  /// Localized label for a `SyncActionType` so we don't display raw
  /// snake_case enum values to end users in the settings queue.
  String syncActionTypeLabel(SyncActionType type) {
    switch (type) {
      case SyncActionType.refill:
        return t('syncActionRefill');
      case SyncActionType.undoRefill:
        return t('syncActionUndoRefill');
      case SyncActionType.correctionRequest:
        return t('syncActionCorrectionRequest');
      case SyncActionType.bottleReplacement:
        return t('syncActionBottleReplacement');
      case SyncActionType.stockAdjustment:
        return t('syncActionStockAdjustment');
      case SyncActionType.pendingEdit:
        return t('syncActionPendingEdit');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
