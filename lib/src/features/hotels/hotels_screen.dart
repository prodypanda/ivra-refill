import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../auth/auth_validation.dart';
import '../shared/async_value_view.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';

class HotelsScreen extends ConsumerWidget {
  const HotelsScreen({super.key});

  static const route = '/hotels';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canCreateHotel = currentUser?.isIvraUser ?? false;
    final theme = Theme.of(context);

    return PageScaffold(
      title: l10n.t('hotels'),
      onRefresh: () async {
        ref.invalidate(hotelsProvider);
        await ref.read(hotelsProvider.future);
      },
      actions: [
        if (canCreateHotel)
          IconButton(
            tooltip: l10n.t('createHotel'),
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () => _showCreateHotelDialog(context, ref),
          ),
      ],
      child: AsyncValueView(
        value: ref.watch(hotelsProvider),
        onRetry: () => ref.invalidate(hotelsProvider),
        builder: (hotels) => Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final hotel in hotels)
              _PremiumHotelCard(
                hotel: hotel,
                onEdit: () => _showHotelEditRequestDialog(context, ref, hotel),
                onDelete: canCreateHotel ? () => _confirmDeleteHotel(context, ref, hotel) : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteHotel(
    BuildContext context,
    WidgetRef ref,
    Hotel hotel,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('delete')),
        content: Text(l10n.tParams('confirmDeleteHotel', {'hotelName': hotel.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('btnCancel')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteHotel(hotel.id);
        ref.invalidate(hotelsProvider);
        if (context.mounted) {
          PremiumSnackbar.showSuccess(context, l10n.t('hotelDeleted'));
        }
      } catch (e) {
        if (context.mounted) {
          PremiumSnackbar.showError(context, e);
        }
      }
    }
  }

  Future<void> _showCreateHotelDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CreateHotelDialog(),
    );
    ref.invalidate(hotelsProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> _showHotelEditRequestDialog(
    BuildContext context,
    WidgetRef ref,
    Hotel hotel,
  ) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _HotelEditRequestDialog(
        hotel: hotel,
        applyImmediately: currentUser?.isIvraUser ?? false,
      ),
    );
    ref.invalidate(hotelsProvider);
    ref.invalidate(approvalsProvider);
    ref.invalidate(dashboardProvider);
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _PremiumHotelCard extends StatefulWidget {
  const _PremiumHotelCard({required this.hotel, required this.onEdit, this.onDelete});

  final Hotel hotel;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  State<_PremiumHotelCard> createState() => _PremiumHotelCardState();
}

class _PremiumHotelCardState extends State<_PremiumHotelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hotel = widget.hotel;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary
                      .withValues(alpha: _isHovered ? 0.15 : 0.0),
                  blurRadius: _isHovered ? 20 : 0,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              borderColor: theme.colorScheme.outline
                  .withValues(alpha: _isHovered ? 0.3 : 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.6),
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                hotel.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (hotel.pendingEdits > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pending_actions,
                                      size: 14,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${hotel.pendingEdits}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (hotel.legalName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            hotel.legalName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_city_outlined,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${hotel.city}, ${hotel.country}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _Line(Icons.person_outline, hotel.contactName),
                        _Line(Icons.email_outlined, hotel.email),
                        _Line(Icons.phone_outlined, hotel.phone),
                        if (hotel.address.isNotEmpty)
                          _Line(Icons.location_on_outlined, hotel.address),
                        if (hotel.notes.isNotEmpty)
                          _Line(Icons.notes_outlined, hotel.notes),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.room_service_outlined,
                                  size: 16,
                                  color:
                                      theme.colorScheme.onSecondaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${hotel.roomCount}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    l10n.t('hotelRoomsTracked'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? theme.colorScheme.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                tooltip: l10n.t('requestHotelEdit'),
                                icon: Icon(
                                  Icons.edit_note_outlined,
                                  color: _isHovered
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: widget.onEdit,
                              ),
                            ),
                            if (widget.onDelete != null) ...[
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: _isHovered
                                      ? theme.colorScheme.errorContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  tooltip: l10n.t('delete'),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: _isHovered
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: widget.onDelete,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateHotelDialog extends ConsumerStatefulWidget {
  const _CreateHotelDialog();

  @override
  ConsumerState<_CreateHotelDialog> createState() => _CreateHotelDialogState();
}

class _CreateHotelDialogState extends ConsumerState<_CreateHotelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _legalName = TextEditingController();
  TunisianState _selectedState = TunisianState.tunis;
  final _country = TextEditingController(text: 'Tunisia');
  final _contactName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  var _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    _legalName.dispose();
    _country.dispose();
    _contactName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('createHotel'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RequiredTextField(
                          controller: _name, label: l10n.t('hotelLabelName')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _legalName,
                        decoration: InputDecoration(
                            labelText: l10n.t('hotelLabelLegalName')),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TunisianState>(
                              isExpanded: true,
                              initialValue: _selectedState,
                              decoration: InputDecoration(
                                  labelText: l10n.t('hotelLabelState')),
                              items: [
                                for (final state in TunisianState.values)
                                  DropdownMenuItem(
                                    value: state,
                                    child: Text(state.displayName,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedState = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RequiredTextField(
                              controller: _country,
                              label: l10n.t('hotelLabelCountry'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RequiredTextField(
                        controller: _contactName,
                        label: l10n.t('hotelLabelContactName'),
                      ),
                      const SizedBox(height: 12),
                      _RequiredTextField(
                          controller: _email, label: l10n.t('hotelLabelEmail')),
                      const SizedBox(height: 12),
                      _RequiredTextField(
                          controller: _phone, label: l10n.t('hotelLabelPhone')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: InputDecoration(
                            labelText: l10n.t('hotelLabelAddress')),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        decoration: InputDecoration(
                          labelText: l10n.t('hotelLabelNotes'),
                          alignLabelWithHint: true,
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.add_business_outlined),
                  label: Text(l10n.t('btnCreate')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(repositoryProvider).createHotel(
            name: _name.text.trim(),
            legalName: _legalName.text.trim(),
            city: _selectedState.displayName,
            country: _country.text.trim(),
            contactName: _contactName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            notes: _notes.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        PremiumSnackbar.showSuccess(context, AppLocalizations.of(context).t('hotelCreatedSuccessfully'),);
      }
    } catch (error) {
      if (!mounted) return;
      PremiumSnackbar.showSuccess(context, localizeAuthError(
            AppLocalizations.of(context),
            error,
            fallbackKey: 'hotelCreateFailed',
          ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _HotelEditRequestDialog extends ConsumerStatefulWidget {
  const _HotelEditRequestDialog({
    required this.hotel,
    required this.applyImmediately,
  });

  final Hotel hotel;
  final bool applyImmediately;

  @override
  ConsumerState<_HotelEditRequestDialog> createState() =>
      _HotelEditRequestDialogState();
}

class _HotelEditRequestDialogState
    extends ConsumerState<_HotelEditRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _legalName;
  late TunisianState _selectedState;
  late TextEditingController _country;
  late final TextEditingController _contactName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.hotel.name);
    _legalName = TextEditingController(text: widget.hotel.legalName);
    _selectedState =
        TunisianState.fromString(widget.hotel.city) ?? TunisianState.tunis;
    _country = TextEditingController(
        text: widget.hotel.country.isEmpty ? 'Tunisia' : widget.hotel.country);
    _contactName = TextEditingController(text: widget.hotel.contactName);
    _email = TextEditingController(text: widget.hotel.email);
    _phone = TextEditingController(text: widget.hotel.phone);
    _address = TextEditingController(text: widget.hotel.address);
    _notes = TextEditingController(text: widget.hotel.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _legalName.dispose();
    _country.dispose();
    _contactName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.t('requestHotelEdit')} - ${widget.hotel.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RequiredTextField(
                          controller: _name, label: l10n.t('hotelLabelName')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _legalName,
                        decoration: InputDecoration(
                            labelText: l10n.t('hotelLabelLegalName')),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TunisianState>(
                              isExpanded: true,
                              initialValue: _selectedState,
                              decoration: InputDecoration(
                                  labelText: l10n.t('hotelLabelState')),
                              items: [
                                for (final state in TunisianState.values)
                                  DropdownMenuItem(
                                    value: state,
                                    child: Text(state.displayName,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedState = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RequiredTextField(
                              controller: _country,
                              label: l10n.t('hotelLabelCountry'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RequiredTextField(
                        controller: _contactName,
                        label: l10n.t('hotelLabelContactName'),
                      ),
                      const SizedBox(height: 12),
                      _RequiredTextField(
                          controller: _email, label: l10n.t('hotelLabelEmail')),
                      const SizedBox(height: 12),
                      _RequiredTextField(
                          controller: _phone, label: l10n.t('hotelLabelPhone')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: InputDecoration(
                            labelText: l10n.t('hotelLabelAddress')),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        decoration: InputDecoration(
                          labelText: l10n.t('hotelLabelNotes'),
                          alignLabelWithHint: true,
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: Icon(
                    widget.applyImmediately
                        ? Icons.save_outlined
                        : Icons.pending_actions_outlined,
                  ),
                  label: Text(widget.applyImmediately
                      ? l10n.t('btnSave')
                      : l10n.t('btnSubmitRequest')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final title = 'Update hotel information for ${widget.hotel.name}';
      final oldData = {
        'name': widget.hotel.name,
        'legal_name': widget.hotel.legalName,
        'city': widget.hotel.city,
        'country': widget.hotel.country,
        'contact_name': widget.hotel.contactName,
        'email': widget.hotel.email,
        'phone': widget.hotel.phone,
        'address': widget.hotel.address,
        'notes': widget.hotel.notes,
      };
      final newData = {
        'name': _name.text.trim(),
        'legal_name': _legalName.text.trim(),
        'city': _selectedState.displayName,
        'country': _country.text.trim(),
        'contact_name': _contactName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'notes': _notes.text.trim(),
      };
      final offline = ref.read(offlineModeProvider);
      if (offline) {
        await ref.read(offlineSyncServiceProvider).enqueue(
          type: SyncActionType.pendingEdit,
          payload: {
            'hotelId': widget.hotel.id,
            'title': title,
            'targetTable': 'hotels',
            'targetId': widget.hotel.id,
            'oldData': oldData,
            'newData': newData,
          },
        );
        ref.invalidate(offlineActionsProvider);
      } else {
        final requestId =
            await ref.read(repositoryProvider).submitChangeRequest(
                  hotelId: widget.hotel.id,
                  title: title,
                  targetTable: 'hotels',
                  targetId: widget.hotel.id,
                  oldData: oldData,
                  newData: newData,
                );
        if (widget.applyImmediately && requestId != null) {
          await ref.read(repositoryProvider).approveRequest(
                approvalRequestId: requestId,
              );
        }
      }
      if (mounted) {
        Navigator.of(context).pop();
        PremiumSnackbar.showSuccess(context, offline
                  ? l10n.t('editRequestQueued')
                  : widget.applyImmediately
                      ? l10n.t('hotelUpdated')
                      : l10n.t('editRequestSubmitted'),);
      }
    } catch (error) {
      if (!mounted) return;
      PremiumSnackbar.showSuccess(context, localizeAuthError(
            l10n,
            error,
            fallbackKey: 'hotelUpdateFailed',
          ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RequiredTextField extends StatelessWidget {
  const _RequiredTextField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.t('requiredField');
        }
        return null;
      },
    );
  }
}
