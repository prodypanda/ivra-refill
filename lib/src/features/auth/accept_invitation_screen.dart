import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_validation.dart';
import 'login_screen.dart';

class AcceptInvitationScreen extends ConsumerStatefulWidget {
  const AcceptInvitationScreen({
    required this.token,
    super.key,
  });

  static const route = '/accept-invite';

  final String token;

  @override
  ConsumerState<AcceptInvitationScreen> createState() =>
      _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState
    extends ConsumerState<AcceptInvitationScreen> {
  late Future<TeamInvitation?> _invitationFuture;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _isSaving = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _invitationFuture = _loadInvitation();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<TeamInvitation?> _loadInvitation() async {
    if (widget.token.trim().isEmpty) return null;
    final invitation = await ref
        .read(repositoryProvider)
        .invitationByToken(token: widget.token.trim());
    if (invitation != null && _emailController.text.isEmpty) {
      _emailController.text = invitation.email;
    }
    return invitation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FutureBuilder<TeamInvitation?>(
                  future: _invitationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final invitation = snapshot.data;
                    if (invitation == null) {
                      return _InvalidInvitation(
                        onBackToLogin: () => context.go(LoginScreen.route),
                      );
                    }
                    return _InvitationForm(
                      invitation: invitation,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmController: _confirmController,
                      isSaving: _isSaving,
                      error: _error,
                      message: _message,
                      onAccept: () => _acceptInvitation(invitation),
                      onBackToLogin: () => context.go(LoginScreen.route),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(TeamInvitation invitation) async {
    final email = _emailController.text.trim();
    final emailError = AuthValidation.email(email);
    final passwordError = AuthValidation.matchingPasswords(
      _passwordController.text,
      _confirmController.text,
    );
    if (emailError != null || passwordError != null) {
      setState(() {
        _error = emailError ?? passwordError;
        _message = null;
      });
      return;
    }
    if (email.toLowerCase() != invitation.email.toLowerCase()) {
      setState(() {
        _error = AppLocalizations.of(context).t('inviteEmailMismatch');
        _message = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _message = null;
    });

    try {
      final useSupabase = ref.read(useSupabaseProvider);
      if (useSupabase && Supabase.instance.client.auth.currentSession == null) {
        await _ensureSupabaseSession(
          email: email,
          fullName: invitation.fullName,
        );
        if (Supabase.instance.client.auth.currentSession == null) {
          if (!mounted) return;
          setState(() {
            _message = AppLocalizations.of(context)
                .t('inviteAccountCreatedConfirm');
          });
          return;
        }
      }

      await ref
          .read(repositoryProvider)
          .acceptTeamInvitation(token: widget.token.trim());
      ref.invalidate(currentUserProvider);
      ref.invalidate(teamMembersProvider);
      ref.invalidate(teamInvitationsProvider);
      if (!mounted) return;
      context.go(DashboardScreen.route);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = localizeAuthError(
            AppLocalizations.of(context),
            error,
          ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _ensureSupabaseSession({
    required String email,
    required String fullName,
  }) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );
      return;
    } on AuthException {
      // If the account does not exist yet, create it below.
    }

    final base = Uri.base;
    final String redirectUrl;
    if (base.hasScheme && (base.scheme == 'http' || base.scheme == 'https')) {
      redirectUrl = base
          .replace(
              path: '/',
              query: '',
              fragment: '${AcceptInvitationScreen.route}?token=${widget.token.trim()}')
          .toString();
    } else {
      // Mobile / native build: hand Supabase the registered custom
      // scheme URL so it can email a working confirmation link.
      // See AndroidManifest.xml for the `ivra://app` intent-filter.
      redirectUrl = Uri(
        scheme: 'ivra',
        host: 'app',
        path: AcceptInvitationScreen.route,
        queryParameters: {'token': widget.token.trim()},
      ).toString();
    }

    await Supabase.instance.client.auth.signUp(
      email: email,
      password: _passwordController.text,
      data: {'full_name': fullName},
      emailRedirectTo: redirectUrl,
    );
  }
}

class _InvitationForm extends StatelessWidget {
  const _InvitationForm({
    required this.invitation,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.isSaving,
    required this.onAccept,
    required this.onBackToLogin,
    this.error,
    this.message,
  });

  final TeamInvitation invitation;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isSaving;
  final VoidCallback onAccept;
  final VoidCallback onBackToLogin;
  final String? error;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).t('inviteAcceptHeading'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          invitation.hotelName == null
              ? AppLocalizations.of(context).tParams(
                  'inviteSubtitleNoHotel',
                  {
                    'name': invitation.fullName,
                    'role':
                        AppLocalizations.of(context).userRoleLabel(invitation.role),
                  },
                )
              : AppLocalizations.of(context).tParams(
                  'inviteSubtitleWithHotel',
                  {
                    'name': invitation.fullName,
                    'role':
                        AppLocalizations.of(context).userRoleLabel(invitation.role),
                    'hotel': invitation.hotelName!,
                  },
                ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('inviteEmail'),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('invitePassword'),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('inviteConfirmPassword'),
            prefixIcon: const Icon(Icons.lock_reset_outlined),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: isSaving ? null : onAccept,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_outlined),
          label: Text(AppLocalizations.of(context).t('inviteAcceptTitle')),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isSaving ? null : onBackToLogin,
          child: Text(AppLocalizations.of(context).t('inviteAlreadyHaveAccount')),
        ),
      ],
    );
  }
}

class _InvalidInvitation extends StatelessWidget {
  const _InvalidInvitation({required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_unread_outlined, size: 48),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).t('inviteInvalidHeading'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).t('inviteInvalidBody'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onBackToLogin,
          child: Text(AppLocalizations.of(context).t('inviteBackToSignIn')),
        ),
      ],
    );
  }
}
