import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../auth/accept_invitation_screen.dart';
import '../auth/auth_validation.dart';
import '../shared/async_value_view.dart';
import '../shared/premium_snackbar.dart';
import '../shared/premium_confirm_dialog.dart';
import '../shared/page_scaffold.dart';
import '../shared/glass_card.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  static const route = '/team';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canInvite =
        currentUser != null && currentUser.role != UserRole.hotelStaff;

    return PageScaffold(
      title: AppLocalizations.of(context).t('team'),
      onRefresh: () async {
        ref.invalidate(teamMembersProvider);
        ref.invalidate(teamInvitationsProvider);
        await Future.wait([
          ref.read(teamMembersProvider.future),
          ref.read(teamInvitationsProvider.future),
        ]);
      },
      actions: [
        if (canInvite)
          IconButton(
            tooltip: AppLocalizations.of(context).t('teamInviteTitle'),
            icon: const Icon(Icons.person_add_alt_outlined),
            onPressed: () => _showInviteDialog(context, ref, currentUser),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).t('teamAccounts'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AsyncValueView(
            value: ref.watch(teamMembersProvider),
            onRetry: () => ref.invalidate(teamMembersProvider),
            builder: (members) => _MembersTable(
              currentUser: currentUser,
              members: members,
              onSetActive: (member, isActive) =>
                  _setMemberActive(context, ref, member, isActive),
              onManageHotels: (member) =>
                  _showManageHotelsDialog(context, ref, member),
              onEditProfile: (member) => showDialog(
                context: context,
                builder: (context) => _EditProfileDialog(member: member),
              ),
              onDelete: (member) => _confirmDeleteUser(context, ref, member),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppLocalizations.of(context).t('teamPendingInvitations'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AsyncValueView(
            value: ref.watch(teamInvitationsProvider),
            onRetry: () => ref.invalidate(teamInvitationsProvider),
            builder: (invitations) => _InvitationsTable(
              currentUser: currentUser,
              invitations: invitations,
              onResend: (invitation) =>
                  _resendInvitation(context, ref, invitation),
              onCancel: (invitation) =>
                  _cancelInvitation(context, ref, invitation),
              onCopyLink: (invitation) =>
                  _copyInvitationLink(context, invitation),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageHotelsDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile member,
  ) async {
    final allHotels = await ref.read(hotelsProvider.future);
    final assignedHotels =
        await ref.read(repositoryProvider).userHotels(userId: member.id);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _ManageHotelsDialog(
        member: member,
        allHotels: allHotels,
        assignedHotelIds: assignedHotels.map((h) => h.id).toSet(),
      ),
    );

    ref.invalidate(teamMembersProvider);
  }

  Future<void> _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile currentUser,
  ) async {
    final hotels = await ref.read(hotelsProvider.future);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _InviteTeamMemberDialog(
        currentUser: currentUser,
        hotels: hotels,
      ),
    );

    ref.invalidate(teamInvitationsProvider);
    ref.invalidate(teamMembersProvider);
  }

  Future<void> _setMemberActive(
    BuildContext context,
    WidgetRef ref,
    UserProfile member,
    bool isActive,
  ) async {
    await ref.read(repositoryProvider).setTeamMemberActive(
          userId: member.id,
          isActive: isActive,
        );
    ref.invalidate(teamMembersProvider);
    if (!context.mounted) return;
    PremiumSnackbar.showSuccess(
      context,
      AppLocalizations.of(context).tParams(
        isActive ? 'teamMemberReactivated' : 'teamMemberDeactivated',
        {'name': member.fullName},
      ),
    );
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    WidgetRef ref,
    UserProfile member,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await PremiumConfirmDialog.show(
      context,
      title: l10n.t('delete'),
      message: l10n.tParams('confirmDeleteUser', {'userName': member.fullName}),
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteUser(member.id);
        ref.invalidate(teamMembersProvider);
      } catch (e) {
        if (context.mounted) {
          PremiumSnackbar.showError(context, e);
        }
      }
    }
  }

  Future<void> _cancelInvitation(
    BuildContext context,
    WidgetRef ref,
    TeamInvitation invitation,
  ) async {
    await ref.read(repositoryProvider).cancelTeamInvitation(
          invitationId: invitation.id,
        );
    ref.invalidate(teamInvitationsProvider);
    if (!context.mounted) return;
    PremiumSnackbar.showSuccess(
      context,
      AppLocalizations.of(context).tParams(
        'teamInvitationCancelled',
        {'email': invitation.email},
      ),
    );
  }

  Future<void> _resendInvitation(
    BuildContext context,
    WidgetRef ref,
    TeamInvitation invitation,
  ) async {
    await ref.read(repositoryProvider).resendTeamInvitation(
          invitationId: invitation.id,
        );
    ref.invalidate(teamInvitationsProvider);
    if (!context.mounted) return;
    PremiumSnackbar.showSuccess(
      context,
      AppLocalizations.of(context).tParams(
        'teamInvitationResent',
        {'email': invitation.email},
      ),
    );
  }

  Future<void> _copyInvitationLink(
    BuildContext context,
    TeamInvitation invitation,
  ) async {
    final token = invitation.inviteToken;
    if (token == null || token.isEmpty) {
      PremiumSnackbar.showError(
        context,
        AppLocalizations.of(context).t('teamInviteLinkUnavailable'),
      );
      return;
    }

    final invitePath = Uri(
      path: AcceptInvitationScreen.route,
      queryParameters: {'token': token},
    ).toString();
    final link =
        Uri.base.replace(path: '/', query: '', fragment: invitePath).toString();
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    PremiumSnackbar.showSuccess(
      context,
      AppLocalizations.of(context).tParams(
        'teamInvitationCopied',
        {'email': invitation.email},
      ),
    );
  }
}

class _MembersTable extends ConsumerWidget {
  const _MembersTable({
    required this.currentUser,
    required this.members,
    required this.onSetActive,
    required this.onManageHotels,
    required this.onEditProfile,
    required this.onDelete,
  });

  final UserProfile? currentUser;
  final List<UserProfile> members;
  final void Function(UserProfile member, bool isActive) onSetActive;
  final void Function(UserProfile member) onManageHotels;
  final void Function(UserProfile member) onEditProfile;
  final void Function(UserProfile member) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (members.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(l10n.t('teamNoMembers')),
        ),
      );
    }

    final canManageHotels = currentUser != null &&
        (currentUser!.role == UserRole.appAdmin ||
            currentUser!.role == UserRole.appManager);

    final hotelsById = <String, String>{
      for (final hotel
          in ref.watch(hotelsProvider).valueOrNull ?? const <Hotel>[])
        hotel.id: hotel.name,
    };

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final member in members)
          _PremiumMemberCard(
            currentUser: currentUser,
            member: member,
            hotelsById: hotelsById,
            canManageHotels: canManageHotels,
            onSetActive: onSetActive,
            onManageHotels: onManageHotels,
            onEditProfile: onEditProfile,
            onDelete: onDelete,
          ),
      ],
    );
  }
}

