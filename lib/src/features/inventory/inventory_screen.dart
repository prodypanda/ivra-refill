import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/empty_state.dart';
import '../shared/premium_snackbar.dart';
import '../shared/shimmer_loading.dart';
import '../shared/premium_loading.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  static const route = '/inventory';

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'lowStock'
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFF2A900); // Golden yellow/orange

    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final hotelsAsync = ref.watch(hotelsProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final suggestedOrdersAsync = ref.watch(suggestedOrdersProvider);

    return PageScaffold(
      title: l10n.t('inventory'),
      actions: [
        IconButton(
          tooltip: l10n.t('adjustStockTitle'),
          icon: const Icon(Icons.add_box_outlined),
          onPressed: () => _showStockAdjustmentDialog(context),
        ),
      ],
      child: hotelsAsync.when(
        loading: () => const Center(child: PremiumLoadingWidget()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (hotels) {
          if (hotels.isEmpty) {
            return EmptyState(
              icon: Icons.hotel_outlined,
              title: l10n.t('inventoryNoHotels'),
              message: l10n.t('inventoryAddHotelHint'),
            );
          }

          // Inventory has no cross-hotel aggregate view, so we narrow down
          // to a single hotel automatically when there is no ambiguity:
          //   - hotel-bound users are already scoped by the splash gate, but
          //     re-confirm here in case the list filter changes their hotel
          //     out of view;
          //   - admin / app-wide users only get auto-selected when exactly
          //     one hotel is visible. With multiple hotels the dropdown
          //     stays as the explicit choice so we never silently turn the
          //     dashboard/rooms/alerts cross-hotel view into a single-hotel
          //     view as a side effect of visiting Inventory.
          if (selectedHotelId == null && hotels.isNotEmpty) {
            final userHotelId = currentUser?.hotelId;
            final autoSelectId = userHotelId != null &&
                    hotels.any((hotel) => hotel.id == userHotelId)
                ? userHotelId
                : (hotels.length == 1 ? hotels.first.id : null);
            if (autoSelectId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedHotelIdProvider.notifier).state =
                    autoSelectId;
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildControlPanel(
                hotels,
                l10n,
                theme,
                primaryColor,
                currentUser,
                selectedHotelId,
              ),
              const SizedBox(height: 20),
              if (selectedHotelId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      l10n.t('roomsSelectHotelFirst'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else ...[
                AsyncValueView(
                  value: inventoryAsync,
                  loadingWidget: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CardShimmer(),
                    ),
                  ),
                  builder: (items) {
                    // Filter items by hotel
                    final hotelItems = items
                        .where((item) => item.hotelId == selectedHotelId)
                        .toList();

                    // Apply search query
                    final searchedItems = hotelItems.where((item) {
                      final name = item.product.label(Localizations.localeOf(context).languageCode).toLowerCase();
                      final sku = item.product.sku.toLowerCase();
                      if (_searchQuery.isEmpty) return true;
                      return name.contains(_searchQuery.toLowerCase()) || sku.contains(_searchQuery.toLowerCase());
                    }).toList();

                    // Apply status filter
                    final filteredItems = searchedItems.where((item) {
                      if (_statusFilter == 'lowStock') {
                        return item.lowBottles || item.lowBidons;
                      }
                      return true;
                    }).toList();

                    return _InventoryTable(items: filteredItems);
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.t('suggestedOrders'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                AsyncValueView(
                  value: suggestedOrdersAsync,
                  loadingWidget: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CardShimmer(),
                  ),
                  builder: (orders) {
                    // Filter orders by hotel and search query
                    final filteredOrders = orders.where((order) {
                      final matchHotel = order.hotelId == selectedHotelId;
                      if (!matchHotel) return false;

                      if (_searchQuery.isEmpty) return true;
                      final name = order.product.label(Localizations.localeOf(context).languageCode).toLowerCase();
                      final sku = order.product.sku.toLowerCase();
                      return name.contains(_searchQuery.toLowerCase()) || sku.contains(_searchQuery.toLowerCase());
                    }).toList();

                    return _SuggestedOrders(orders: filteredOrders);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlPanel(
    List<Hotel> hotels,
    AppLocalizations l10n,
    ThemeData theme,
    Color primaryColor,
    UserProfile? currentUser,
    String? selectedHotelId,
  ) {
    // Lock the hotel selector to a static label for users who have nothing to
    // choose between (hotel-scoped users, or app-wide users with a single
    // visible hotel).
    final userHotelId = currentUser?.hotelId;
    final userIsHotelScoped =
        userHotelId != null && hotels.any((hotel) => hotel.id == userHotelId);
    final isScoped = userIsHotelScoped || hotels.length == 1;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hotel Selector Row
            Row(
              children: [
                Icon(Icons.business_outlined, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: isScoped
                      ? Text(
                          hotels
                              .firstWhere(
                                (h) => h.id == selectedHotelId,
                                orElse: () => hotels.first,
                              )
                              .name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedHotelId,
                            hint: Text(l10n.t('roomsSelectHotelFirst')),
                            icon: Icon(Icons.arrow_drop_down,
                                color: primaryColor),
                            items: [
                              for (final hotel in hotels)
                                DropdownMenuItem(
                                  value: hotel.id,
                                  child: Text(
                                    hotel.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(selectedHotelIdProvider.notifier)
                                    .state = val;
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Search Bar
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.t('roomsSearchPlaceholder'),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.t('roomsFilterAll')),
                    selected: _statusFilter == 'all',
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: _statusFilter == 'all' ? primaryColor : theme.colorScheme.onSurface,
                      fontWeight: _statusFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
                    label: Text(l10n.t('inventoryStatusLowStock')),
                    selected: _statusFilter == 'lowStock',
                    selectedColor: theme.colorScheme.error.withValues(alpha: 0.15),
                    checkmarkColor: theme.colorScheme.error,
                    labelStyle: TextStyle(
                      color: _statusFilter == 'lowStock' ? theme.colorScheme.error : theme.colorScheme.onSurface,
                      fontWeight: _statusFilter == 'lowStock' ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = 'lowStock');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _showStockAdjustmentDialog(BuildContext context) async {
    final items = await ref.read(inventoryProvider.future);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final selectedHotelId = ref.read(selectedHotelIdProvider);

    // Filter available adjustment items to only the currently selected hotel's inventory items!
    final hotelItems =
        items.where((item) => item.hotelId == selectedHotelId).toList();

    if (hotelItems.isEmpty) {
      PremiumSnackbar.show(
        context,
        l10n.t('inventoryNoItemsToAdjust'),
        icon: Icons.error_outline,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _StockAdjustmentDialog(items: hotelItems),
    );

    ref.invalidate(inventoryProvider);
    ref.invalidate(suggestedOrdersProvider);
    ref.invalidate(dashboardProvider);
  }
}

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.t('inventoryNoInventoryYet'),
        message: l10n.t('inventoryNoProductsInInventory'),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
          columns: [
            DataColumn(label: Text(l10n.t('inventoryTableProduct'), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(l10n.t('inventoryTableFullBottles'), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(l10n.t('inventoryTableEmptyBottles'), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(l10n.t('inventoryTableFullBidons'), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(l10n.t('inventoryTableOpenBidons'), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(l10n.t('inventoryTableStatus'), style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            for (final item in items)
              DataRow(
                cells: [
                  DataCell(Text(item.product.label(language), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${item.fullBottles}')),
                  DataCell(Text('${item.emptyBottles}')),
                  DataCell(Text('${item.fullBidons}')),
                  DataCell(Text('${item.openBidons}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item.lowBottles || item.lowBidons)
                            ? theme.colorScheme.errorContainer
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.lowBottles || item.lowBidons
                            ? l10n.t('inventoryStatusLowStock')
                            : l10n.t('inventoryStatusHealthy'),
                        style: TextStyle(
                          color: (item.lowBottles || item.lowBidons)
                              ? theme.colorScheme.onErrorContainer
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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

class _StockAdjustmentDialog extends ConsumerStatefulWidget {
  const _StockAdjustmentDialog({required this.items});

  final List<InventoryItem> items;

  @override
  ConsumerState<_StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState
    extends ConsumerState<_StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullBottles = TextEditingController(text: '0');
  final _emptyBottles = TextEditingController(text: '0');
  final _fullBidons = TextEditingController(text: '0');
  final _openBidons = TextEditingController(text: '0');
  final _emptyBidons = TextEditingController(text: '0');
  final _reason = TextEditingController();
  late String _inventoryItemId;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _inventoryItemId = widget.items.first.id;
  }

  @override
  void dispose() {
    _fullBottles.dispose();
    _emptyBottles.dispose();
    _fullBidons.dispose();
    _openBidons.dispose();
    _emptyBidons.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    final selectedItem = widget.items.firstWhere(
      (item) => item.id == _inventoryItemId,
    );

    final emptyBidonsLabel = l10n.t('inventoryTableEmptyBidons');

    return AlertDialog(
      title: Text(l10n.t('adjustStockTitle')),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _inventoryItemId,
                  decoration: InputDecoration(labelText: l10n.t('inventoryTableProduct')),
                  items: [
                    for (final item in widget.items)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(item.product.label(language)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _inventoryItemId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.t('bottles')}: ${selectedItem.fullBottles} | ${l10n.t('bidons')}: ${selectedItem.fullBidons}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DeltaField(
                      controller: _fullBottles,
                      label: '${l10n.t('inventoryTableFullBottles')} (+/-)',
                    ),
                    _DeltaField(
                      controller: _emptyBottles,
                      label: '${l10n.t('inventoryTableEmptyBottles')} (+/-)',
                    ),
                    _DeltaField(
                      controller: _fullBidons,
                      label: '${l10n.t('inventoryTableFullBidons')} (+/-)',
                    ),
                    _DeltaField(
                      controller: _openBidons,
                      label: '${l10n.t('inventoryTableOpenBidons')} (+/-)',
                    ),
                    _DeltaField(
                      controller: _emptyBidons,
                      label: '$emptyBidonsLabel (+/-)',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reason,
                  decoration: InputDecoration(labelText: l10n.t('hotelLabelNotes')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.t('requiredField');
                    }
                    return null;
                  },
                ),
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
          icon: const Icon(Icons.add_box_outlined),
          label: Text(l10n.t('adjustStockTitle')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = widget.items.firstWhere((item) => item.id == _inventoryItemId);
    final l10n = AppLocalizations.of(context);

    setState(() => _isSaving = true);
    try {
      final payload = {
        'hotelId': item.hotelId,
        'productId': item.product.id,
        'fullBottlesDelta': int.parse(_fullBottles.text),
        'emptyBottlesDelta': int.parse(_emptyBottles.text),
        'fullBidonsDelta': int.parse(_fullBidons.text),
        'openBidonsDelta': int.parse(_openBidons.text),
        'emptyBidonsDelta': int.parse(_emptyBidons.text),
        'reason': _reason.text.trim(),
      };
      var isOffline = ref.read(offlineModeProvider);
      if (!isOffline) {
        try {
          await ref.read(repositoryProvider).recordStockAdjustment(
                hotelId: item.hotelId,
                productId: item.product.id,
                fullBottlesDelta: payload['fullBottlesDelta'] as int,
                emptyBottlesDelta: payload['emptyBottlesDelta'] as int,
                fullBidonsDelta: payload['fullBidonsDelta'] as int,
                openBidonsDelta: payload['openBidonsDelta'] as int,
                emptyBidonsDelta: payload['emptyBidonsDelta'] as int,
                reason: payload['reason'] as String,
              );
        } catch (e) {
          if (e.toString().contains('SocketException') || e.toString().contains('ClientException') || e.toString().contains('Failed host lookup') || e.toString().contains('XMLHttpRequest')) {
            isOffline = true;
          } else {
            rethrow;
          }
        }
      }

      if (isOffline) {
        await ref.read(offlineSyncServiceProvider).enqueue(
              type: SyncActionType.stockAdjustment,
              payload: payload,
            );
        ref.invalidate(offlineActionsProvider);
      }

      if (mounted) {
        Navigator.of(context).pop();
        PremiumSnackbar.show(
          context,
          isOffline ? l10n.t('editRequestQueued') : l10n.t('hotelUpdated'),
          icon: Icons.check_circle_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DeltaField extends StatelessWidget {
  const _DeltaField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 164,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (int.tryParse(value ?? '') == null) {
            return l10n.t('enterNumberError');
          }
          return null;
        },
      ),
    );
  }
}

class _SuggestedOrders extends StatelessWidget {
  const _SuggestedOrders({required this.orders});

  final List<SuggestedOrder> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: l10n.t('inventoryNoSuggestedOrders'),
        message: l10n.t('inventoryLevelsSufficient'),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final order in orders)
          SizedBox(
            width: 320,
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.product.label(language),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _SuggestedOrderRow(
                      Icons.water_drop_outlined,
                      l10n.t('orderNewBottlesText').replaceAll('{count}', order.bottlesToOrder.toString()),
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _SuggestedOrderRow(
                      Icons.propane_tank_outlined,
                      l10n.t('orderNewBidonsText').replaceAll('{count}', order.bidonsToOrder.toString()),
                      theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _SuggestedOrderRow(
                      Icons.recycling_outlined,
                      l10n.t('recycleBottlesText').replaceAll('{count}', order.bottlesToRecycle.toString()),
                      theme.colorScheme.error,
                    ),
                  ],
                ),
            ),
          ),
      ],
    );
  }
}

class _SuggestedOrderRow extends StatelessWidget {
  const _SuggestedOrderRow(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.darkenForContrast(),
            ),
          ),
        ),
      ],
    );
  }
}

// Extends Color to calculate high-contrast text shades
extension _ColorExtension on Color {
  Color darkenForContrast() {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}
