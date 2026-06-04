import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

import '../dashboard/dashboard_screen.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import 'auth_validation.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  static const route = '/set-password';

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _error;
  bool _obscurePassword = true;

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
      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
        ),
      );

      if (res.user != null) {
        if (!mounted) return;
        // User successfully set their password!
        // We update their metadata to remove the `invitation_id` so we know they're fully onboarded
        // Actually, we can just let them pass to the dashboard, as the router will allow them now
        // if we update a flag in their user metadata. Let's set `onboarded: true`.
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {'onboarded': true},
          ),
        );

        if (!mounted) return;
        context.go(DashboardScreen.route);
      } else {
        throw Exception('Failed to update password');
      }
    } catch (e) {
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

    return PageScaffold(
      title: l10n.t('setPasswordTitle'), // You may need to add this to translations if missing
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
                      tooltip: l10n.t(_obscurePassword ? 'authShowPassword' : 'authHidePassword'),
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
