import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class InventoryScreen extends ConsumerStatefulWidget {
  final String? hotelId;
  const InventoryScreen({super.key, this.hotelId});

  static const route = '/inventory';

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

enum InventorySortOption { nameAsc, nameDesc, fullBottlesDesc, emptyBottlesDesc }

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'lowStock'
  InventorySortOption _sortOption = InventorySortOption.nameAsc;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.hotelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHotelIdProvider.notifier).state = widget.hotelId;
      });
    }
  }

  @override
  void didUpdateWidget(covariant InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hotelId != oldWidget.hotelId && widget.hotelId != null) {
      ref.read(selectedHotelIdProvider.notifier).state = widget.hotelId;
    }
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
      onRefresh: () async {
        ref.invalidate(hotelsProvider);
        ref.invalidate(inventoryProvider);
        ref.invalidate(suggestedOrdersProvider);
        await Future.wait([
          ref.read(hotelsProvider.future),
          ref.read(inventoryProvider.future),
          ref.read(suggestedOrdersProvider.future),
        ]);
      },
      actions: [
        IconButton(
          tooltip: l10n.t('adjustStockTitle'),
          icon: const Icon(Icons.add_box_outlined),
          onPressed: () => _showStockAdjustmentDialog(context),
        ),
        IconButton(
          tooltip: l10n.t('bulkAdjustStockTitle'),
          icon: const Icon(Icons.playlist_add_check_outlined),
          onPressed: () => _showBulkStockAdjustmentDialog(context),
        ),
      ],
      child: AsyncValueView(
        value: hotelsAsync,
        onRetry: () {
          ref.invalidate(hotelsProvider);
          ref.invalidate(inventoryProvider);
          ref.invalidate(suggestedOrdersProvider);
        },
        builder: (hotels) {
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
                ref.read(selectedHotelIdProvider.notifier).state = autoSelectId;
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
                  onRetry: () => ref.invalidate(inventoryProvider),
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
                      final name = item.product
                          .label(Localizations.localeOf(context).languageCode)
                          .toLowerCase();
                      final sku = item.product.sku.toLowerCase();
                      if (_searchQuery.isEmpty) return true;
                      return name.contains(_searchQuery.toLowerCase()) ||
                          sku.contains(_searchQuery.toLowerCase());
                    }).toList();

                    // Apply status filter
                    final filteredItems = searchedItems.where((item) {
                      if (_statusFilter == 'lowStock') {
                        return item.lowBottles || item.lowBidons;
                      }
                      return true;
                    }).toList();

                    // Apply sort
                    final languageCode = Localizations.localeOf(context).languageCode;
                    filteredItems.sort((a, b) {
                      switch (_sortOption) {
                        case InventorySortOption.nameAsc:
                          return a.product.label(languageCode).compareTo(b.product.label(languageCode));
                        case InventorySortOption.nameDesc:
                          return b.product.label(languageCode).compareTo(a.product.label(languageCode));
                        case InventorySortOption.fullBottlesDesc:
                          return b.fullBottles.compareTo(a.fullBottles);
                        case InventorySortOption.emptyBottlesDesc:
                          return b.emptyBottles.compareTo(a.emptyBottles);
                      }
                    });

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
                  onRetry: () => ref.invalidate(suggestedOrdersProvider),
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
                      final name = order.product
                          .label(Localizations.localeOf(context).languageCode)
                          .toLowerCase();
                      final sku = order.product.sku.toLowerCase();
                      return name.contains(_searchQuery.toLowerCase()) ||
                          sku.contains(_searchQuery.toLowerCase());
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
                          icon:
                              Icon(Icons.arrow_drop_down, color: primaryColor),
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
                              ref.read(selectedHotelIdProvider.notifier).state =
                                  val;
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
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: Colors.grey),
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: theme.colorScheme.outlineVariant),
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
                    color: _statusFilter == 'all'
                        ? primaryColor
                        : theme.colorScheme.onSurface,
                    fontWeight: _statusFilter == 'all'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _statusFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                  label: Text(l10n.t('inventoryStatusLowStock')),
                  selected: _statusFilter == 'lowStock',
                  selectedColor:
                      theme.colorScheme.error.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.error,
                  labelStyle: TextStyle(
                    color: _statusFilter == 'lowStock'
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                    fontWeight: _statusFilter == 'lowStock'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _statusFilter = 'lowStock');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sort Options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.sort, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.t('sortNameAsc') ?? 'Name (A-Z)'),
                  selected: _sortOption == InventorySortOption.nameAsc,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortOption = InventorySortOption.nameAsc);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.t('sortNameDesc') ?? 'Name (Z-A)'),
                  selected: _sortOption == InventorySortOption.nameDesc,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortOption = InventorySortOption.nameDesc);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.t('sortMostFullBottles') ?? 'Most Full Bottles'),
                  selected: _sortOption == InventorySortOption.fullBottlesDesc,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortOption = InventorySortOption.fullBottlesDesc);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.t('sortMostEmptyBottles') ?? 'Most Empty Bottles'),
                  selected: _sortOption == InventorySortOption.emptyBottlesDesc,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortOption = InventorySortOption.emptyBottlesDesc);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBulkStockAdjustmentDialog(BuildContext context) async {
    final selectedHotelId = ref.read(selectedHotelIdProvider);
    final l10n = AppLocalizations.of(context);

    if (selectedHotelId == null) {
      PremiumSnackbar.show(
        context,
        l10n.t('roomsSelectHotelFirst'),
        icon: Icons.domain_outlined,
      );
      return;
    }

    final products = await ref.read(productsProvider.future);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => _BulkStockAdjustmentDialog(
        hotelId: selectedHotelId,
        products: products,
      ),
    );
  }

  Future<void> _showStockAdjustmentDialog(BuildContext context) async {
    final items = await ref.read(inventoryProvider.future);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final selectedHotelId = ref.read(selectedHotelIdProvider);

    if (selectedHotelId == null) {
      PremiumSnackbar.show(
        context,
        l10n.t('roomsSelectHotelFirst'),
        icon: Icons.domain_outlined,
      );
      return;
    }

    // Filter available adjustment items to only the currently selected hotel's inventory items!
    final hotelItems =
        items.where((item) => item.hotelId == selectedHotelId).toList();

    // Fetch all available products so we can allow adding stock for products not yet in the hotel's inventory.
    final products = await ref.read(productsProvider.future);
    if (!context.mounted) return;
    final allHotelItems = products.map((product) {
      final existing = hotelItems
          .where((item) => item.product.id == product.id)
          .firstOrNull;
      return existing ??
          InventoryItem(
            id: 'new_${product.id}',
            hotelId: selectedHotelId,
            product: product,
            fullBottles: 0,
            emptyBottles: 0,
            fullBidons: 0,
            openBidons: 0,
            emptyBidons: 0,
          );
    }).toList();

    if (allHotelItems.isEmpty) {
      PremiumSnackbar.show(
        context,
        l10n.t('inventoryNoItemsToAdjust'),
        icon: Icons.error_outline,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _StockAdjustmentDialog(items: allHotelItems),
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
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.t('inventoryNoInventoryYet'),
        message: l10n.t('inventoryNoProductsInInventory'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: isMobile ? 1.0 : 1.3,
          children: [
            for (final item in items)
              _PremiumInventoryCard(item: item, language: language),
          ],
        );
      },
    );
  }
}

