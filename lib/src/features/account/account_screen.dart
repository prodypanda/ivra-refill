import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/login_screen.dart';
import '../auth/auth_validation.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  static const route = '/account';

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _loadedUserId;
  var _isSavingProfile = false;
  var _isChangingPassword = false;
  var _isSigningOut = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useSupabase = ref.watch(useSupabaseProvider);

    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.t('account'),
      child: AsyncValueView(
        value: ref.watch(currentUserProvider),
        builder: (user) {
          _hydrateProfile(user);
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileCard(
                  formKey: _profileFormKey,
                  user: user,
                  fullNameController: _fullNameController,
                  isSaving: _isSavingProfile,
                  onSave: _saveProfile,
                ),
                const SizedBox(height: 20),
                _PasswordCard(
                  formKey: _passwordFormKey,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  useSupabase: useSupabase,
                  isSaving: _isChangingPassword,
                  onSave: _changePassword,
                ),
                if (useSupabase) ...[
                  const SizedBox(height: 20),
                  _SignOutCard(
                    isSigningOut: _isSigningOut,
                    onSignOut: _signOut,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _hydrateProfile(UserProfile user) {
    if (_loadedUserId == user.id) return;
    _loadedUserId = user.id;
    _fullNameController.text = user.fullName;
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);
    try {
      await ref.read(repositoryProvider).updateCurrentUserProfile(
            fullName: _fullNameController.text.trim(),
          );
      ref.invalidate(currentUserProvider);
      ref.invalidate(teamMembersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('accountProfileUpdated'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'accountSaveFailed',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isChangingPassword = true);
    try {
      await ref.read(repositoryProvider).changeCurrentUserPassword(
            password: _passwordController.text,
          );
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('accountPasswordUpdated'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'accountPasswordChangeFailed',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(hotelsProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(suggestedOrdersProvider);
      ref.invalidate(approvalsProvider);
      ref.invalidate(alertsProvider);
      ref.invalidate(refillEventsProvider);
      ref.invalidate(teamMembersProvider);
      ref.invalidate(teamInvitationsProvider);
      if (mounted) context.go(LoginScreen.route);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'accountSignOutFailed',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    required this.formKey,
    required this.user,
    required this.fullNameController,
    required this.isSaving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final UserProfile user;
  final TextEditingController fullNameController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelName = user.hotelId == null
        ? null
        : (ref.watch(hotelsProvider).valueOrNull ?? const <Hotel>[])
            .where((hotel) => hotel.id == user.hotelId)
            .map((hotel) => hotel.name)
            .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).t('accountProfile'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(AppLocalizations.of(context).t('btnSave')),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).t('accountFullName')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).t('accountFullNameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoChip(
                    icon: Icons.email_outlined,
                    label: AppLocalizations.of(context).t('accountEmail'),
                    value: user.email,
                  ),
                  _InfoChip(
                    icon: Icons.admin_panel_settings_outlined,
                    label: AppLocalizations.of(context).t('accountRole'),
                    value: AppLocalizations.of(context).userRoleLabel(user.role),
                  ),
                  _InfoChip(
                    icon: Icons.apartment_outlined,
                    label: AppLocalizations.of(context).t('accountScope'),
                    value: user.hotelId != null
                        ? (hotelName ?? user.hotelId!)
                        : AppLocalizations.of(context).t('accountIvraGlobal'),
                  ),
                  _InfoChip(
                    icon: user.isActive
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                    label: AppLocalizations.of(context).t('accountStatus'),
                    value: user.isActive ? AppLocalizations.of(context).t('accountActive') : AppLocalizations.of(context).t('accountInactive'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.useSupabase,
    required this.isSaving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool useSupabase;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.password_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).t('accountPassword'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          useSupabase
                              ? AppLocalizations.of(context).t('accountPasswordHintSupabase')
                              : AppLocalizations.of(context).t('accountPasswordHintDemo'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_reset_outlined),
                    label: Text(AppLocalizations.of(context).t('btnUpdate')),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).t('accountNewPassword')),
                validator: (value) => AuthValidation.password(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: AppLocalizations.of(context).t('accountConfirmPassword')),
                validator: (value) => AuthValidation.matchingPasswords(
                  passwordController.text,
                  value ?? '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({
    required this.isSigningOut,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.logout_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(builder: (context) => Text(AppLocalizations.of(context).t('accountSignOutHint'))),
            ),
            Builder(builder: (context) => FilledButton.icon(
              onPressed: isSigningOut ? null : onSignOut,
              icon: isSigningOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_outlined),
              label: Text(AppLocalizations.of(context).t('accountSignOut')),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
    );
  }
}


