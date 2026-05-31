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

/// Maps an arbitrary error thrown during a Supabase call (auth or
/// repository) into a user-facing localized message. Falls back to a
/// generic message instead of dumping `Exception:` / `StateError:`
/// prefixes and internal diagnostics straight into the UI.
///
/// If a caller wants a context-specific fallback (e.g.
/// `accountSaveFailed` instead of the generic `authUnexpectedError`),
/// pass the key via [fallbackKey].
String localizeAuthError(
  AppLocalizations l10n,
  Object error, {
  String fallbackKey = 'authUnexpectedError',
}) {
  if (error is AuthException) {
    return error.message;
  }
  final raw = error.toString();
  if (raw.contains('This account has been deactivated')) {
    return l10n.t('authAccountDeactivated');
  }
  return l10n.t(fallbackKey);
}

/// Returns true when [error], thrown while loading the signed-in user's
/// profile, is a *transient* failure (a network blip, a request timeout, or an
/// auth-token refresh race on cold start) rather than a genuine authorization
/// problem.
///
/// Transient failures should be retried in place instead of being shown as
/// "this account cannot access Ivra" and forcing the user to sign out / restart
/// the app. Genuine problems — a deactivated account, or an account that truly
/// has no profile row — are not transient.
bool isTransientProfileError(Object error) {
  // Genuine authorization problems: do not retry / do not soften the message.
  if (error is StateError) return false;
  final raw = error.toString();
  if (raw.contains('This account has been deactivated')) return false;
  // PostgREST `.single()` with no row => the account genuinely has no profile.
  if (raw.contains('PGRST116') ||
      raw.contains('contains 0 rows') ||
      raw.contains('multiple (or no) rows')) {
    return false;
  }
  // An expired/invalid access token (common right after a cold start, before
  // Supabase auto-refreshes the session) is transient.
  if (error is AuthException) return true;
  return raw.contains('JWT') ||
      raw.contains('PGRST301') ||
      raw.contains('token is expired') ||
      raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('ClientException') ||
      raw.contains('XMLHttpRequest') ||
      raw.contains('Failed to fetch') ||
      raw.contains('Connection') ||
      raw.contains('timeout') ||
      raw.contains('timed out');
}
