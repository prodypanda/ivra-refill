import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

class AuthValidation {
  const AuthValidation._();

  static String? email(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'authValidationEmailRequired';
    if (!text.contains('@') || !text.contains('.')) {
      return 'authValidationEmailInvalid';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'authValidationPasswordRequired';
    if (value.length < 8) return 'authValidationPasswordTooShort';
    return null;
  }

  static String? matchingPasswords(String password, String confirmation) {
    final passwordError = AuthValidation.password(password);
    if (passwordError != null) return passwordError;
    if (password != confirmation) return 'authValidationPasswordsDoNotMatch';
    return null;
  }
}

/// Maps an arbitrary error thrown during a Supabase auth call into a
/// user-facing localized message. Falls back to the generic
/// `authUnexpectedError` instead of dumping `Exception:` / `StateError:`
/// prefixes and internal diagnostics straight into the UI.
String localizeAuthError(AppLocalizations l10n, Object error) {
  if (error is AuthException) {
    return error.message;
  }
  final raw = error.toString();
  if (raw.contains('This account has been deactivated')) {
    return l10n.t('authAccountDeactivated');
  }
  return l10n.t('authUnexpectedError');
}
