import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../dashboard/dashboard_screen.dart';
import '../shared/glass_card.dart';
import 'auth_validation.dart';
import 'reset_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;
  var _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final useSupabase = ref.watch(useSupabaseProvider);
    final hasSession =
        useSupabase && Supabase.instance.client.auth.currentSession != null;
    final profileError = hasSession
        ? ref.watch(currentUserProvider).whenOrNull(
              error: (error, stackTrace) => localizeAuthError(l10n, error),
            )
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isMobile ? Alignment.topCenter : Alignment.topLeft,
            end: isMobile ? Alignment.bottomCenter : Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF8F5),
              if (isMobile) const Color(0xFFFFEDD5),
              const Color(0xFFFFF4D9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 24 : 24,
                isMobile ? 16 : 24,
                24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 420,
                ),
                child: Column(
                  children: [
                    if (isMobile) ...[
                      _LoginHero(useSupabase: useSupabase),
                      const SizedBox(height: 20),
                    ],
                    GlassCard(
                      padding: EdgeInsets.all(
                        isMobile ? 20 : 32,
                      ),
                      borderRadius: isMobile ? 30 : 16,
                      color: isMobile
                          ? colorScheme.surface.withValues(alpha: 0.88)
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isMobile) ...[
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.spa_outlined,
                                  size: 36,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ivra',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            Text(
                              l10n.t('authBtnSignIn'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              useSupabase
                                  ? l10n.t('settingsSupabaseHint')
                                  : l10n.t('demoModeDescription'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                          if (profileError != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('authTitleCannotAccess'),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    profileError,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _isLoading ? null : _signOut,
                                      icon: const Icon(Icons.logout_outlined),
                                      label: Text(l10n.t('authBtnSignOut')),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.t('authLabelEmail'),
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.t('authLabelPassword'),
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                tooltip: l10n.t(
                                  _obscurePassword
                                      ? 'authShowPassword'
                                      : 'authHidePassword',
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(isMobile ? 54 : 48),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 18 : 12,
                                ),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            icon: _isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_outlined),
                            label: Text(
                              l10n.t('authBtnSignIn'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _showResetDialog(context),
                            child: Text(
                              l10n.t('authBtnForgotPassword'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMobile) ...[
                      const SizedBox(height: 18),
                      _LoginTrustStrip(useSupabase: useSupabase),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final emailErrorKey = AuthValidation.email(_emailController.text);
    final passwordErrorKey = AuthValidation.password(_passwordController.text);
    if (emailErrorKey != null || passwordErrorKey != null) {
      setState(() => _error = l10n.t(emailErrorKey ?? passwordErrorKey!));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      ref.invalidate(currentUserProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) {
        context.go(DashboardScreen.route);
      }
    } catch (error) {
      if (mounted) setState(() => _error = localizeAuthError(l10n, error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(dashboardProvider);
    } catch (error) {
      if (mounted) {
        setState(() => _error = localizeAuthError(
              l10n,
              error,
              fallbackKey: 'accountSignOutFailed',
            ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final email = _emailController.text.trim();
    await showDialog<void>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(initialEmail: email),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.useSupabase});

  final bool useSupabase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.95),
            const Color(0xFFF59E0B).withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child:
                const Icon(Icons.spa_outlined, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            'Ivra',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useSupabase
                ? l10n.t('settingsSupabaseConnected')
                : l10n.t('demoMode'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTrustStrip extends StatelessWidget {
  const _LoginTrustStrip({required this.useSupabase});

  final bool useSupabase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _LoginTrustTile(
            icon: Icons.cloud_done_outlined,
            label: useSupabase
                ? l10n.t('settingsSupabaseConnected')
                : l10n.t('demoMode'),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LoginTrustTile(
            icon: Icons.lock_outline,
            label: l10n.t('authLabelPassword'),
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _LoginTrustTile extends StatelessWidget {
  const _LoginTrustTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  var _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.t('authResetPasswordTitle')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.t('authLabelEmail'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton.icon(
          onPressed: _isSending ? null : _sendResetEmail,
          icon: _isSending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.mark_email_read_outlined),
          label: Text(l10n.t('authBtnSendResetLink')),
        ),
      ],
    );
  }

  Future<void> _sendResetEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final emailErrorKey = AuthValidation.email(email);
    if (emailErrorKey != null) {
      setState(() => _error = l10n.t(emailErrorKey));
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: _resetRedirectUrl(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.t('authResetLinkSent')} $email')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = localizeAuthError(l10n, error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _resetRedirectUrl() {
    final base = Uri.base;
    if (base.hasScheme && (base.scheme == 'http' || base.scheme == 'https')) {
      return base
          .replace(path: '/', query: '', fragment: ResetPasswordScreen.route)
          .toString();
    }
    // Mobile / native build: Supabase requires an absolute URL with a
    // scheme, so we hand it the custom `ivra://app/...` URI registered
    // by AndroidManifest.xml. The OS routes the redirect back into the
    // running app via Flutter's deep-link integration.
    return 'ivra://app${ResetPasswordScreen.route}';
  }
}