class _PremiumInventoryCard extends StatefulWidget {
  const _PremiumInventoryCard({
    required this.item,
    required this.language,
  });

  final InventoryItem item;
  final String language;

  @override
  State<_PremiumInventoryCard> createState() => _PremiumInventoryCardState();
}

class _PremiumInventoryCardState extends State<_PremiumInventoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lowStock = widget.item.lowBottles || widget.item.lowBidons;
    final statusColor =
        lowStock ? theme.colorScheme.error : theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.95),
                theme.colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 24 : 12,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: _isHovered ? 0.4 : 0.15),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      lowStock
                          ? Icons.priority_high_rounded
                          : Icons.inventory_2_outlined,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.product.label(widget.language),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.item.product.sku,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _InventoryStatusPill(lowStock: lowStock),
                ],
              ),
              const Spacer(),
              // Visual Stock Indicators
              _VisualStockBar(
                label: l10n.t('inventoryTableFullBottles'),
                value: widget.item.fullBottles,
                threshold: widget.item.product.lowBottleThreshold,
                icon: Icons.water_drop_outlined,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _VisualStockBar(
                label: l10n.t('inventoryTableFullBidons'),
                value: widget.item.fullBidons,
                threshold: widget.item.product.lowBidonThreshold,
                icon: Icons.propane_tank_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              // Smaller stats for empties/open
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                      label: l10n.t('inventoryTableEmptyBottles'),
                      value: widget.item.emptyBottles,
                      icon: Icons.recycling_outlined,
                      color: theme.colorScheme.tertiary,
                    ),
                    Container(width: 1, height: 24, color: theme.dividerColor),
                    _MiniStat(
                      label: l10n.t('inventoryTableOpenBidons'),
                      value: widget.item.openBidons,
                      icon: Icons.oil_barrel_outlined,
                      color: Colors.indigo,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualStockBar extends StatelessWidget {
  const _VisualStockBar({
    required this.label,
    required this.value,
    required this.threshold,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final int threshold;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = value <= threshold;
    final displayColor = isLow ? theme.colorScheme.error : color;

    // Calculate an artificial percentage based on threshold (e.g. threshold * 3 is 100%)
    final maxExpected = (threshold * 3).clamp(10, 1000);
    final percentage =
        (value / maxExpected).clamp(0.05, 1.0); // At least 5% so it's visible

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: displayColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: displayColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      displayColor.withValues(alpha: 0.7),
                      displayColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Threshold marker
            Positioned(
              left: 0,
              right: 0,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (threshold / maxExpected).clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 2,
                    height: 8,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Replaced with _PremiumInventoryCard

class _InventoryStatusPill extends StatelessWidget {
  const _InventoryStatusPill({required this.lowStock});

  final bool lowStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color =
        lowStock ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        lowStock
            ? l10n.t('inventoryStatusLowStock')
            : l10n.t('inventoryStatusHealthy'),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
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
  bool _showAdvanced = false;

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
                  value: _inventoryItemId,
                  decoration: InputDecoration(
                      labelText: l10n.t('inventoryTableProduct')),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined,
                          size: 16, color: theme.colorScheme.primary),
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
                Column(
                  children: [
                    _DeltaField(
                      controller: _fullBottles,
                      label: l10n.t('inventoryTableFullBottles'),
                    ),
                    const SizedBox(height: 12),
                    _DeltaField(
                      controller: _emptyBottles,
                      label: l10n.t('inventoryTableEmptyBottles'),
                    ),
                    const SizedBox(height: 12),
                    _DeltaField(
                      controller: _fullBidons,
                      label: l10n.t('inventoryTableFullBidons'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAdvanced = !_showAdvanced;
                        });
                      },
                      icon: Icon(_showAdvanced
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      label: Text(l10n.t('more')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                    if (_showAdvanced) ...[
                      const SizedBox(height: 8),
                      _DeltaField(
                        controller: _openBidons,
                        label: l10n.t('inventoryTableOpenBidons'),
                      ),
                      const SizedBox(height: 12),
                      _DeltaField(
                        controller: _emptyBidons,
                        label: emptyBidonsLabel,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reason,
                  decoration:
                      InputDecoration(labelText: l10n.t('hotelLabelNotes')),
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
    final lang = Localizations.localeOf(context).languageCode;

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
              
          final newAlertsCount = await ref.read(repositoryProvider).refreshSmartAlerts(hotelId: item.hotelId);
          debugPrint('[ALERT-PUSH] refreshSmartAlerts returned $newAlertsCount new alerts');
          if (newAlertsCount > 0) {
            ref.invalidate(alertsProvider);
            try {
              if (Supabase.instance.client.auth.currentSession != null) {
                // Fetch the new alerts directly from repository to bypass any Riverpod cache issues
                final latestAlerts = await ref.read(repositoryProvider).alerts(hotelId: item.hotelId);
                final products = await ref.read(productsProvider.future);
                
                debugPrint('[ALERT-PUSH] Fetched ${latestAlerts.length} alerts, ${products.length} products');
                
                final unresolved = latestAlerts.where((a) => !a.isResolved).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                
                debugPrint('[ALERT-PUSH] ${unresolved.length} unresolved alerts, sending up to $newAlertsCount');
                
                // Send notifications for the newest alerts (most recently created)
                for (var i = 0; i < newAlertsCount && i < unresolved.length; i++) {
                   final alert = unresolved[i];
                   final product = products.where((p) => p.id == alert.productId).firstOrNull;
                   
                   debugPrint('[ALERT-PUSH] Alert type=${alert.type.value}, productId=${alert.productId}, product found=${product != null}');
                   debugPrint('[ALERT-PUSH] Raw title="${alert.title}", Raw body="${alert.body}"');
                   
                   final (pushTitle, pushBody) = alert.localizedStrings(l10n, lang, product);
                   
                   debugPrint('[ALERT-PUSH] Translated title="$pushTitle", body="$pushBody"');
                   
                   await Supabase.instance.client.functions.invoke(
                     'send-notification',
                     body: {
                       'title': pushTitle,
                       'body': pushBody,
                       'targetType': 'hotel',
                       'targetValue': item.hotelId,
                       'targetPage': '/alerts',
                       'actionButtons': [
                         {
                           'id': 'more_info',
                           'title': l10n.t('notificationMoreInfo'),
                         },
                         {
                           'id': 'resolve',
                           'title': l10n.t('alertsResolve'),
                         },
                         {
                           'id': 'delete',
                           'title': l10n.t('delete'),
                         },
                       ],
                       'data': {
                         'alertId': alert.id,
                         'hotelId': item.hotelId,
                       },
                     },
                   );
                   debugPrint('[ALERT-PUSH] Notification sent successfully for alert ${alert.id}');
                }
              }
            } catch (e) {
              debugPrint('[ALERT-PUSH] Failed to dispatch alert push notification: $e');
            }
          }
        } catch (e) {
          if (e.toString().contains('SocketException') ||
              e.toString().contains('ClientException') ||
              e.toString().contains('Failed host lookup') ||
              e.toString().contains('XMLHttpRequest')) {
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

class _DeltaField extends StatefulWidget {
  const _DeltaField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  State<_DeltaField> createState() => _DeltaFieldState();
}

class _DeltaFieldState extends State<_DeltaField> {
  void _increment() {
    final current = int.tryParse(widget.controller.text) ?? 0;
    widget.controller.text = (current + 1).toString();
  }

  void _decrement() {
    final current = int.tryParse(widget.controller.text) ?? 0;
    widget.controller.text = (current - 1).toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: _decrement,
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: widget.controller,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    validator: (value) {
                      if (int.tryParse(value ?? '') == null) {
                        return '!';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _increment,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
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
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: l10n.t('inventoryNoSuggestedOrders'),
        message: l10n.t('inventoryLevelsSufficient'),
      );
    }

    final cards = [
      for (final order in orders)
        SizedBox(
          width: isMobile ? double.infinity : 320,
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        color: theme.colorScheme.primary),
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
                  l10n.tParams(
                    'orderNewBottlesText',
                    {'count': '${order.bottlesToOrder}'},
                  ),
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _SuggestedOrderRow(
                  Icons.propane_tank_outlined,
                  l10n.tParams(
                    'orderNewBidonsText',
                    {'count': '${order.bidonsToOrder}'},
                  ),
                  theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                _SuggestedOrderRow(
                  Icons.recycling_outlined,
                  l10n.tParams(
                    'recycleBottlesText',
                    {'count': '${order.bottlesToRecycle}'},
                  ),
                  theme.colorScheme.error,
                ),
              ],
            ),
          ),
        ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards,
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

class _BulkStockAdjustmentDialog extends ConsumerStatefulWidget {
  const _BulkStockAdjustmentDialog({
    required this.hotelId,
    required this.products,
  });

  final String hotelId;
  final List<Product> products;

  @override
  ConsumerState<_BulkStockAdjustmentDialog> createState() =>
      _BulkStockAdjustmentDialogState();
}

class _BulkStockAdjustmentDialogState
    extends ConsumerState<_BulkStockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullBottles = TextEditingController(text: '0');
  final _emptyBottles = TextEditingController(text: '0');
  final _fullBidons = TextEditingController(text: '0');
  final _openBidons = TextEditingController(text: '0');
  final _emptyBidons = TextEditingController(text: '0');
  final _reason = TextEditingController();
  var _isSaving = false;
  bool _showAdvanced = false;
  Set<String> _selectedProductIds = {};

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
    final theme = Theme.of(context);

    final emptyBidonsLabel = l10n.t('inventoryTableEmptyBidons').isNotEmpty
        ? l10n.t('inventoryTableEmptyBidons')
        : 'Empty Bidons';

    return AlertDialog(
      title: Text(
        l10n.t('bulkAdjustStockTitle'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('bulkAdjustStockHint'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('bulkAdjustSelectProducts') ?? 'Select Products',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedProductIds = widget.products.map((p) => p.id).toSet();
                        });
                      },
                      child: Text(l10n.t('bulkAdjustSelectAll') ?? 'Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedProductIds.clear();
                        });
                      },
                      child: Text(l10n.t('bulkAdjustDeselectAll') ?? 'Deselect All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.products.map((p) {
                    final isSelected = _selectedProductIds.contains(p.id);
                    return FilterChip(
                      label: Text(p.label(Localizations.localeOf(context).languageCode)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedProductIds.add(p.id);
                          } else {
                            _selectedProductIds.remove(p.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    _DeltaField(
                      controller: _fullBottles,
                      label: l10n.t('inventoryTableFullBottles'),
                    ),
                    const SizedBox(height: 12),
                    _DeltaField(
                      controller: _emptyBottles,
                      label: l10n.t('inventoryTableEmptyBottles'),
                    ),
                    const SizedBox(height: 12),
                    _DeltaField(
                      controller: _fullBidons,
                      label: l10n.t('inventoryTableFullBidons'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAdvanced = !_showAdvanced;
                        });
                      },
                      icon: Icon(_showAdvanced
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      label: Text(l10n.t('more')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                    if (_showAdvanced) ...[
                      const SizedBox(height: 8),
                      _DeltaField(
                        controller: _openBidons,
                        label: l10n.t('inventoryTableOpenBidons'),
                      ),
                      const SizedBox(height: 12),
                      _DeltaField(
                        controller: _emptyBidons,
                        label: emptyBidonsLabel,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reason,
                  decoration:
                      InputDecoration(labelText: l10n.t('hotelLabelNotes')),
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
          icon: const Icon(Icons.playlist_add_check_outlined),
          label: Text(l10n.t('btnSave')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    if (_selectedProductIds.isEmpty) {
      PremiumSnackbar.showError(
        context,
        l10n.t('bulkAdjustNoProductsSelected') ?? 'Please select at least one product.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final fullBottlesDelta = int.parse(_fullBottles.text);
      final emptyBottlesDelta = int.parse(_emptyBottles.text);
      final fullBidonsDelta = int.parse(_fullBidons.text);
      final openBidonsDelta = int.parse(_openBidons.text);
      final emptyBidonsDelta = int.parse(_emptyBidons.text);
      final reason = _reason.text.trim();

      var isOffline = ref.read(offlineModeProvider);

      final selectedProducts = widget.products.where((p) => _selectedProductIds.contains(p.id));

      for (final product in selectedProducts) {
        final payload = {
          'hotelId': widget.hotelId,
          'productId': product.id,
          'fullBottlesDelta': fullBottlesDelta,
          'emptyBottlesDelta': emptyBottlesDelta,
          'fullBidonsDelta': fullBidonsDelta,
          'openBidonsDelta': openBidonsDelta,
          'emptyBidonsDelta': emptyBidonsDelta,
          'reason': reason,
        };

        if (!isOffline) {
          try {
            await ref.read(repositoryProvider).recordStockAdjustment(
                  hotelId: widget.hotelId,
                  productId: product.id,
                  fullBottlesDelta: fullBottlesDelta,
                  emptyBottlesDelta: emptyBottlesDelta,
                  fullBidonsDelta: fullBidonsDelta,
                  openBidonsDelta: openBidonsDelta,
                  emptyBidonsDelta: emptyBidonsDelta,
                  reason: reason,
                );
          } catch (e) {
            if (e.toString().contains('SocketException') ||
                e.toString().contains('ClientException') ||
                e.toString().contains('Failed host lookup') ||
                e.toString().contains('XMLHttpRequest')) {
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
        }
      }

      if (!isOffline) {
        await ref.read(repositoryProvider).refreshSmartAlerts(hotelId: widget.hotelId);
      }

      ref.invalidate(inventoryProvider);
      ref.invalidate(suggestedOrdersProvider);
      ref.invalidate(alertsProvider);

      if (isOffline) {
        ref.invalidate(offlineActionsProvider);
      }

      if (mounted) {
        Navigator.of(context).pop();
        PremiumSnackbar.show(
          context,
          isOffline
              ? (l10n.t('bulkAdjustStockOfflineQueued'))
              : (l10n.t('bulkAdjustStockSuccess')),
          icon: isOffline ? Icons.cloud_queue : Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
