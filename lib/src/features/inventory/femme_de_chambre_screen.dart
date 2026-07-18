import 'package:flutter/material.dart';
import '../shared/shimmer_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../ui/ivra_icons.dart';
import '../shared/async_value_view.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/empty_state.dart';
import '../shared/premium_snackbar.dart';
import '../shared/premium_confirm_dialog.dart';
import '../shared/premium_loading.dart';
import '../shared/hover_image_tooltip.dart';

class FemmeDeChambreScreen extends ConsumerStatefulWidget {
  const FemmeDeChambreScreen({super.key});

  static const route = '/femme-de-chambre';

  @override
  ConsumerState<FemmeDeChambreScreen> createState() => _FemmeDeChambreScreenState();
}

class _FemmeDeChambreScreenState extends ConsumerState<FemmeDeChambreScreen> {
  var _isUploadingAvatar = false;
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

    final currentUser = ref.watch(currentUserProvider.select((s) => s.valueOrNull));
    if (currentUser == null) {
      return PageScaffold(
        title: l10n.t('housekeepersTitle'),
        child: const Center(
          child: PremiumLoadingWidget(),
        ),
      );
    }
    final isHousekeeper = currentUser.role == UserRole.housekeeper;
    final canManage = currentUser.role != UserRole.hotelStaff && !isHousekeeper;
    final selectedHotelId = ref.watch(selectedHotelIdProvider);

