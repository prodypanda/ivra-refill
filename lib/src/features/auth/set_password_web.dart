import 'dart:html' as html;

/// Reads and removes the refresh token stored by the auth callback page.
/// Returns null if no token was stored.
String? consumeRefreshToken() {
  final token = html.window.sessionStorage['ivra_auth_refresh_token'];
  if (token != null && token.isNotEmpty) {
    // Consume: remove it so it can't be replayed
    html.window.sessionStorage.remove('ivra_auth_refresh_token');
    return token;
  }
  return null;
}
