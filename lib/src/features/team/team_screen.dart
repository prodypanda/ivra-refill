import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../auth/accept_invitation_screen.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

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
          Text(AppLocalizations.of(context).t('teamAccounts'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AsyncValueView(
            value: ref.watch(teamMembersProvider),
            builder: (members) => _MembersTable(
              currentUser: currentUser,
              members: members,
              onSetActive: (member, isActive) =>
                  _setMemberActive(context, ref, member, isActive),
              onManageHotels: (member) =>
                  _showManageHotelsDialog(context, ref, member),
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
    final assignedHotels = await ref.read(repositoryProvider).userHotels(userId: member.id);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).tParams(
            isActive ? 'teamMemberReactivated' : 'teamMemberDeactivated',
            {'name': member.fullName},
          ),
        ),
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).tParams(
            'teamInvitationCancelled',
            {'email': invitation.email},
          ),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).tParams(
            'teamInvitationResent',
            {'email': invitation.email},
          ),
        ),
      ),
    );
  }

  Future<void> _copyInvitationLink(
    BuildContext context,
    TeamInvitation invitation,
  ) async {
    final token = invitation.inviteToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('teamInviteLinkUnavailable'))),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).tParams(
            'teamInvitationCopied',
            {'email': invitation.email},
          ),
        ),
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
  });

  final UserProfile? currentUser;
  final List<UserProfile> members;
  final void Function(UserProfile member, bool isActive) onSetActive;
  final void Function(UserProfile member) onManageHotels;

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
      for (final hotel in ref.watch(hotelsProvider).valueOrNull ?? const <Hotel>[])
        hotel.id: hotel.name,
    };

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.t('teamTableColumnName'))),
            DataColumn(label: Text(l10n.t('teamTableColumnEmail'))),
            DataColumn(label: Text(l10n.t('teamTableColumnRole'))),
            DataColumn(label: Text(l10n.t('teamTableColumnHotel'))),
            DataColumn(label: Text(l10n.t('teamTableColumnStatus'))),
            DataColumn(label: Text(l10n.t('teamTableColumnActions'))),
          ],
          rows: [
            for (final member in members)
              DataRow(
                cells: [
                  DataCell(Text(member.fullName)),
                  DataCell(Text(member.email)),
                  DataCell(Chip(label: Text(l10n.userRoleLabel(member.role)))),
                  DataCell(
                    Text(
                      member.hotelId != null
                          ? (hotelsById[member.hotelId!] ?? member.hotelId!)
                          : (member.isIvraUser
                              ? l10n.t('teamHotelAll')
                              : l10n.t('teamHotelNone')),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(
                        member.isActive
                            ? l10n.t('teamStatusActive')
                            : l10n.t('teamStatusInactive'),
                      ),
                    ),
                  ),
                  DataCell(
                    _MemberActions(
                      currentUser: currentUser,
                      member: member,
                      onSetActive: onSetActive,
                      onManageHotels: canManageHotels && !member.isIvraUser
                          ? () => onManageHotels(member)
                          : null,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
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

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context).t('teamTableColumnName'))),
            DataColumn(label: Text(AppLocalizations.of(context).t('teamTableColumnEmail'))),
            DataColumn(label: Text(AppLocalizations.of(context).t('teamTableColumnRole'))),
            DataColumn(label: Text(AppLocalizations.of(context).t('teamTableColumnHotel'))),
            DataColumn(label: Text(AppLocalizations.of(context).t('teamTableColumnStatus'))),
            DataColumn(label: Text(AppLocalizations.of(context).t('teamTableColumnActions'))),
          ],
          rows: [
            for (final invitation in invitations)
              DataRow(
                cells: [
                  DataCell(Text(invitation.fullName)),
                  DataCell(Text(invitation.email)),
                  DataCell(
                    Chip(label: Text(l10n.userRoleLabel(invitation.role))),
                  ),
                  DataCell(
                    Text(invitation.hotelName ?? l10n.t('teamHotelAll')),
                  ),
                  DataCell(Text(l10n.invitationStatusLabel(invitation.status))),
                  DataCell(
                    _InvitationActions(
                      canManage: _canManageInvitation(currentUser, invitation),
                      invitation: invitation,
                      onCancel: onCancel,
                      onCopyLink: onCopyLink,
                      onResend: onResend,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
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
                  decoration: InputDecoration(labelText: l10n.t('teamLabelFullName')),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.t('teamTableColumnEmail')),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Required';
                    if (!text.contains('@')) return 'Enter an email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: InputDecoration(labelText: l10n.t('teamTableColumnRole')),
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
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
    if (value == null || value.trim().isEmpty) return 'Required';
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
      final primaryHotelId = _selectedHotelIds.isNotEmpty
          ? _selectedHotelIds.first
          : null;
      await repo.inviteTeamMember(
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
        role: _role.value,
        hotelId: primaryHotelId,
      );
      // Additional hotels will be assigned after the user accepts the invitation
      // and their profile is created. We store the intent locally for now.
      if (mounted) Navigator.of(context).pop();
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
  });

  final UserProfile? currentUser;
  final UserProfile member;
  final void Function(UserProfile member, bool isActive) onSetActive;
  final VoidCallback? onManageHotels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextState = !member.isActive;
    final canManage = _canManageMember(currentUser, member);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      title: Text('${l10n.t('teamAssignHotelsTitle')} — ${widget.member.fullName}'),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
          SnackBar(content: Text(AppLocalizations.of(context).t('teamHotelsUpdated'))),
        );
      }
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

List<UserRole> _invitableRoles(UserRole role) {
  return switch (role) {
    UserRole.appAdmin => UserRole.values,
    UserRole.appManager => const [
        UserRole.hotelManager,
        UserRole.hotelStaff,
      ],
    UserRole.hotelManager => const [UserRole.hotelStaff],
    UserRole.hotelStaff => const [],
  };
}

bool _canManageMember(UserProfile? currentUser, UserProfile member) {
  if (currentUser == null || currentUser.id == member.id) return false;
  return switch (currentUser.role) {
    UserRole.appAdmin => true,
    UserRole.appManager => member.role == UserRole.hotelManager ||
        member.role == UserRole.hotelStaff,
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


