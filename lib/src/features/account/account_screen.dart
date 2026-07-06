import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/login_screen.dart';
import '../auth/auth_validation.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';
import '../../services/audit_service.dart';
import '../shared/premium_snackbar.dart';

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
  var _isUploadingAvatar = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (!isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final useSupabase = ref.watch(useSupabaseProvider);

    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canViewTeam =
        currentUser != null && currentUser.role != UserRole.hotelStaff;

    return PageScaffold(
      title: l10n.t('account'),
      onRefresh: () async {
        ref.invalidate(realCurrentUserProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(teamMembersProvider);
        await Future.wait([
          ref.read(currentUserProvider.future),
          ref.read(teamMembersProvider.future),
        ]);
      },
      child: AsyncValueView(
        value: ref.watch(currentUserProvider),
        onRetry: () {
          ref.invalidate(realCurrentUserProvider);
          ref.invalidate(currentUserProvider);
        },
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
                  isUploadingAvatar: _isUploadingAvatar,
                  onSave: _saveProfile,
                  onAvatarTap: _pickAvatar,
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
                if (canViewTeam) ...[
                  const SizedBox(height: 20),
                  _TeamAccountsCard(currentUserId: user.id),
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
      ref.invalidate(realCurrentUserProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(teamMembersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).t('accountProfileUpdated'))),
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
        SnackBar(
            content:
                Text(AppLocalizations.of(context).t('accountPasswordUpdated'))),
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
      ref.read(auditServiceProvider).logAction('User logged off');
      await Supabase.instance.client.auth.signOut();
      ref.invalidate(realCurrentUserProvider);
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
    } catch (error) {
      if (!mounted) return;
      PremiumSnackbar.showError(context, localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'accountSignOutFailed',
          ));
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      XFile? image;
      try {
        image = await picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        image = await picker.pickMedia();
      }
      
      if (image == null) return;
      
      setState(() => _isUploadingAvatar = true);
      
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser != null) {
        await ref.read(repositoryProvider).updateUserAvatar(
          userId: currentUser.id,
          imageBytes: bytes,
          fileExtension: ext,
        );
        ref.invalidate(realCurrentUserProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(teamMembersProvider);
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    required this.formKey,
    required this.user,
    required this.fullNameController,
    required this.isSaving,
    required this.isUploadingAvatar,
    required this.onSave,
    required this.onAvatarTap,
  });

  final GlobalKey<FormState> formKey;
  final UserProfile user;
  final TextEditingController fullNameController;
  final bool isSaving;
  final bool isUploadingAvatar;
  final VoidCallback onSave;
  final VoidCallback onAvatarTap;

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
                  GestureDetector(
                    onTap: isUploadingAvatar ? null : onAvatarTap,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty && user.avatarUrl!.startsWith('http')) ? NetworkImage(user.avatarUrl!) : null,
                          child: (user.avatarUrl == null || user.avatarUrl!.isEmpty || !user.avatarUrl!.startsWith('http'))
                              ? Icon(Icons.person, size: 32, color: Theme.of(context).colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        if (isUploadingAvatar)
                          const Positioned.fill(
                            child: CircularProgressIndicator(),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context).t('accountFullName')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)
                        .t('accountFullNameRequired');
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
                    value:
                        AppLocalizations.of(context).userRoleLabel(user.role),
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
                    value: user.isActive
                        ? AppLocalizations.of(context).t('accountActive')
                        : AppLocalizations.of(context).t('accountInactive'),
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
                              ? AppLocalizations.of(context)
                                  .t('accountPasswordHintSupabase')
                              : AppLocalizations.of(context)
                                  .t('accountPasswordHintDemo'),
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
                decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context).t('accountNewPassword')),
                validator: (value) => AuthValidation.password(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)
                        .t('accountConfirmPassword')),
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
              child: Builder(
                  builder: (context) => Text(
                      AppLocalizations.of(context).t('accountSignOutHint'))),
            ),
            Builder(
                builder: (context) => FilledButton.icon(
                      onPressed: isSigningOut ? null : onSignOut,
                      icon: isSigningOut
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_outlined),
                      label: Text(
                          AppLocalizations.of(context).t('accountSignOut')),
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
      label: Text(AppLocalizations.of(context).tParams('chipLabelValue', {'label': label, 'value': value})),
    );
  }
}

class _TeamAccountsCard extends ConsumerWidget {
  const _TeamAccountsCard({required this.currentUserId});

  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final hotelsById = <String, String>{
      for (final hotel
          in ref.watch(hotelsProvider).valueOrNull ?? const <Hotel>[])
        hotel.id: hotel.name,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_2_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t('accountTeamAccounts'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AsyncValueView(
              value: ref.watch(teamMembersProvider),
              onRetry: () => ref.invalidate(teamMembersProvider),
              builder: (members) {
                if (members.isEmpty) {
                  return Text(l10n.t('accountNoOtherAccounts'));
                }
                return Column(
                  children: [
                    for (int i = 0; i < members.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _TeamMemberTile(
                        member: members[i],
                        isCurrentUser: members[i].id == currentUserId,
                        hotelName: members[i].hotelId != null
                            ? hotelsById[members[i].hotelId!]
                            : null,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({
    required this.member,
    required this.isCurrentUser,
    this.hotelName,
  });

  final UserProfile member;
  final bool isCurrentUser;
  final String? hotelName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isCurrentUser
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outlined,
          color: isCurrentUser
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.fullName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.t('accountYou'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${l10n.userRoleLabel(member.role)}'
        '${hotelName != null ? ' · $hotelName' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: member.isActive
              ? Colors.green.withValues(alpha: 0.1)
              : theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          member.isActive ? l10n.t('accountActive') : l10n.t('accountInactive'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: member.isActive
                ? Colors.green.shade700
                : theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
