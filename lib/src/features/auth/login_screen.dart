import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../dashboard/dashboard_screen.dart';
import '../shared/glass_card.dart';
import '../shared/offline_banner.dart';
import 'auth_validation.dart';
import 'biometric_auth.dart';
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
  var _biometricAvailable = false;
  var _hasSavedCredentials = false;
  var _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await ref.read(biometricAuthServiceProvider).isAvailable();
    final hasCreds = await hasBiometricCredentials();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _hasSavedCredentials = hasCreds;
    });
  }

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
    final profileErrorObj = hasSession
        ? ref.watch(currentUserProvider).whenOrNull(
              error: (error, stackTrace) => error,
            )
        : null;
    final isTransientProfile =
        profileErrorObj != null && isTransientProfileError(profileErrorObj);

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
                child: GlassCard(
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
                          child: Image.asset(
                            'assets/images/logo-dark.png',
                            height: 110,
                            fit: BoxFit.contain,
                          ),
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
                      if (profileErrorObj != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t(isTransientProfile
                                    ? 'authProfileLoadErrorTitle'
                                    : 'authTitleCannotAccess'),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isTransientProfile
                                    ? l10n.t('authProfileLoadErrorBody')
                                    : localizeAuthError(l10n, profileErrorObj),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isTransientProfile) ...[
                                    TextButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _retryProfileLoad,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(l10n.t('btnRetry')),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  TextButton.icon(
                                    onPressed: _isLoading ? null : _signOut,
                                    icon: const Icon(Icons.logout_outlined),
                                    label: Text(l10n.t('authBtnSignOut')),
                                  ),
                                ],
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                                    color: Theme.of(context).colorScheme.error,
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
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(isMobile ? 54 : 48),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 18 : 12,
                            ),
                          ),
                        ),
                        onPressed: _isLoading ? null : _googleSignIn,
                        icon: const Icon(Icons.public),
                        label: Text(
                          l10n.t('authBtnGoogleSignIn'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (_biometricAvailable &&
                          _hasSavedCredentials &&
                          ref.watch(biometricAccountProvider) != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(isMobile ? 54 : 48),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 18 : 12,
                              ),
                            ),
                          ),
                          onPressed:
                              (_isLoading || _isAuthenticating) ? null : _biometricLogin,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(
                            l10n.t('authBtnBiometricLogin'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => _showResetDialog(context),
                        child: Text(
                          l10n.t('authBtnForgotPassword'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _googleSignIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final base = Uri.base;
      final isWeb = base.hasScheme && (base.scheme == 'http' || base.scheme == 'https');
      
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: isWeb ? base.toString() : 'ivra://app/login-callback',
      );
      // Note: for web, the browser will redirect automatically.
      // For mobile, the OS deep links back and Supabase flutter handles the session.
      // The actual routing to Dashboard happens via our app state listeners.
    } catch (error) {
      if (mounted) setState(() => _error = localizeAuthError(l10n, error));
      if (mounted) setState(() => _isLoading = false);
    }
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
      
      await saveLoginCredentials(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final hasCreds = await hasBiometricCredentials();
      if (mounted) setState(() => _hasSavedCredentials = hasCreds);

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

  Future<void> _biometricLogin() async {
    // Re-entrancy guard: never start a second biometric prompt while one is
    // already in flight. Without this, a double tap (or a rebuild that re-runs
    // the handler) stacks multiple `authenticate()` calls and the system
    // prompt reappears again and again until the app is killed.
    if (_isAuthenticating) return;

    final l10n = AppLocalizations.of(context);
    final biometricAccount = ref.read(biometricAccountProvider);
    final savedPassword = biometricAccount == null
        ? null
        : await savedPasswordFor(biometricAccount);
    final hasSession =
        Supabase.instance.client.auth.currentSession != null;

    // Biometric unlock needs either a live session to restore, or the stored
    // credentials of the account that opted in (to replay a sign-in).
    if (!hasSession &&
        (biometricAccount == null ||
            savedPassword == null ||
            savedPassword.isEmpty)) {
      setState(() => _error = l10n.t('authBiometricNeedsLogin'));
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final authenticated = await ref
          .read(biometricAuthServiceProvider)
          .authenticate(l10n.t('authBiometricReason'));

      if (!authenticated) return;

      // If a (possibly cached/offline) Supabase session already exists, unlock
      // straight into the app instead of forcing a network sign-in. This is
      // what lets biometric unlock work offline: the previous code always
      // called `signInWithPassword`, which fails without a network and left the
      // user stuck re-trying the fingerprint prompt.
      if (hasSession) {
        ref.invalidate(currentUserProvider);
        ref.invalidate(dashboardProvider);
        if (mounted) context.go(DashboardScreen.route);
        return;
      }

      final isOnline = ref.read(connectivityProvider);
      if (!isOnline) {
        if (mounted) {
          setState(() => _error = l10n.t('authBiometricOfflineNoSession'));
        }
        return;
      }

      // Online and no session yet: replay the saved credentials of the account
      // that enabled biometric unlock.
      _emailController.text = biometricAccount!;
      _passwordController.text = savedPassword!;
      await _login();
    } catch (e) {
      if (mounted) setState(() => _error = l10n.t('authBiometricFailed'));
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _retryProfileLoad() {
    setState(() => _error = null);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signOut();
      // Drop the offline read-cache so a different account signing in next
      // can't be served this user's cached data.
      await ref.read(repositoryProvider).clearCachedData();
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
