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
