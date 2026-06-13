import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';

/// Translates generic exceptions, AuthException, and PostgrestException 
/// into user-friendly localized messages.
String translateError(Object error, AppLocalizations l10n) {
  if (error is PostgrestException) {
    if (error.code == '23505') {
      return l10n.t('errorUniqueViolation') ?? 'This record already exists.';
    }
    if (error.code == '23503') {
      return l10n.t('errorForeignKeyViolation') ?? 'Related record not found.';
    }
    if (error.code == '42501') {
      return l10n.t('errorPermissionDenied') ?? 'You do not have permission to perform this action.';
    }
    // For other unhandled PostgREST exceptions, fallback to the generic error 
    // to avoid leaking DB schema or generic Postgres errors to the user.
    return l10n.t('errorGeneric') ?? 'An unexpected error occurred. Please try again.';
  }
  
  if (error is AuthException) {
    // Auth exceptions usually contain user-friendly messages from Supabase Auth server.
    return error.message;
  }

  // Generic fallback
  return l10n.t('errorGeneric') ?? 'An unexpected error occurred. Please try again.';
}