    return PageScaffold(
      title: isHousekeeper ? l10n.t('myBasket') : l10n.t('housekeepersTitle'),
      onRefresh: () async {
        if (isHousekeeper) {
          ref.invalidate(housekeeperAllocationsProvider);
          ref.invalidate(productsProvider);
          await Future.wait([
            ref.read(housekeeperAllocationsProvider.future),
            ref.read(productsProvider.future),
          ]);
        } else {
          ref.invalidate(hotelHousekeepersProvider);
          await ref.read(hotelHousekeepersProvider.future);
        }
      },
      actions: isHousekeeper ? [
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
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _showAllHistoryDialog(context, currentUser.id),
        ),
      ] : [
        if (canManage && selectedHotelId != null)
          MediaQuery.sizeOf(context).width >= 600
              ? FilledButton.icon(
                  onPressed: () => _showInviteHousekeeperDialog(context),
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(l10n.t('inviteHousekeeper')),
                )
              : IconButton(
                  tooltip: l10n.t('inviteHousekeeper'),
                  icon: const Icon(Icons.person_add_outlined),
                  onPressed: () => _showInviteHousekeeperDialog(context),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
      ],
      child: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: isHousekeeper 
          ? _buildHousekeeperView(context, currentUser)
          : _buildManagementView(context, currentUser),
      ),
    );
  }

  Widget _buildHousekeeperView(BuildContext context, UserProfile currentUser) {
    final allocationsAsync = ref.watch(housekeeperAllocationsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AsyncValueView(
      value: allocationsAsync,
      builder: (allocations) {
        if (allocations.isEmpty) {
          return Column(
            children: [
              _buildAvatarHeader(context, currentUser),
              Expanded(
                child: EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: l10n.t('housekeeperCart'),
                  message: l10n.t('noAllocations'),
                  actionLabel: l10n.t('checkoutStock'),
                  onAction: () => _showCheckoutDialog(context),
                ),
              ),
            ],
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
              _buildAvatarHeader(context, currentUser),
              const SizedBox(height: 24),
              
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
                        icon: IvraIcons.fullBottleWithPump,
                        color: const Color(0xFFF2A900),
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.t('inventoryTableEmptyBottlesGeneric'),
                        value: '$totalEmptyBottles',
                        icon: IvraIcons.emptyBottleWithPump,
                        color: Colors.redAccent,
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.t('inventoryTableFullBidonsGeneric'),
                        value: '$totalFullBidons',
                        icon: IvraIcons.fullRefillBottle,
                        color: Colors.blueAccent,
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.t('inventoryTableOpenBidons'),
                        value: '$totalOpenBidons',
                        icon: IvraIcons.refillAction,
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
                  return _buildAllocationCard(context, allocation, currentUser.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarHeader(BuildContext context, UserProfile user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          HoverImageTooltip(
            imageUrl: user.avatarUrl,
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : () => _pickAvatar(user.id),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty && user.avatarUrl!.startsWith('http')) ? NetworkImage(user.avatarUrl!) : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty || !user.avatarUrl!.startsWith('http'))
                        ? Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  if (_isUploadingAvatar)
                  const Positioned.fill(
                    child: CircularProgressIndicator(),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context).t('userRoleHousekeeper'),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementView(BuildContext context, UserProfile currentUser) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFF2A900); // Golden yellow/orange

    final hotels = hotelsAsync.valueOrNull ?? const <Hotel>[];

    // Show a spinner until hotels have loaded at least once.
    if (hotelsAsync is AsyncLoading && hotels.isEmpty) {
      return const Center(child: PremiumLoadingWidget());
    }

    if (hotels.isEmpty) {
      return EmptyState(
        icon: Icons.hotel_outlined,
        title: l10n.t('inventoryNoHotels'),
        message: l10n.t('inventoryAddHotelHint'),
      );
    }

    // Auto-select first hotel for users with no hotel scope (App Admin/Manager)
    if (selectedHotelId == null && hotels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedHotelIdProvider.notifier).state = hotels.first.id;
        }
      });
    }

    final userHotelId = currentUser.hotelId;
    final userIsHotelScoped =
        userHotelId != null && hotels.any((hotel) => hotel.id == userHotelId);
    final isScoped = userIsHotelScoped || hotels.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Control panel with hotel selection dropdown — always visible
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(Icons.business_outlined, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: isScoped
                      ? Text(
                          hotels
                              .firstWhere(
                                (h) => h.id == (selectedHotelId ?? userHotelId ?? hotels.first.id),
                                orElse: () => hotels.first,
                              )
                              .name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedHotelId != null &&
                                    hotels.any((h) => h.id == selectedHotelId)
                                ? selectedHotelId
                                : null,
                            hint: Text(l10n.t('roomsSelectHotelFirst')),
                            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                            items: [
                              for (final hotel in hotels)
                                DropdownMenuItem(
                                  value: hotel.id,
                                  child: Text(
                                    hotel.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(selectedHotelIdProvider.notifier).state = val;
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // Content section
        if (selectedHotelId == null)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: PremiumLoadingWidget(),
            ),
          )
        else
          _buildHousekeepersList(context, currentUser),
      ],
    );
  }

  /// Renders the housekeepers list for the currently selected hotel.
  /// Separated from the hotel picker so that the dropdown stays visible
  /// while the list reloads.
  Widget _buildHousekeepersList(BuildContext context, UserProfile currentUser) {
    final housekeepersAsync = ref.watch(hotelHousekeepersProvider);
    final l10n = AppLocalizations.of(context);

    // Use .when but keep previous data visible during refresh to avoid flicker
    return housekeepersAsync.when(
      skipLoadingOnRefresh: true,
      data: (housekeepers) {
        if (housekeepers.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l10n.t('housekeepersTitle'),
            message: l10n.t('noHousekeepers'),
            actionLabel: currentUser.role != UserRole.hotelStaff
                ? l10n.t('inviteHousekeeper')
                : null,
            onAction: currentUser.role != UserRole.hotelStaff
                ? () => _showInviteHousekeeperDialog(context)
                : null,
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: housekeepers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final hk = housekeepers[index];
            return _buildHousekeeperExpandableCard(context, hk, currentUser);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: PremiumLoadingWidget()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            error.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Future<List<HousekeeperAllocation>> _getActiveAllocations(
    String housekeeperId,
  ) async {
    final allocations = await ref
        .read(repositoryProvider)
        .fetchHousekeeperAllocations(housekeeperId: housekeeperId);
    return allocations
        .where((a) =>
            a.fullBottles > 0 ||
            a.emptyBottles > 0 ||
            a.fullBidons > 0 ||
            a.openBidons > 0 ||
            a.emptyBidons > 0 ||
            a.openBidonVolumeLeftMl > 0)
        .toList();
  }

  Future<void> _returnAllStock(
    String housekeeperId,
    List<HousekeeperAllocation> activeAllocations,
  ) async {
    final repo = ref.read(repositoryProvider);
    for (final alloc in activeAllocations) {
      await repo.returnHousekeeperStock(
        housekeeperId: housekeeperId,
        productId: alloc.product.id,
        fullBottles: alloc.fullBottles,
        emptyBottles: alloc.emptyBottles,
        fullBidons: alloc.fullBidons,
        openBidons: alloc.openBidons,
        emptyBidons: alloc.emptyBidons,
        openBidonVolumeLeftMl: alloc.openBidonVolumeLeftMl,
      );
    }
  }

  Widget _buildHousekeeperExpandableCard(BuildContext context, UserProfile hk, UserProfile currentUser) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canManage = currentUser.role != UserRole.hotelStaff;

    final isWideScreen = MediaQuery.sizeOf(context).width >= 600;

    return GlassCard(
      child: ExpansionTile(
        leading: HoverImageTooltip(
          imageUrl: hk.avatarUrl,
          child: GestureDetector(
            onTap: canManage ? () => _pickAvatar(hk.id) : null,
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: (hk.avatarUrl != null && hk.avatarUrl!.isNotEmpty && hk.avatarUrl!.startsWith('http')) ? NetworkImage(hk.avatarUrl!) : null,
                  child: (hk.avatarUrl == null || hk.avatarUrl!.isEmpty || !hk.avatarUrl!.startsWith('http'))
                      ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                      : null,
                ),
                if (canManage)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 10,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
        title: Text(
          hk.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hk.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Consumer(
              builder: (context, ref, _) {
                final basketAsync = ref.watch(housekeeperBasketProvider(hk.id));
                return basketAsync.when(
                  loading: () => Text(AppLocalizations.of(context)!.t("inventoryHkLoading"), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  error: (_, __) => const SizedBox(),
                  data: (basket) {
                    if (basket.isEmpty) return const SizedBox();
                    final items = basket.map((a) {
                      final total = a.fullBottles + a.emptyBottles + a.fullBidons + a.openBidons;
                      final lang = Localizations.localeOf(context).languageCode;
                      return '${a.product.label(lang)} ($total)';
                    }).join(', ');
                    return Text(
                      items,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                );
              },
            ),
          ],
        ),
        trailing: isWideScreen
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: l10n.t('allHistory'),
                    onPressed: () => _showAllHistoryDialog(context, hk.id),
                  ),
                  if (canManage)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'toggle_status') {
                          final isActive = !hk.isActive;
                          
                          if (!isActive) {
                            final activeAllocations = await _getActiveAllocations(hk.id);
                            if (activeAllocations.isNotEmpty && context.mounted) {
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n.t('hkDeactivateWithStockTitle')),
                                  content: Text(l10n.t('hkDeactivateWithStockMessage')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop('cancel'),
                                      child: Text(l10n.t('btnCancel')),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop('deactivate'),
                                      child: Text(l10n.t('btnJustDeactivate')),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                        foregroundColor: Theme.of(context).colorScheme.onError,
                                      ),
                                      onPressed: () => Navigator.of(context).pop('return'),
                                      child: Text(l10n.t('btnReturnAndDeactivate')),
                                    ),
                                  ],
                                ),
                              );

                              if (result == null || result == 'cancel') return;
                              if (result == 'return') {
                                await _returnAllStock(hk.id, activeAllocations);
                              }
                            }
                          }

                          await ref.read(repositoryProvider).setTeamMemberActive(userId: hk.id, isActive: isActive);
                          ref.invalidate(hotelHousekeepersProvider);
                        } else if (value == 'delete') {
                          List<HousekeeperAllocation> activeAllocations = await _getActiveAllocations(hk.id);
                          String messageKey = activeAllocations.isNotEmpty ? 'hkDeleteWithStockMessage' : 'confirmDeleteUser';
                          
                          if (!context.mounted) return;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => PremiumConfirmDialog(
                              title: l10n.t('confirmAction'),
                              message: l10n.tParams(messageKey, {'userName': hk.fullName}),
                              confirmLabel: l10n.t('deleteGeneric'),
                              isDestructive: true,
                            ),
                          );
                          if (confirm == true) {
                            if (activeAllocations.isNotEmpty) {
                              await _returnAllStock(hk.id, activeAllocations);
                            }
                            await ref.read(repositoryProvider).deleteUser(hk.id);
                            ref.invalidate(hotelHousekeepersProvider);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Text(hk.isActive ? l10n.t('teamDeactivate') : l10n.t('teamReactivate')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.t('deleteGeneric'), style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              )
            : (canManage
                ? PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'history') {
                        _showAllHistoryDialog(context, hk.id);
                      } else if (value == 'toggle_status') {
                        final isActive = !hk.isActive;
                        
                        if (!isActive) {
                          final activeAllocations = await _getActiveAllocations(hk.id);
                          if (activeAllocations.isNotEmpty && context.mounted) {
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(l10n.t('hkDeactivateWithStockTitle')),
                                content: Text(l10n.t('hkDeactivateWithStockMessage')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop('cancel'),
                                    child: Text(l10n.t('btnCancel')),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop('deactivate'),
                                    child: Text(l10n.t('btnJustDeactivate')),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      foregroundColor: Theme.of(context).colorScheme.onError,
                                    ),
                                    onPressed: () => Navigator.of(context).pop('return'),
                                    child: Text(l10n.t('btnReturnAndDeactivate')),
                                  ),
                                ],
                              ),
                            );

                            if (result == null || result == 'cancel') return;
                            if (result == 'return') {
                              await _returnAllStock(hk.id, activeAllocations);
                            }
                          }
                        }

                        await ref.read(repositoryProvider).setTeamMemberActive(userId: hk.id, isActive: isActive);
                        ref.invalidate(hotelHousekeepersProvider);
                      } else if (value == 'delete') {
                        List<HousekeeperAllocation> activeAllocations = await _getActiveAllocations(hk.id);
                        String messageKey = activeAllocations.isNotEmpty ? 'hkDeleteWithStockMessage' : 'confirmDeleteUser';
                        
                        if (!context.mounted) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => PremiumConfirmDialog(
                            title: l10n.t('confirmAction'),
                            message: l10n.tParams(messageKey, {'userName': hk.fullName}),
                            confirmLabel: l10n.t('deleteGeneric'),
                            isDestructive: true,
                          ),
                        );
                        if (confirm == true) {
                          if (activeAllocations.isNotEmpty) {
                            await _returnAllStock(hk.id, activeAllocations);
                          }
                          await ref.read(repositoryProvider).deleteUser(hk.id);
                          ref.invalidate(hotelHousekeepersProvider);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.t('allHistory')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Text(hk.isActive ? l10n.t('teamDeactivate') : l10n.t('teamReactivate')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.t('deleteGeneric'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: l10n.t('allHistory'),
                    onPressed: () => _showAllHistoryDialog(context, hk.id),
                  )),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('basketContent'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final basketAsync = ref.watch(housekeeperBasketProvider(hk.id));
                    return basketAsync.when(
                      loading: () => const Padding(padding: EdgeInsets.all(16.0), child: ShimmerLoading(width: double.infinity, height: 100)),
                      error: (e, _) => Center(child: Text(l10n.tParams('errorWithArgs', {'error': e.toString()}), style: TextStyle(color: theme.colorScheme.error))),
                      data: (basket) {
                        if (basket.isEmpty) {
                          return Text(l10n.t('noAllocations'), style: const TextStyle(fontStyle: FontStyle.italic));
                        }
                        return Column(
                          children: basket.map((a) => _buildAllocationCard(context, a, hk.id)).toList(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(String targetUserId) async {
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
      
      await ref.read(repositoryProvider).updateUserAvatar(
        userId: targetUserId,
        imageBytes: bytes,
        fileExtension: ext,
      );
      
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser?.id == targetUserId) {
        ref.invalidate(realCurrentUserProvider);
        ref.invalidate(currentUserProvider);
      }
      ref.invalidate(hotelHousekeepersProvider);
      ref.invalidate(teamMembersProvider);
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

  Future<void> _showInviteHousekeeperDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.t('inviteHousekeeper')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.t('accountFullName')),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.t('accountEmail')),
                  validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Invalid email' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('btnCancel')),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final hotelId = ref.read(selectedHotelIdProvider);
                    await ref.read(repositoryProvider).inviteTeamMember(
                      email: emailController.text.trim(),
                      role: UserRole.housekeeper.name,
                      hotelId: hotelId,
                      fullName: nameController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      PremiumSnackbar.show(context, 'Invitation sent', icon: Icons.check);
                      ref.invalidate(hotelHousekeepersProvider);
                    }
                  } catch (e) {
                    if (context.mounted) PremiumSnackbar.showError(context, e);
                  }
                }
              },
              child: Text(l10n.t('teamInvite')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAllHistoryDialog(BuildContext context, String housekeeperId) async {
    final l10n = AppLocalizations.of(context);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 8),
              Text(l10n.t('allHistory')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final targetEventsAsync = ref.watch(housekeeperHistoryProvider(housekeeperId));
                return targetEventsAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(16.0), child: ShimmerLoading(width: double.infinity, height: 100)),
                  error: (error, stack) => Center(child: Text(l10n.tParams('errorWithArgs', {'error': error.toString()}), style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  data: (targetEvents) {
                    if (targetEvents.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(l10n.t('noHistory'), textAlign: TextAlign.center),
                      );
                    }
                    
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: targetEvents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final event = targetEvents[index];
                        final dateFormat = DateFormat('MMM d, yyyy HH:mm');
                        final pName = Localizations.localeOf(context).languageCode == 'ar'
                            ? event.product.nameAr
                            : (Localizations.localeOf(context).languageCode == 'fr'
                                ? event.product.nameFr
                                : event.product.nameEn);

                        final meta = _stockEventMeta(l10n, event);
                        final displayLabel = event.roomNumber != null && event.roomNumber!.isNotEmpty
                            ? (event.eventType == HousekeeperStockEventType.roomPlacement
                                ? '${meta.label} ${event.roomNumber}'
                                : (event.eventType == HousekeeperStockEventType.refillUse || event.eventType == HousekeeperStockEventType.replaceUse
                                    ? '${meta.label} (${l10n.t('roomsLabelRoom')} ${event.roomNumber})'
                                    : '${meta.label} — ${event.roomNumber}'))
                            : meta.label;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.tParams('productEventTitle', {'productName': pName, 'eventLabel': displayLabel})),
                          subtitle: Text(
                            event.roomNumber != null && event.roomNumber!.isNotEmpty
                                ? '${dateFormat.format(event.createdAt.toLocal())} • ${l10n.t('roomsLabelRoom')} ${event.roomNumber}'
                                : dateFormat.format(event.createdAt.toLocal()),
                          ),
                          trailing: Text(
                            _stockEventDeltas(l10n, event),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    );
                  }
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('btnClose')),
            ),
          ],
        );
      },
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

  Widget _buildAllocationCard(BuildContext context, HousekeeperAllocation allocation, String housekeeperId) {
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
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobileCard = constraints.maxWidth < 450;
                if (isMobileCard) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HoverImageTooltip(
                            imageUrl: allocation.product.imageUrl,
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFFF2A900).withOpacity(0.1),
                              backgroundImage: allocation.product.imageUrl != null && allocation.product.imageUrl!.isNotEmpty 
                                  ? NetworkImage(allocation.product.imageUrl!) 
                                  : null,
                              child: allocation.product.imageUrl == null || allocation.product.imageUrl!.isEmpty
                                  ? const Icon(Icons.inventory_2_outlined, color: Color(0xFFF2A900))
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            tooltip: AppLocalizations.of(context).t('housekeeperStockHistory'),
                            icon: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                            onPressed: () => _showProductHistoryDialog(context, allocation.product, housekeeperId),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 52.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SKU: ${allocation.product.sku}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      HoverImageTooltip(
                        imageUrl: allocation.product.imageUrl,
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFF2A900).withOpacity(0.1),
                          backgroundImage: allocation.product.imageUrl != null && allocation.product.imageUrl!.isNotEmpty 
                              ? NetworkImage(allocation.product.imageUrl!) 
                              : null,
                          child: allocation.product.imageUrl == null || allocation.product.imageUrl!.isEmpty
                              ? const Icon(Icons.inventory_2_outlined, color: Color(0xFFF2A900))
                              : null,
                        ),
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
                      IconButton(
                        tooltip: AppLocalizations.of(context).t('housekeeperStockHistory'),
                        icon: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                        onPressed: () => _showProductHistoryDialog(context, allocation.product, housekeeperId),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
                }
              },
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
                  icon: allocation.product.bottleType == BottleType.withPump
                      ? IvraIcons.fullBottleWithPump
                      : IvraIcons.fullBottleWithoutPump,
                  color: Colors.green,
                ),
                _buildMiniDetail(
                  context,
                  label: AppLocalizations.of(context).t('inventoryTableEmptyBottlesGeneric'),
                  value: '${allocation.emptyBottles}',
                  icon: allocation.product.bottleType == BottleType.withPump
                      ? IvraIcons.emptyBottleWithPump
                      : IvraIcons.emptyBottleWithoutPump,
                  color: Colors.redAccent,
                ),
                if (allocation.product.isRefillable) ...[
                  _buildMiniDetail(
                    context,
                    label: AppLocalizations.of(context).t('inventoryTableFullBidonsGeneric'),
                    value: '${allocation.fullBidons}',
                    icon: IvraIcons.fullRefillBottle,
                    color: Colors.blueAccent,
                  ),
                  _buildMiniDetail(
                    context,
                    label: AppLocalizations.of(context).t('inventoryTableOpenBidons'),
                    value: '${allocation.openBidons}',
                    icon: IvraIcons.refillAction,
                    color: Colors.teal,
                  ),
                  _buildMiniDetail(
                    context,
                    label: AppLocalizations.of(context).t('inventoryTableEmptyBidons'),
                    value: '${allocation.emptyBidons}',
                    icon: IvraIcons.emptyRefillBottle,
                    color: Colors.grey,
                  ),
                ],
              ],
            ),

            if (allocation.product.isRefillable && allocation.openBidons > 0) ...[
              const SizedBox(height: 16),
              // Open Bidon Volume Indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context).t('openBidonVolumeLeft')}:',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final hotelId = ref.read(selectedHotelIdProvider);
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    if (currentUser == null) return;

    final List<Product> products;
    final List<InventoryItem> inventory;

    try {
      products = await ref.read(productsProvider.future);
      inventory = await ref.read(inventoryProvider.future);
    } catch (e) {
      if (context.mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('errorGeneric'),
          isError: true,
        );
      }
      return;
    }

    if (products.isEmpty) {
      if (context.mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('errorGeneric'),
          isError: true,
        );
      }
      return;
    }

    Product selectedProduct = products.first;
    int fullBottles = 0;
    int fullBidons = 0;

    // Hotel inventory is used to show available stock and clamp quantities
    // so the housekeeper can't request more than the hotel actually has.
    InventoryItem? hotelStockFor(Product product) {
      for (final item in inventory) {
        if (item.product.id == product.id && (hotelId == null || item.hotelId == hotelId)) {
          return item;
        }
      }
      return null;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final hotelStock = hotelStockFor(selectedProduct);
            final maxBottles = hotelStock?.fullBottles ?? 0;
            final maxBidons = hotelStock?.fullBidons ?? 0;

            final String stockText;
            if (selectedProduct.isRefillable) {
              stockText = l10n.tParams('housekeeperHotelStockAvailable', {
                'bottles': maxBottles.toString(),
                'bidons': maxBidons.toString(),
              });
            } else {
              final raw = l10n.tParams('housekeeperHotelStockAvailable', {
                'bottles': maxBottles.toString(),
                'bidons': '',
              });
              final parts = raw.contains('،') ? raw.split('،') : raw.split(',');
              stockText = parts.isNotEmpty ? parts[0].trim() : raw;
            }

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
                          setDialogState(() {
                            selectedProduct = val;
                            // Re-clamp quantities to the new product's hotel stock.
                            final stock = hotelStockFor(val);
                            fullBottles = fullBottles.clamp(0, stock?.fullBottles ?? 0);
                            fullBidons = fullBidons.clamp(0, stock?.fullBidons ?? 0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Available hotel stock for the selected product
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stockText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Bottles Counter (clamped to hotel stock)
                    _buildCounterRow(
                      context,
                      title: l10n.t('fullBottles'),
                      value: fullBottles,
                      max: maxBottles,
                      onChanged: (val) => setDialogState(() => fullBottles = val),
                    ),

                    if (selectedProduct.isRefillable) ...[
                      const SizedBox(height: 16),
                      // Full Bidons Counter (clamped to hotel stock)
                      _buildCounterRow(
                        context,
                        title: l10n.t('inventoryTableFullBidonsGeneric'),
                        value: fullBidons,
                        max: maxBidons,
                        onChanged: (val) => setDialogState(() => fullBidons = val),
                      ),
                    ],
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
                            ref.invalidate(inventoryProvider);
                            ref.invalidate(housekeeperStockEventsProvider);
                            ref.invalidate(housekeeperHistoryProvider);
                            ref.invalidate(housekeeperAllStockEventsProvider);
                            if (context.mounted) {
                              PremiumSnackbar.show(
                                context,
                                l10n.t('housekeeperStockCheckedOut'),
                                icon: Icons.check_circle_outline,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              PremiumSnackbar.showError(context, e);
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
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    if (currentUser == null) return;

    final List<HousekeeperAllocation> allocations;

    try {
      allocations = await ref.read(housekeeperAllocationsProvider.future);
    } catch (e) {
      if (context.mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('errorGeneric'),
          isError: true,
        );
      }
      return;
    }

    if (allocations.isEmpty) {
      if (context.mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('noAllocations'),
          isError: true,
        );
      }
      return;
    }

    HousekeeperAllocation selectedAllocation = allocations.first;
    int fullBottles = selectedAllocation.fullBottles;
    int emptyBottles = selectedAllocation.emptyBottles;
    int fullBidons = selectedAllocation.fullBidons;
    int openBidons = selectedAllocation.openBidons;
    int emptyBidons = selectedAllocation.emptyBidons;
    double openBidonVolume = selectedAllocation.openBidonVolumeLeftMl;

    if (!context.mounted) return;

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

                      if (selectedAllocation.product.isRefillable) ...[
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
                            ref.invalidate(housekeeperStockEventsProvider);
                            ref.invalidate(housekeeperHistoryProvider);
                            ref.invalidate(housekeeperAllStockEventsProvider);
                            if (context.mounted) {
                              PremiumSnackbar.show(
                                context,
                                l10n.t('housekeeperStockReturned'),
                                icon: Icons.check_circle_outline,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              PremiumSnackbar.showError(context, e);
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

  // ============================================================
  // PER-PRODUCT STOCK MOVEMENT HISTORY DIALOG
  // ============================================================
  Future<void> _showProductHistoryDialog(BuildContext context, Product product, String housekeeperId) async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final productName = product.label(language);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.history_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.t('housekeeperStockHistory')} — $productName',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 420,
            child: Consumer(
              builder: (context, ref, _) {
                final eventsAsync = ref.watch(housekeeperStockEventsProvider((housekeeperId: housekeeperId, productId: product.id)));
                return eventsAsync.when(
                  loading: () => Padding(padding: EdgeInsets.all(16.0), child: ShimmerLoading(width: double.infinity, height: 100)),
                  error: (e, _) => Center(
                    child: Text(e.toString(), style: theme.textTheme.bodySmall),
                  ),
                  data: (events) {
                    if (events.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 48, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('housekeeperStockHistoryEmpty'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final meta = _stockEventMeta(l10n, event);
                        final deltas = _stockEventDeltas(l10n, event);
                        final dateStr =
                            DateFormat('yyyy-MM-dd HH:mm').format(event.createdAt.toLocal());
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: meta.color.withOpacity(0.12),
                            child: Icon(meta.icon, size: 18, color: meta.color),
                          ),
                          title: Text(
                            event.roomNumber != null
                                ? '${meta.label} — ${l10n.t('roomsLabelRoom')} ${event.roomNumber}'
                                : meta.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (deltas.isNotEmpty)
                                Text(deltas, style: theme.textTheme.bodySmall),
                              Text(
                                dateStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.t('btnOk')),
            ),
          ],
        );
      },
    );
  }

  ({IconData icon, Color color, String label}) _stockEventMeta(
    AppLocalizations l10n,
    HousekeeperStockEvent event,
  ) {
    return switch (event.eventType) {
      HousekeeperStockEventType.checkout => (
          icon: Icons.add_shopping_cart_rounded,
          color: const Color(0xFFF2A900),
          label: l10n.t('stockEventCheckout'),
        ),
      HousekeeperStockEventType.returned => (
          icon: Icons.assignment_return_outlined,
          color: Colors.blueAccent,
          label: l10n.t('stockEventReturn'),
        ),
      HousekeeperStockEventType.roomPlacement => (
          icon: Icons.meeting_room_outlined,
          color: Colors.green,
          label: l10n.t('stockEventRoomPlacement'),
        ),
      HousekeeperStockEventType.refillUse => (
          icon: Icons.water_drop_outlined,
          color: Colors.teal,
          label: l10n.t('stockEventRefillUse'),
        ),
      HousekeeperStockEventType.replaceUse => (
          icon: Icons.swap_horiz_rounded,
          color: Colors.deepOrange,
          label: l10n.t('stockEventReplaceUse'),
        ),
    };
  }

  String _stockEventDeltas(AppLocalizations l10n, HousekeeperStockEvent event) {
    String signed(int v) => v > 0 ? '+$v' : '$v';
    final parts = <String>[
      if (event.fullBottlesDelta != 0)
        '${l10n.t('fullBottles')}: ${signed(event.fullBottlesDelta)}',
      if (event.emptyBottlesDelta != 0)
        '${l10n.t('inventoryTableEmptyBottlesGeneric')}: ${signed(event.emptyBottlesDelta)}',
      if (event.fullBidonsDelta != 0)
        '${l10n.t('inventoryTableFullBidonsGeneric')}: ${signed(event.fullBidonsDelta)}',
      if (event.openBidonsDelta != 0)
        '${l10n.t('inventoryTableOpenBidons')}: ${signed(event.openBidonsDelta)}',
      if (event.emptyBidonsDelta != 0)
        '${l10n.t('inventoryTableEmptyBidons')}: ${signed(event.emptyBidonsDelta)}',
      if (event.volumeDeltaMl != 0)
        '${l10n.t('openBidonVolumeLeft')}: ${event.volumeDeltaMl > 0 ? '+' : ''}${event.volumeDeltaMl.toInt()} ml',
    ];
    return parts.join(' · ');
  }
}