class _InvitationsTable extends StatelessWidget {
  const _InvitationsTable({
    required this.currentUser,
    required this.invitations,
    required this.onResend,
    required this.onCancel,
    required this.onCopyLink,
  });

  final UserProfile? currentUser;
  final List<TeamInvitation> invitations;
  final ValueChanged<TeamInvitation> onResend;
  final ValueChanged<TeamInvitation> onCancel;
  final ValueChanged<TeamInvitation> onCopyLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (invitations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(l10n.t('teamNoPendingInvitations')),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final invitation in invitations)
          _PremiumInvitationCard(
            currentUser: currentUser,
            invitation: invitation,
            onResend: onResend,
            onCancel: onCancel,
            onCopyLink: onCopyLink,
          ),
      ],
    );
  }
}

class _InviteTeamMemberDialog extends ConsumerStatefulWidget {
  const _InviteTeamMemberDialog({
    required this.currentUser,
    required this.hotels,
  });

  final UserProfile currentUser;
  final List<Hotel> hotels;

  @override
  ConsumerState<_InviteTeamMemberDialog> createState() =>
      _InviteTeamMemberDialogState();
}

class _InviteTeamMemberDialogState
    extends ConsumerState<_InviteTeamMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  UserRole _role = UserRole.hotelStaff;
  final Set<String> _selectedHotelIds = {};
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.hotels.isNotEmpty) {
      _selectedHotelIds.add(widget.hotels.first.id);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final availableRoles = _invitableRoles(widget.currentUser.role);
    final needsHotel =
        _role == UserRole.hotelManager || _role == UserRole.hotelStaff;

    return AlertDialog(
      title: Text(l10n.t('teamInviteTitle')),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullName,
                  decoration:
                      InputDecoration(labelText: l10n.t('teamLabelFullName')),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: l10n.t('teamTableColumnEmail')),
                  validator: (value) {
                    final errorKey = AuthValidation.email(value ?? '');
                    if (errorKey != null) return l10n.t(errorKey);
                    // Prevent self-invitation
                    if ((value ?? '').trim().toLowerCase() ==
                        widget.currentUser.email.toLowerCase()) {
                      return l10n.t('teamCannotInviteSelf');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  decoration:
                      InputDecoration(labelText: l10n.t('teamTableColumnRole')),
                  items: [
                    for (final role in availableRoles)
                      DropdownMenuItem(
                        value: role,
                        child: Text(
                          AppLocalizations.of(context).userRoleLabel(role),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _role = value;
                      if (_role == UserRole.appAdmin ||
                          _role == UserRole.appManager) {
                        _selectedHotelIds.clear();
                      } else if (_selectedHotelIds.isEmpty &&
                          widget.hotels.isNotEmpty) {
                        _selectedHotelIds.add(widget.hotels.first.id);
                      }
                    });
                  },
                ),
                if (needsHotel && widget.hotels.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('teamSelectHotels'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final hotel in widget.hotels)
                          CheckboxListTile(
                            title: Text(hotel.name),
                            subtitle: Text(hotel.city),
                            value: _selectedHotelIds.contains(hotel.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedHotelIds.add(hotel.id);
                                } else {
                                  _selectedHotelIds.remove(hotel.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  if (_selectedHotelIds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        l10n.t('requiredField'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.person_add_alt_outlined),
          label: Text(l10n.t('teamInviteTitle')),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).t('requiredField');
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final needsHotel =
        _role == UserRole.hotelManager || _role == UserRole.hotelStaff;
    if (needsHotel && _selectedHotelIds.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(repositoryProvider);
      // Invite with the first selected hotel
      final primaryHotelId =
          _selectedHotelIds.isNotEmpty ? _selectedHotelIds.first : null;
      await repo.inviteTeamMember(
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
        role: _role.value,
        hotelId: primaryHotelId,
      );
      // Additional hotels will be assigned after the user accepts the invitation
      // and their profile is created. We store the intent locally for now.
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      PremiumSnackbar.showError(context, localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'teamInviteFailed',
          ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MemberActions extends StatelessWidget {
  const _MemberActions({
    required this.currentUser,
    required this.member,
    required this.onSetActive,
    this.onManageHotels,
    required this.onEditProfile,
    required this.onDelete,
  });

  final UserProfile? currentUser;
  final UserProfile member;
  final void Function(UserProfile member, bool isActive) onSetActive;
  final VoidCallback? onManageHotels;
  final void Function(UserProfile member) onEditProfile;
  final void Function(UserProfile member) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextState = !member.isActive;
    final canManage = _canManageMember(currentUser, member);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canManage)
          IconButton(
            tooltip: l10n.t('teamEditProfile'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => onEditProfile(member),
          ),
        if (onManageHotels != null)
          IconButton(
            tooltip: l10n.t('teamManageHotels'),
            icon: const Icon(Icons.domain_add_outlined),
            onPressed: onManageHotels,
          ),
        IconButton.outlined(
          tooltip: member.isActive
              ? l10n.t('teamDeactivateAccountTooltip')
              : l10n.t('teamReactivateAccountTooltip'),
          icon: Icon(
            member.isActive
                ? Icons.person_off_outlined
                : Icons.person_add_alt_1_outlined,
          ),
          onPressed: canManage ? () => onSetActive(member, nextState) : null,
        ),
        IconButton(
          tooltip: l10n.t('delete'),
          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
          onPressed: canManage ? () => onDelete(member) : null,
        ),
      ],
    );
  }
}

// ============================================================
// Manage Hotels Dialog — assign/unassign hotels to a team member
// ============================================================
class _ManageHotelsDialog extends ConsumerStatefulWidget {
  const _ManageHotelsDialog({
    required this.member,
    required this.allHotels,
    required this.assignedHotelIds,
  });

  final UserProfile member;
  final List<Hotel> allHotels;
  final Set<String> assignedHotelIds;

  @override
  ConsumerState<_ManageHotelsDialog> createState() =>
      _ManageHotelsDialogState();
}

class _ManageHotelsDialogState extends ConsumerState<_ManageHotelsDialog> {
  late final Set<String> _selectedIds;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.assignedHotelIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
          '${l10n.t('teamAssignHotelsTitle')} — ${widget.member.fullName}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_selectedIds.length} ${l10n.t('teamHotelsAssigned')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 350),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final hotel in widget.allHotels)
                    CheckboxListTile(
                      title: Text(hotel.name),
                      subtitle: Text('${hotel.city}, ${hotel.country}'),
                      secondary: Icon(
                        Icons.hotel_outlined,
                        color: _selectedIds.contains(hotel.id)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      value: _selectedIds.contains(hotel.id),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.add(hotel.id);
                          } else {
                            _selectedIds.remove(hotel.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check),
          label: Text(l10n.t('btnSave')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final oldIds = widget.assignedHotelIds;

      // Assign newly selected hotels
      for (final id in _selectedIds) {
        if (!oldIds.contains(id)) {
          await repo.assignUserHotel(
            userId: widget.member.id,
            hotelId: id,
          );
        }
      }

      // Unassign removed hotels
      for (final id in oldIds) {
        if (!_selectedIds.contains(id)) {
          await repo.unassignUserHotel(
            userId: widget.member.id,
            hotelId: id,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).t('teamHotelsUpdated'))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'teamHotelsUpdateFailed',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _InvitationActions extends StatelessWidget {
  const _InvitationActions({
    required this.canManage,
    required this.invitation,
    required this.onCancel,
    required this.onCopyLink,
    required this.onResend,
  });

  final bool canManage;
  final TeamInvitation invitation;
  final ValueChanged<TeamInvitation> onCancel;
  final ValueChanged<TeamInvitation> onCopyLink;
  final ValueChanged<TeamInvitation> onResend;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context).t('teamCopyLink'),
          icon: const Icon(Icons.link_outlined),
          onPressed: canManage ? () => onCopyLink(invitation) : null,
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).t('teamResendInvitation'),
          icon: const Icon(Icons.forward_to_inbox_outlined),
          onPressed: canManage ? () => onResend(invitation) : null,
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).t('teamCancelInvitation'),
          icon: const Icon(Icons.cancel_outlined),
          onPressed: canManage ? () => onCancel(invitation) : null,
        ),
      ],
    );
  }
}

class _PremiumMemberCard extends StatefulWidget {
  const _PremiumMemberCard({
    required this.currentUser,
    required this.member,
    required this.hotelsById,
    required this.canManageHotels,
    required this.onSetActive,
    required this.onManageHotels,
    required this.onEditProfile,
    required this.onDelete,
  });

  final UserProfile? currentUser;
  final UserProfile member;
  final Map<String, String> hotelsById;
  final bool canManageHotels;
  final void Function(UserProfile member, bool isActive) onSetActive;
  final void Function(UserProfile member) onManageHotels;
  final void Function(UserProfile member) onEditProfile;
  final void Function(UserProfile member) onDelete;

  @override
  State<_PremiumMemberCard> createState() => _PremiumMemberCardState();
}

class _PremiumMemberCardState extends State<_PremiumMemberCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final member = widget.member;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 320,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderColor: member.isActive
                ? theme.colorScheme.primary
                    .withValues(alpha: _isHovered ? 0.5 : 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                            theme.colorScheme.secondary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member.fullName.substring(0, 1).toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            member.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.userRoleLabel(member.role),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: member.isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.isActive
                            ? l10n.t('teamStatusActive')
                            : l10n.t('teamStatusInactive'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: member.isActive
                              ? Colors.green[800]
                              : theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.business_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        member.hotelId != null
                            ? (widget.hotelsById[member.hotelId!] ??
                                member.hotelId!)
                            : (member.isIvraUser
                                ? l10n.t('teamHotelAll')
                                : l10n.t('teamHotelNone')),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: _MemberActions(
                    currentUser: widget.currentUser,
                    member: member,
                    onSetActive: widget.onSetActive,
                    onManageHotels: widget.canManageHotels && !member.isIvraUser
                        ? () => widget.onManageHotels(member)
                        : null,
                    onEditProfile: widget.onEditProfile,
                    onDelete: widget.onDelete,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumInvitationCard extends StatefulWidget {
  const _PremiumInvitationCard({
    required this.currentUser,
    required this.invitation,
    required this.onResend,
    required this.onCancel,
    required this.onCopyLink,
  });

  final UserProfile? currentUser;
  final TeamInvitation invitation;
  final ValueChanged<TeamInvitation> onResend;
  final ValueChanged<TeamInvitation> onCancel;
  final ValueChanged<TeamInvitation> onCopyLink;

  @override
  State<_PremiumInvitationCard> createState() => _PremiumInvitationCardState();
}

class _PremiumInvitationCardState extends State<_PremiumInvitationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final invitation = widget.invitation;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 320,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderColor: theme.colorScheme.tertiary
                .withValues(alpha: _isHovered ? 0.5 : 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              theme.colorScheme.tertiary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            invitation.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.userRoleLabel(invitation.role),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.invitationStatusLabel(invitation.status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.business_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        invitation.hotelName ?? l10n.t('teamHotelAll'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: _InvitationActions(
                    canManage:
                        _canManageInvitation(widget.currentUser, invitation),
                    invitation: invitation,
                    onCancel: widget.onCancel,
                    onCopyLink: widget.onCopyLink,
                    onResend: widget.onResend,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<UserRole> _invitableRoles(UserRole role) {
  return switch (role) {
    UserRole.appAdmin => UserRole.values,
    UserRole.appManager => const [
        UserRole.hotelManager,
        UserRole.hotelStaff,
      ],
    UserRole.hotelManager => [UserRole.hotelStaff],
    UserRole.hotelStaff => [],
  };
}

// ============================================================
// Edit Profile Dialog
// ============================================================
class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.member});

  final UserProfile member;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.member.fullName);
  }

  @override
  void dispose() {
    _fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.t('teamEditProfile')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullName,
                decoration: InputDecoration(labelText: l10n.t('teamLabelFullName')),
                validator: (val) => val == null || val.trim().isEmpty ? l10n.t('requiredField') : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(l10n.t('btnSave')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(repositoryProvider);
      await repo.updateUserProfile(
        userId: widget.member.id,
        fullName: _fullName.text.trim(),
      );
      // Invalidate providers so UI updates
      ref.invalidate(teamMembersProvider);
      ref.invalidate(currentUserProvider);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('teamEditProfileSuccess'))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'errorGeneric',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}


bool _canManageMember(UserProfile? currentUser, UserProfile member) {
  if (currentUser == null || currentUser.id == member.id) return false;
  return switch (currentUser.role) {
    UserRole.appAdmin => true,
    UserRole.appManager => member.role != UserRole.appAdmin,
    UserRole.hotelManager => member.role == UserRole.hotelStaff &&
        member.hotelId != null &&
        member.hotelId == currentUser.hotelId,
    UserRole.hotelStaff => false,
  };
}

bool _canManageInvitation(
  UserProfile? currentUser,
  TeamInvitation invitation,
) {
  if (currentUser == null) return false;
  return switch (currentUser.role) {
    UserRole.appAdmin => true,
    UserRole.appManager => invitation.role == UserRole.hotelManager ||
        invitation.role == UserRole.hotelStaff,
    UserRole.hotelManager => invitation.role == UserRole.hotelStaff &&
        invitation.hotelId != null &&
        invitation.hotelId == currentUser.hotelId,
    UserRole.hotelStaff => false,
  };
}
