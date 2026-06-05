import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Conditional import for web-only sessionStorage access
import 'set_password_stub.dart' if (dart.library.html) 'set_password_web.dart'
    as platform;

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

import '../dashboard/dashboard_screen.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import 'auth_validation.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({
    this.refreshToken,
    this.accessToken,
    super.key,
  });

  static const route = '/set-password';

  /// Fallback: refresh token passed as query parameter (kept for backwards
  /// compatibility, but the auth callback page now prefers sessionStorage).
  final String? refreshToken;
  final String? accessToken;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _error;
  bool _obscurePassword = true;
  bool _isEstablishingSession = false;

  @override
  void initState() {
    super.initState();
    _maybeEstablishSession();
  }

  /// Establish a Supabase session from the refresh token.
  /// Priority: sessionStorage (secure) > query parameter (fallback).
  Future<void> _maybeEstablishSession() async {
    // Already have a session? Skip.
    if (Supabase.instance.client.auth.currentSession != null) return;

    // 1. Try sessionStorage first (set by the auth callback page)
    String? refreshToken;
    if (kIsWeb) {
      refreshToken = platform.consumeRefreshToken();
    }

    // 2. Fallback to query parameter
    refreshToken ??= widget.refreshToken;

    if (refreshToken == null || refreshToken.isEmpty) return;

    setState(() => _isEstablishingSession = true);

    try {
      await Supabase.instance.client.auth.setSession(refreshToken);
      // Invalidate cached user so the rest of the app picks up the new session.
      ref.invalidate(currentUserProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Session error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isEstablishingSession = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final passwordError = AuthValidation.matchingPasswords(
      _passwordController.text,
      _confirmController.text,
    );

    if (passwordError != null) {
      setState(() {
        _error = passwordError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      // Set the flag BEFORE calling updateUser. The updateUser call triggers
      // an auth state change which causes the router to rebuild. Without this
      // flag, the router would see needsPassword=true and redirect back here.
      ref.read(passwordSetProvider.notifier).state = true;

      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
          data: {'onboarded': true},
        ),
      );

      if (res.user != null) {
        if (!mounted) return;
        ref.invalidate(currentUserProvider);
        context.go(DashboardScreen.route);
      } else {
        ref.read(passwordSetProvider.notifier).state = false;
        throw Exception('Failed to update password');
      }
    } catch (e) {
      ref.read(passwordSetProvider.notifier).state = false;
      setState(() {
        _error = localizeAuthError(AppLocalizations.of(context), e, fallbackKey: 'resetPasswordError');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isEstablishingSession) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.t('setPasswordTitle')),
            ],
          ),
        ),
      );
    }

    return PageScaffold(
      title: l10n.t('setPasswordTitle'),
      child: Center(
        child: SizedBox(
          width: 400,
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.t('setPasswordBody'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.t('password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.t('confirmPassword'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _updatePassword(),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving ? null : _updatePassword,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.t('setPasswordButton')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
