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

class FemmeDeChambreScreen extends ConsumerStatefulWidget {
  const FemmeDeChambreScreen({super.key});

  static const route = '/femme-de-chambre';

  @override
  ConsumerState<FemmeDeChambreScreen> createState() => _FemmeDeChambreScreenState();
}

class _FemmeDeChambreScreenState extends ConsumerState<FemmeDeChambreScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Aesthetic gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF111827), const Color(0xFF1F2937), const Color(0xFF111827)]
          : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
    );

    final allocationsAsync = ref.watch(housekeeperAllocationsProvider);
    final productsAsync = ref.watch(productsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return PageScaffold(
      title: l10n.t('femmeDeChambre'),
      onRefresh: () async {
        ref.invalidate(housekeeperAllocationsProvider);
        ref.invalidate(productsProvider);
        await Future.wait([
          ref.read(housekeeperAllocationsProvider.future),
          ref.read(productsProvider.future),
        ]);
      },
      actions: [
        IconButton(
          tooltip: l10n.t('checkoutStock'),
          icon: const Icon(Icons.add_shopping_cart_outlined),
          onPressed: () => _showCheckoutDialog(context),
        ),
        IconButton(
          tooltip: l10n.t('returnStock'),
          icon: const Icon(Icons.assignment_return_outlined),
          onPressed: () => _showReturnDialog(context),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: AsyncValueView(
          value: allocationsAsync,
          builder: (allocations) {
            if (allocations.isEmpty) {
              return EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: l10n.t('housekeeperCart'),
                message: l10n.t('noAllocations'),
                actionLabel: l10n.t('checkoutStock'),
                onAction: () => _showCheckoutDialog(context),
              );
            }

            final totalFullBottles = allocations.fold<int>(0, (sum, item) => sum + item.fullBottles);
            final totalEmptyBottles = allocations.fold<int>(0, (sum, item) => sum + item.emptyBottles);
            final totalFullBidons = allocations.fold<int>(0, (sum, item) => sum + item.fullBidons);
            final totalOpenBidons = allocations.fold<int>(0, (sum, item) => sum + item.openBidons);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary cards row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.4 : 1.6,
                        children: [
                          _buildSummaryCard(
                            context,
                            title: l10n.t('fullBottles'),
                            value: '$totalFullBottles',
                            icon: Icons.local_drink,
                            color: const Color(0xFFF2A900),
                          ),
                          _buildSummaryCard(
                            context,
                            title: l10n.t('inventoryTableEmptyBottlesGeneric'),
                            value: '$totalEmptyBottles',
                            icon: Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          _buildSummaryCard(
                            context,
                            title: l10n.t('inventoryTableFullBidonsGeneric'),
                            value: '$totalFullBidons',
                            icon: Icons.opacity_outlined,
                            color: Colors.blueAccent,
                          ),
                          _buildSummaryCard(
                            context,
                            title: l10n.t('inventoryTableOpenBidons'),
                            value: '$totalOpenBidons',
                            icon: Icons.hourglass_empty,
                            color: Colors.teal,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Allocation list header
                  Text(
                    l10n.t('housekeeperCart'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Allocations cards
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allocations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final allocation = allocations[index];
                      return _buildAllocationCard(context, allocation);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationCard(BuildContext context, HousekeeperAllocation allocation) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final pName = isAr
        ? allocation.product.nameAr
        : (Localizations.localeOf(context).languageCode == 'fr'
            ? allocation.product.nameFr
            : allocation.product.nameEn);

    final openBidonPercentage = allocation.openBidons > 0 && allocation.product.bidonVolumeMl > 0
        ? (allocation.openBidonVolumeLeftMl / allocation.product.bidonVolumeMl * 100).clamp(0.0, 100.0)
        : 0.0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Product Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF2A900).withOpacity(0.1),
                  child: const Icon(Icons.local_shipping_outlined, color: Color(0xFFF2A900)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'SKU: ${allocation.product.sku}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Counts Grid
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMiniDetail(
                  context,
                  label: AppLocalizations.of(context).t('fullBottles'),
                  value: '${allocation.fullBottles}',
                  icon: Icons.local_drink_outlined,
                  color: Colors.green,
                ),
                _buildMiniDetail(
                  context,
                  label: AppLocalizations.of(context).t('inventoryTableEmptyBottlesGeneric'),
                  value: '${allocation.emptyBottles}',
                  icon: Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                _buildMiniDetail(
                  context,
                  label: AppLocalizations.of(context).t('inventoryTableFullBidonsGeneric'),
                  value: '${allocation.fullBidons}',
                  icon: Icons.opacity_outlined,
                  color: Colors.blueAccent,
                ),
                _buildMiniDetail(
                  context,
                  label: AppLocalizations.of(context).t('inventoryTableOpenBidons'),
                  value: '${allocation.openBidons}',
                  icon: Icons.hourglass_empty,
                  color: Colors.teal,
                ),
                _buildMiniDetail(
                  context,
                  label: AppLocalizations.of(context).t('inventoryTableEmptyBidons'),
                  value: '${allocation.emptyBidons}',
                  icon: Icons.recycling_outlined,
                  color: Colors.grey,
                ),
              ],
            ),

            if (allocation.openBidons > 0) ...[
              const SizedBox(height: 16),
              // Open Bidon Volume Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context).t('openBidonVolumeLeft')}:',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${allocation.openBidonVolumeLeftMl.toInt()} / ${allocation.product.bidonVolumeMl} ml (${openBidonPercentage.toInt()}%)',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: openBidonPercentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniDetail(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHECKOUT STOCK DIALOG
  // ============================================================
  Future<void> _showCheckoutDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.read(productsProvider);
    final hotelId = ref.read(selectedHotelIdProvider);
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    if (currentUser == null) return;

    final products = productsAsync.valueOrNull ?? [];
    if (products.isEmpty) {
      PremiumSnackbar.show(
        context,
        l10n.t('errorGeneric'),
        isError: true,
      );
      return;
    }

    Product selectedProduct = products.first;
    int fullBottles = 0;
    int fullBidons = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.add_shopping_cart, color: Color(0xFFF2A900)),
                  const SizedBox(width: 10),
                  Text(l10n.t('checkoutStock')),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Selection
                    DropdownButtonFormField<Product>(
                      value: selectedProduct,
                      decoration: InputDecoration(
                        labelText: l10n.t('inventoryTableProduct'),
                        border: const OutlineInputBorder(),
                      ),
                      items: products.map((p) {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        final pName = isAr
                            ? p.nameAr
                            : (Localizations.localeOf(context).languageCode == 'fr'
                                ? p.nameFr
                                : p.nameEn);
                        return DropdownMenuItem<Product>(
                          value: p,
                          child: Text(pName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedProduct = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Full Bottles Counter
                    _buildCounterRow(
                      context,
                      title: l10n.t('fullBottles'),
                      value: fullBottles,
                      onChanged: (val) => setDialogState(() => fullBottles = val),
                    ),
                    const SizedBox(height: 16),

                    // Full Bidons Counter
                    _buildCounterRow(
                      context,
                      title: l10n.t('inventoryTableFullBidonsGeneric'),
                      value: fullBidons,
                      onChanged: (val) => setDialogState(() => fullBidons = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2A900),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (fullBottles == 0 && fullBidons == 0)
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          try {
                            await ref.read(repositoryProvider).checkoutHousekeeperStock(
                                  housekeeperId: currentUser.id,
                                  productId: selectedProduct.id,
                                  fullBottles: fullBottles,
                                  fullBidons: fullBidons,
                                );
                            ref.invalidate(housekeeperAllocationsProvider);
                            if (context.mounted) {
                              PremiumSnackbar.show(
                                context,
                                l10n.t('housekeeperStockCheckedOut'),
                                icon: Icons.check_circle_outline,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              PremiumSnackbar.show(
                                context,
                                l10n.t('errorGeneric'),
                                isError: true,
                              );
                            }
                          }
                        },
                  child: Text(l10n.t('btnConfirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // RETURN STOCK DIALOG
  // ============================================================
  Future<void> _showReturnDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final allocationsAsync = ref.read(housekeeperAllocationsProvider);
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    if (currentUser == null) return;

    final allocations = allocationsAsync.valueOrNull ?? [];
    if (allocations.isEmpty) {
      PremiumSnackbar.show(
        context,
        l10n.t('noAllocations'),
        isError: true,
      );
      return;
    }

    HousekeeperAllocation selectedAllocation = allocations.first;
    int fullBottles = selectedAllocation.fullBottles;
    int emptyBottles = selectedAllocation.emptyBottles;
    int fullBidons = selectedAllocation.fullBidons;
    int openBidons = selectedAllocation.openBidons;
    int emptyBidons = selectedAllocation.emptyBidons;
    double openBidonVolume = selectedAllocation.openBidonVolumeLeftMl;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final maxVolume = selectedAllocation.product.bidonVolumeMl.toDouble();
            
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.assignment_return, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Text(l10n.t('returnStock')),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cart Item Selection
                      DropdownButtonFormField<HousekeeperAllocation>(
                        value: selectedAllocation,
                        decoration: InputDecoration(
                          labelText: l10n.t('inventoryTableProduct'),
                          border: const OutlineInputBorder(),
                        ),
                        items: allocations.map((a) {
                          final isAr = Localizations.localeOf(context).languageCode == 'ar';
                          final pName = isAr
                              ? a.product.nameAr
                              : (Localizations.localeOf(context).languageCode == 'fr'
                                  ? a.product.nameFr
                                  : a.product.nameEn);
                          return DropdownMenuItem<HousekeeperAllocation>(
                            value: a,
                            child: Text(pName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedAllocation = val;
                              fullBottles = val.fullBottles;
                              emptyBottles = val.emptyBottles;
                              fullBidons = val.fullBidons;
                              openBidons = val.openBidons;
                              emptyBidons = val.emptyBidons;
                              openBidonVolume = val.openBidonVolumeLeftMl;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Full Bottles Slider/Counter
                      _buildCounterRow(
                        context,
                        title: l10n.t('fullBottles'),
                        value: fullBottles,
                        max: selectedAllocation.fullBottles,
                        onChanged: (val) => setDialogState(() => fullBottles = val),
                      ),
                      const SizedBox(height: 16),

                      // Empty Bottles Counter
                      _buildCounterRow(
                        context,
                        title: l10n.t('inventoryTableEmptyBottlesGeneric'),
                        value: emptyBottles,
                        max: selectedAllocation.emptyBottles,
                        onChanged: (val) => setDialogState(() => emptyBottles = val),
                      ),
                      const SizedBox(height: 16),

                      // Full Bidons Counter
                      _buildCounterRow(
                        context,
                        title: l10n.t('inventoryTableFullBidonsGeneric'),
                        value: fullBidons,
                        max: selectedAllocation.fullBidons,
                        onChanged: (val) => setDialogState(() => fullBidons = val),
                      ),
                      const SizedBox(height: 16),

                      // Open Bidons Counter
                      _buildCounterRow(
                        context,
                        title: l10n.t('inventoryTableOpenBidons'),
                        value: openBidons,
                        max: selectedAllocation.openBidons,
                        onChanged: (val) {
                          setDialogState(() {
                            openBidons = val;
                            if (openBidons == 0) {
                              openBidonVolume = 0.0;
                            } else if (openBidonVolume == 0.0) {
                              openBidonVolume = maxVolume;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Empty Bidons Counter
                      _buildCounterRow(
                        context,
                        title: l10n.t('inventoryTableEmptyBidons'),
                        value: emptyBidons,
                        max: selectedAllocation.emptyBidons,
                        onChanged: (val) => setDialogState(() => emptyBidons = val),
                      ),

                      if (openBidons > 0) ...[
                        const SizedBox(height: 20),
                        // Slider for Open Bidon Volume
                        Text(
                          '${l10n.t('openBidonVolumeLeft')} (${openBidonVolume.toInt()} ml):',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: openBidonVolume.clamp(0.0, maxVolume),
                          min: 0.0,
                          max: maxVolume,
                          divisions: (maxVolume / 50).round(),
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            setDialogState(() => openBidonVolume = val);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (fullBottles == 0 &&
                          emptyBottles == 0 &&
                          fullBidons == 0 &&
                          openBidons == 0 &&
                          emptyBidons == 0)
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          try {
                            await ref.read(repositoryProvider).returnHousekeeperStock(
                                  housekeeperId: currentUser.id,
                                  productId: selectedAllocation.product.id,
                                  fullBottles: fullBottles,
                                  emptyBottles: emptyBottles,
                                  fullBidons: fullBidons,
                                  openBidons: openBidons,
                                  emptyBidons: emptyBidons,
                                  openBidonVolumeLeftMl: openBidonVolume,
                                );
                            ref.invalidate(housekeeperAllocationsProvider);
                            ref.invalidate(inventoryProvider);
                            if (context.mounted) {
                              PremiumSnackbar.show(
                                context,
                                l10n.t('housekeeperStockReturned'),
                                icon: Icons.check_circle_outline,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              PremiumSnackbar.show(
                                context,
                                l10n.t('errorGeneric'),
                                isError: true,
                              );
                            }
                          }
                        },
                  child: Text(l10n.t('btnConfirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCounterRow(
    BuildContext context, {
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    int? max,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: theme.textTheme.bodyMedium),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 40),
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
              onPressed: (max == null || value < max) ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
