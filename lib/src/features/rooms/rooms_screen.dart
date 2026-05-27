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

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  static const route = '/rooms';

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'ok', 'refill', 'attention'
  bool _showDetailedView = true; // true = Detailed, false = Compact
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
    final primaryColor = theme.colorScheme.primary;

    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canCreateRoomsFromTemplate = currentUser?.isIvraUser ?? false;

    final hotelsAsync = ref.watch(hotelsProvider);
    final roomProductsAsync = ref.watch(roomProductsProvider);
    final selectedHotelId = ref.watch(selectedHotelIdProvider);

    return PageScaffold(
      title: l10n.t('rooms'),
      onRefresh: () async {
        ref.invalidate(hotelsProvider);
        ref.invalidate(roomProductsProvider);
        await Future.wait([
          ref.read(hotelsProvider.future),
          ref.read(roomProductsProvider.future),
        ]);
      },
      actions: [
        if (canCreateRoomsFromTemplate)
          IconButton(
            tooltip: l10n.t('roomsTooltipCreateTemplate'),
            icon: const Icon(Icons.auto_awesome_motion_outlined),
            onPressed: () => _showRoomTemplateDialog(context, ref),
          ),
      ],
      child: AsyncValueView(
        value: hotelsAsync,
        onRetry: () {
          ref.invalidate(hotelsProvider);
          ref.invalidate(roomProductsProvider);
        },
        loadingWidget: const PremiumLoadingWidget(),
        builder: (hotels) {
          if (hotels.isEmpty) {
            return EmptyState(
              icon: Icons.hotel_outlined,
              title: l10n.t('inventoryNoHotels'),
              message: l10n.t('inventoryAddHotelHint'),
            );
          }

          // Auto-select the hotel when there is no choice to make:
          //  - hotel-scoped users (staff/manager) always work in their own hotel
          //  - app-wide users (admin/manager) auto-select when only one hotel exists
          if (selectedHotelId == null) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlPanel(hotels, l10n, theme, primaryColor, currentUser,
                  selectedHotelId),
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
              else
                AsyncValueView(
                  value: roomProductsAsync,
                  onRetry: () => ref.invalidate(roomProductsProvider),
                  loadingWidget: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CardShimmer(),
                    ),
                  ),
                  builder: (items) {
                    // 1. Filter by selected hotel
                    final hotelItems = items
                        .where((item) => item.hotelId == selectedHotelId)
                        .toList();

                    if (hotelItems.isEmpty) {
                      return EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: l10n.t('roomsNoRoomsFound'),
                        message: canCreateRoomsFromTemplate
                            ? l10n.t('roomsEmptyHotelWithTemplate')
                            : l10n.t('roomsEmptyHotelNoTemplate'),
                      );
                    }

                    // Group items by roomId first to calculate overall status & filter by search
                    final Map<String, List<RoomProduct>> groupedRooms = {};
                    for (final item in hotelItems) {
                      groupedRooms.putIfAbsent(item.roomId, () => []).add(item);
                    }

                    // Apply search query and status filter at room level
                    final filteredRoomEntries =
                        groupedRooms.entries.where((entry) {
                      final firstItem = entry.value.first;

                      // Search filter
                      if (_searchQuery.isNotEmpty) {
                        if (!firstItem.roomNumber
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) {
                          return false;
                        }
                      }

                      // Status filter
                      if (_statusFilter != 'all') {
                        final overallStatus =
                            _getRoomOverallStatus(entry.value);
                        if (_statusFilter == 'ok' &&
                            overallStatus != _RoomOverallStatus.allOk) {
                          return false;
                        }
                        if (_statusFilter == 'refill' &&
                            overallStatus != _RoomOverallStatus.refillNeeded) {
                          return false;
                        }
                        if (_statusFilter == 'attention' &&
                            overallStatus !=
                                _RoomOverallStatus.attentionRequired) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                    if (filteredRoomEntries.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_outlined,
                        title: l10n.t('roomsNoRoomsFound'),
                        message: l10n.t('roomsSearchEmptyHint'),
                      );
                    }

                    // Group rooms by floor
                    final Map<int, List<MapEntry<String, List<RoomProduct>>>>
                        roomsByFloor = {};
                    for (final entry in filteredRoomEntries) {
                      final floor = entry.value.first.floorNumber;
                      roomsByFloor.putIfAbsent(floor, () => []).add(entry);
                    }

                    final sortedFloors = roomsByFloor.keys.toList()..sort();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final floor in sortedFloors) ...[
                          _buildFloorHeader(floor, l10n, theme, primaryColor),
                          const SizedBox(height: 12),
                          if (_showDetailedView)
                            // Detailed View: Vertical list of full detailed RoomCards
                            Column(
                              children: [
                                for (final entry
                                    in _sortRoomsInFloor(roomsByFloor[floor]!))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _RoomCard(
                                      roomId: entry.key,
                                      roomProducts: entry.value,
                                    ),
                                  ),
                              ],
                            )
                          else
                            // Compact View: Wrap grid of CompactRoomTiles
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final entry in _sortRoomsInFloor(
                                      roomsByFloor[floor]!))
                                    _CompactRoomTile(
                                      roomNumber: entry.value.first.roomNumber,
                                      roomProducts: entry.value,
                                      onTap: () => _showRoomDetailsDialog(
                                        context,
                                        entry.value.first.roomNumber,
                                        entry.value,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<MapEntry<String, List<RoomProduct>>> _sortRoomsInFloor(
    List<MapEntry<String, List<RoomProduct>>> floorRooms,
  ) {
    return floorRooms.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.value.first.roomNumber) ?? 0;
        final bNum = int.tryParse(b.value.first.roomNumber) ?? 0;
        if (aNum != 0 && bNum != 0) {
          return aNum.compareTo(bNum);
        }
        return a.value.first.roomNumber.compareTo(b.value.first.roomNumber);
      });
  }

  _RoomOverallStatus _getRoomOverallStatus(List<RoomProduct> products) {
    final hasCritical = products.any((item) =>
        item.status == BottleStatus.refillLimitReached ||
        item.status == BottleStatus.tooOld ||
        item.status == BottleStatus.needsReplacement ||
        item.status == BottleStatus.damaged ||
        item.status == BottleStatus.lost);
    if (hasCritical) return _RoomOverallStatus.attentionRequired;

    final hasWarning =
        products.any((item) => item.status == BottleStatus.needsRefill);
    if (hasWarning) return _RoomOverallStatus.refillNeeded;

    return _RoomOverallStatus.allOk;
  }

  Widget _buildFloorHeader(
      int floor, AppLocalizations l10n, ThemeData theme, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.layers_outlined, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            '${l10n.t('roomsLabelFloor')} $floor',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ],
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
    // Lock the hotel selector when the user has nothing to choose between:
    // hotel-scoped users (staff/manager with hotelId) always work in their own
    // hotel, and app-wide users with a single visible hotel have no choice to
    // make either.
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
                            .firstWhere((h) => h.id == selectedHotelId,
                                orElse: () => hotels.first)
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
          // Search & View Mode Switcher
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final searchField = SizedBox(
                width: isWide ? 300 : double.infinity,
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

              final viewToggle = SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.t('roomsViewDetailed')),
                    icon: const Icon(Icons.view_agenda_outlined),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.t('roomsViewCompact')),
                    icon: const Icon(Icons.grid_view_outlined),
                  ),
                ],
                selected: {_showDetailedView},
                onSelectionChanged: (val) {
                  setState(() {
                    _showDetailedView = val.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: primaryColor.withValues(alpha: 0.2),
                  selectedForegroundColor: primaryColor,
                  visualDensity: VisualDensity.compact,
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    searchField,
                    const Spacer(),
                    viewToggle,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  viewToggle,
                ],
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
                  avatar: const Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.green),
                  label: Text(l10n.t('roomsStatusAllOk')),
                  selected: _statusFilter == 'ok',
                  selectedColor: Colors.green.withValues(alpha: 0.15),
                  checkmarkColor: Colors.green,
                  labelStyle: TextStyle(
                    color: _statusFilter == 'ok'
                        ? Colors.green.shade800
                        : theme.colorScheme.onSurface,
                    fontWeight: _statusFilter == 'ok'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _statusFilter = 'ok');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(Icons.hourglass_empty_rounded,
                      size: 16, color: Colors.orange.shade700),
                  label: Text(l10n.t('roomsStatusRefillNeeded')),
                  selected: _statusFilter == 'refill',
                  selectedColor: Colors.orange.withValues(alpha: 0.15),
                  checkmarkColor: Colors.orange.shade700,
                  labelStyle: TextStyle(
                    color: _statusFilter == 'refill'
                        ? Colors.orange.shade800
                        : theme.colorScheme.onSurface,
                    fontWeight: _statusFilter == 'refill'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _statusFilter = 'refill');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                  label: Text(l10n.t('roomsStatusAttentionRequired')),
                  selected: _statusFilter == 'attention',
                  selectedColor:
                      theme.colorScheme.error.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.error,
                  labelStyle: TextStyle(
                    color: _statusFilter == 'attention'
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                    fontWeight: _statusFilter == 'attention'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _statusFilter = 'attention');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetailsDialog(
    BuildContext context,
    String roomNumber,
    List<RoomProduct> roomProducts,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            child: _RoomCard(
              roomId: roomProducts.first.roomId,
              roomProducts: roomProducts,
              isDialog: true,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRoomTemplateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final hotels = await ref.read(hotelsProvider.future);
    final products = await ref.read(productsProvider.future);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _RoomTemplateDialog(
        hotels: hotels,
        products: products,
      ),
    );

    ref.invalidate(hotelsProvider);
    ref.invalidate(roomsProvider);
    ref.invalidate(roomProductsProvider);
    ref.invalidate(dashboardProvider);
  }
}

enum _RoomOverallStatus { allOk, refillNeeded, attentionRequired }

class _CompactRoomTile extends ConsumerWidget {
  const _CompactRoomTile({
    required this.roomNumber,
    required this.roomProducts,
    required this.onTap,
  });

  final String roomNumber;
  final List<RoomProduct> roomProducts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color overallColor = Colors.green;
    var overallIcon = Icons.check_circle_outline;

    final hasCritical = roomProducts.any((item) =>
        item.status == BottleStatus.refillLimitReached ||
        item.status == BottleStatus.tooOld ||
        item.status == BottleStatus.needsReplacement ||
        item.status == BottleStatus.damaged ||
        item.status == BottleStatus.lost);

    final hasWarning =
        roomProducts.any((item) => item.status == BottleStatus.needsRefill);

    if (hasCritical) {
      overallColor = theme.colorScheme.error;
      overallIcon = Icons.warning_amber_rounded;
    } else if (hasWarning) {
      overallColor = Colors.orange.shade700;
      overallIcon = Icons.hourglass_empty_rounded;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 110,
        height: 85,
        decoration: BoxDecoration(
          color: overallColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: overallColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF92400E).withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(overallIcon, size: 16, color: overallColor),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${roomProducts.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Text(
                  roomNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// Extracted top-level private helpers for both product-centric and room-centric views
Future<void> _showRefillHistory(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  final events = await ref.read(refillEventsProvider.future);
  final user = await ref.read(currentUserProvider.future);
  final itemEvents = events
      .where((event) => event.roomProductId == item.id)
      .toList(growable: false);

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => _RefillHistoryDialog(
      item: item,
      events: itemEvents,
      currentUser: user,
    ),
  );

  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(approvalsProvider);
  ref.invalidate(dashboardProvider);
}

Future<void> _showRoomEditRequest(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _RoomEditRequestDialog(item: item),
  );

  ref.invalidate(approvalsProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(dashboardProvider);
}

Future<void> _showBottleEditRequest(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _BottleLifecycleEditDialog(item: item),
  );

  ref.invalidate(approvalsProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);
}

Future<void> _replaceBottle(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  final l10n = AppLocalizations.of(context);
  var isOffline = ref.read(offlineModeProvider);
  if (!isOffline) {
    try {
      await ref.read(repositoryProvider).replaceBottle(
            roomProductId: item.id,
            notes: l10n.t('roomsReplacementNotes'),
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
      type: SyncActionType.bottleReplacement,
      payload: {
        'roomProductId': item.id,
        'notes': l10n.t('roomsReplacementNotes'),
      },
    );
    ref.invalidate(offlineActionsProvider);
  }

  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(suggestedOrdersProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);

  if (!context.mounted) return;
  PremiumSnackbar.show(
    context,
    isOffline
        ? '${l10n.t('roomsReplacementQueued')} ${item.roomNumber}'
        : '${l10n.t('roomsReplacementRecorded')} ${item.roomNumber}',
    icon: Icons.recycling_outlined,
  );
}

// Room-Centric Grouped Card Widget
class _RoomCard extends ConsumerWidget {
  const _RoomCard({
    required this.roomId,
    required this.roomProducts,
    this.isDialog = false,
  });

  final String roomId;
  final List<RoomProduct> roomProducts;
  final bool isDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final firstItem = roomProducts.first;

    var overallStatus = l10n.t('roomsStatusAllOk');
    var overallColor = Colors.orange.shade700;
    var overallIcon = Icons.check_circle_outline;

    final hasCritical = roomProducts.any((item) =>
        item.status == BottleStatus.refillLimitReached ||
        item.status == BottleStatus.tooOld ||
        item.status == BottleStatus.needsReplacement ||
        item.status == BottleStatus.damaged ||
        item.status == BottleStatus.lost);

    final hasWarning =
        roomProducts.any((item) => item.status == BottleStatus.needsRefill);

    if (hasCritical) {
      overallStatus = l10n.t('roomsStatusAttentionRequired');
      overallColor = theme.colorScheme.error;
      overallIcon = Icons.warning_amber_rounded;
    } else if (hasWarning) {
      overallStatus = l10n.t('roomsStatusRefillNeeded');
      overallColor = Colors.orange.shade700;
      overallIcon = Icons.hourglass_empty_rounded;
    } else {
      overallColor = Colors.green;
      overallIcon = Icons.check_circle_outline;
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: overallColor.withValues(alpha: 0.2),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: overallColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.meeting_room_outlined, color: overallColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.t('roomsLabelRoom')} ${firstItem.roomNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${l10n.t('roomsLabelFloor')} ${firstItem.floorNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: overallColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: overallColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(overallIcon, size: 14, color: overallColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            overallStatus,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: overallColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDialog) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < roomProducts.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  _RoomCardProductRow(item: roomProducts[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Inline Row inside Room-Centric Card
class _RoomCardProductRow extends ConsumerWidget {
  const _RoomCardProductRow({required this.item});

  final RoomProduct item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canSubmitEditRequests =
        currentUser != null && currentUser.role != UserRole.hotelStaff;

    final statusColor = switch (item.status) {
      BottleStatus.refillLimitReached ||
      BottleStatus.tooOld ||
      BottleStatus.needsReplacement ||
      BottleStatus.damaged ||
      BottleStatus.lost =>
        theme.colorScheme.error,
      BottleStatus.needsRefill => Colors.orange.shade700,
      _ => Colors.orange.shade700,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final productThumb = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            item.product.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0C4A3A),
                    Color(0xFF267D65),
                  ],
                ),
              ),
              child: const Icon(
                Icons.spa_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        );

        final productDetails = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.product.label(language),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  item.product.sku,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${(item.product.bottleVolumeMl / 1000).toStringAsFixed(0)}L',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        );

        final statusChips = Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${l10n.t('roomsLabelRefills')}: ${item.refillCount}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${l10n.t('roomsLabelAge')}: ${item.bottleAgeDays(DateTime.now())}${l10n.t('roomsLabelDaysUnit')}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status.value.replaceAll('_', ' '),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: const Color(0xFF267D65),
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              onPressed: item.canRefill
                  ? () async {
                      var isOffline = ref.read(offlineModeProvider);
                      if (!isOffline) {
                        try {
                          await ref.read(repositoryProvider).recordRefill(
                                roomProductId: item.id,
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
                          type: SyncActionType.refill,
                          payload: {'roomProductId': item.id},
                        );
                        ref.invalidate(offlineActionsProvider);
                      }
                      ref.invalidate(roomProductsProvider);
                      ref.invalidate(dashboardProvider);
                      ref.invalidate(refillEventsProvider);
                      if (context.mounted) {
                        PremiumSnackbar.show(
                          context,
                          isOffline
                              ? '${l10n.t('roomsRefillQueued')} ${item.roomNumber}'
                              : '${l10n.t('roomsRefillRecorded')} ${item.roomNumber}',
                          icon: Icons.water_drop_outlined,
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.water_drop_outlined, size: 14),
              label:
                  Text(l10n.t('refill'), style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.t('roomsBtnReplaceBottle'),
              icon: const Icon(Icons.recycling_outlined, size: 20),
              onPressed: item.status == BottleStatus.recycled
                  ? null
                  : () => _replaceBottle(context, ref, item),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.t('roomsBtnHistory'),
              icon: const Icon(Icons.history_outlined, size: 20),
              onPressed: () => _showRefillHistory(context, ref, item),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.t('roomsBtnMoreActions'),
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) {
                if (val == 'bottle_edit') {
                  _showBottleEditRequest(context, ref, item);
                } else if (val == 'room_edit') {
                  _showRoomEditRequest(context, ref, item);
                }
              },
              itemBuilder: (context) => [
                if (canSubmitEditRequests) ...[
                  PopupMenuItem(
                    value: 'bottle_edit',
                    child: Row(
                      children: [
                        const Icon(Icons.spa_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.t('roomsBtnBottleEdit')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'room_edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_location_alt_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.t('roomsBtnRoomEdit')),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  productThumb,
                  const SizedBox(width: 12),
                  Expanded(child: productDetails),
                ],
              ),
              const SizedBox(height: 8),
              statusChips,
              const SizedBox(height: 8),
              actions,
            ],
          );
        }

        return Row(
          children: [
            productThumb,
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: productDetails,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: statusChips,
            ),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _BottleLifecycleEditDialog extends ConsumerStatefulWidget {
  const _BottleLifecycleEditDialog({required this.item});

  final RoomProduct item;

  @override
  ConsumerState<_BottleLifecycleEditDialog> createState() =>
      _BottleLifecycleEditDialogState();
}

class _BottleLifecycleEditDialogState
    extends ConsumerState<_BottleLifecycleEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bottleStartedAt;
  late BottleStatus _status;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
    _bottleStartedAt = TextEditingController(
      text: _formatDate(widget.item.bottleStartedAt),
    );
  }

  @override
  void dispose() {
    _bottleStartedAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
          '${l10n.t('roomsDialogBottleEditTitle')} ${widget.item.roomNumber}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BottleStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                    labelText: l10n.t('roomsLabelBottleStatus')),
                items: [
                  for (final status in BottleStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(status.value.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bottleStartedAt,
                decoration: InputDecoration(
                  labelText: l10n.t('roomsLabelBottleStartDate'),
                  hintText: 'YYYY-MM-DD',
                ),
                validator: (value) {
                  final parsed = DateTime.tryParse(value?.trim() ?? '');
                  if (parsed == null) {
                    return l10n.t('roomsValidationEnterValidDate');
                  }
                  return null;
                },
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
          onPressed: _isSaving ? null : _submit,
          icon: const Icon(Icons.pending_actions_outlined),
          label: Text(l10n.t('btnSubmitRequest')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final language = Localizations.localeOf(context).languageCode;
      final title =
          'Update ${widget.item.product.label(language)} bottle in room ${widget.item.roomNumber}';
      final oldData = {
        'status': widget.item.status.value,
        'bottle_started_at': _formatDate(widget.item.bottleStartedAt),
      };
      final newData = {
        'status': _status.value,
        'bottle_started_at': _bottleStartedAt.text.trim(),
      };
      final offline = ref.read(offlineModeProvider);
      final appliedImmediately = await _submitPendingEditRequest(
        ref: ref,
        hotelId: widget.item.hotelId,
        title: title,
        targetTable: 'room_products',
        targetId: widget.item.id,
        oldData: oldData,
        newData: newData,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              offline
                  ? l10n.t('roomsMsgEditRequestQueued')
                  : appliedImmediately
                      ? l10n.t('roomsMsgDetailsUpdated')
                      : l10n.t('roomsMsgEditRequestSubmitted'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RoomEditRequestDialog extends ConsumerStatefulWidget {
  const _RoomEditRequestDialog({required this.item});

  final RoomProduct item;

  @override
  ConsumerState<_RoomEditRequestDialog> createState() =>
      _RoomEditRequestDialogState();
}

class _RoomEditRequestDialogState
    extends ConsumerState<_RoomEditRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumber;
  late final TextEditingController _floorNumber;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _roomNumber = TextEditingController(text: widget.item.roomNumber);
    _floorNumber = TextEditingController(
      text: widget.item.floorNumber.toString(),
    );
  }

  @override
  void dispose() {
    _roomNumber.dispose();
    _floorNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
          '${l10n.t('roomsDialogRoomEditTitle')} ${widget.item.roomNumber}'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _roomNumber,
                decoration:
                    InputDecoration(labelText: l10n.t('roomsLabelRoomNumber')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.t('requiredField');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _NumberField(
                controller: _floorNumber,
                label: l10n.t('roomsLabelFloorNumber'),
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
          onPressed: _isSaving ? null : _submit,
          icon: const Icon(Icons.pending_actions_outlined),
          label: Text(l10n.t('btnSubmitRequest')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final oldData = {
        'room_number': widget.item.roomNumber,
        'floor_number': widget.item.floorNumber,
      };
      final newData = {
        'room_number': _roomNumber.text.trim(),
        'floor_number': int.parse(_floorNumber.text),
      };
      final offline = ref.read(offlineModeProvider);
      final appliedImmediately = await _submitPendingEditRequest(
        ref: ref,
        hotelId: widget.item.hotelId,
        title: 'Update room ${widget.item.roomNumber}',
        targetTable: 'rooms',
        targetId: widget.item.roomId,
        oldData: oldData,
        newData: newData,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              offline
                  ? l10n.t('roomsMsgRoomEditQueued')
                  : appliedImmediately
                      ? l10n.t('roomsMsgRoomDetailsUpdated')
                      : l10n.t('roomsMsgRoomEditSubmitted'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

Future<bool> _submitPendingEditRequest({
  required WidgetRef ref,
  required String hotelId,
  required String title,
  required String targetTable,
  required String targetId,
  required Map<String, dynamic> oldData,
  required Map<String, dynamic> newData,
}) async {
  var isOffline = ref.read(offlineModeProvider);
  final currentUser = ref.read(currentUserProvider).valueOrNull;
  final applyImmediately = currentUser?.isIvraUser ?? false;

  if (!isOffline) {
    try {
      final requestId = await ref.read(repositoryProvider).submitChangeRequest(
            hotelId: hotelId,
            title: title,
            targetTable: targetTable,
            targetId: targetId,
            oldData: oldData,
            newData: newData,
          );
      if (applyImmediately && requestId != null) {
        await ref.read(repositoryProvider).approveRequest(
              approvalRequestId: requestId,
            );
      }
      return applyImmediately;
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
      type: SyncActionType.pendingEdit,
      payload: {
        'hotelId': hotelId,
        'title': title,
        'targetTable': targetTable,
        'targetId': targetId,
        'oldData': oldData,
        'newData': newData,
      },
    );
    ref.invalidate(offlineActionsProvider);
    return false;
  }
  return false;
}

class _RefillHistoryDialog extends ConsumerWidget {
  const _RefillHistoryDialog({
    required this.item,
    required this.events,
    required this.currentUser,
  });

  final RoomProduct item;
  final List<RefillEvent> events;
  final UserProfile currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    return AlertDialog(
      title: Text(
          '${l10n.t('roomsLabelRoom')} ${item.roomNumber} ${item.product.label(language)} ${l10n.t('roomsDialogHistoryTitle')}'),
      content: SizedBox(
        width: 620,
        child: events.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.t('roomsNoHistoryRecorded')),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final canUndo = event.canUndo(now, currentUser.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_eventIcon(event.type)),
                    title: Text(_eventLabel(l10n, event.type)),
                    subtitle: Text(
                      '${_formatDateTime(event.occurredAt)} | '
                      '${event.previousRefillCount} -> ${event.newRefillCount}',
                    ),
                    trailing: event.type == RefillEventType.refill
                        ? Wrap(
                            spacing: 8,
                            children: [
                              if (canUndo)
                                TextButton.icon(
                                  onPressed: () async {
                                    final offline =
                                        ref.read(offlineModeProvider);
                                    if (offline) {
                                      await ref
                                          .read(offlineSyncServiceProvider)
                                          .enqueue(
                                        type: SyncActionType.undoRefill,
                                        payload: {'refillEventId': event.id},
                                      );
                                      ref.invalidate(offlineActionsProvider);
                                    } else {
                                      await ref
                                          .read(repositoryProvider)
                                          .undoRefill(refillEventId: event.id);
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            offline
                                                ? l10n.t('roomsMsgUndoQueued')
                                                : l10n
                                                    .t('roomsMsgRefillUndone'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.undo_outlined),
                                  label: Text(l10n.t('undo')),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () => _showCorrectionDialog(
                                    context,
                                    ref,
                                    event,
                                  ),
                                  icon: const Icon(
                                    Icons.assignment_late_outlined,
                                  ),
                                  label: Text(l10n.t('correction')),
                                ),
                            ],
                          )
                        : null,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('roomsBtnClose')),
        ),
      ],
    );
  }

  String _eventLabel(AppLocalizations l10n, RefillEventType type) {
    return switch (type) {
      RefillEventType.refill => l10n.t('refill'),
      RefillEventType.undo => l10n.t('undo'),
      RefillEventType.correctionRequested => l10n.t('metricPendingApprovals'),
      RefillEventType.correctionApproved => l10n.t('refillEventApproved'),
      RefillEventType.correctionRejected => l10n.t('refillEventRejected'),
      RefillEventType.bottleReplaced => l10n.t('roomsBtnReplaceBottle'),
    };
  }

  IconData _eventIcon(RefillEventType type) {
    return switch (type) {
      RefillEventType.refill => Icons.water_drop_outlined,
      RefillEventType.undo => Icons.undo_outlined,
      RefillEventType.correctionRequested => Icons.assignment_late_outlined,
      RefillEventType.correctionApproved => Icons.task_alt_outlined,
      RefillEventType.correctionRejected => Icons.block_outlined,
      RefillEventType.bottleReplaced => Icons.recycling_outlined,
    };
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  Future<void> _showCorrectionDialog(
    BuildContext context,
    WidgetRef ref,
    RefillEvent event,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CorrectionRequestDialog(event: event),
    );
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _CorrectionRequestDialog extends ConsumerStatefulWidget {
  const _CorrectionRequestDialog({required this.event});

  final RefillEvent event;

  @override
  ConsumerState<_CorrectionRequestDialog> createState() =>
      _CorrectionRequestDialogState();
}

class _CorrectionRequestDialogState
    extends ConsumerState<_CorrectionRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  var _isSaving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.t('roomsBtnRequestCorrection')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _reason,
            decoration: InputDecoration(
              labelText: l10n.t('roomsLabelReason'),
              alignLabelWithHint: true,
            ),
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.t('requiredField');
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          icon: const Icon(Icons.assignment_late_outlined),
          label: Text(l10n.t('btnSubmitRequest')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final offline = ref.read(offlineModeProvider);
      if (offline) {
        await ref.read(offlineSyncServiceProvider).enqueue(
          type: SyncActionType.correctionRequest,
          payload: {
            'refillEventId': widget.event.id,
            'reason': _reason.text.trim(),
          },
        );
        ref.invalidate(offlineActionsProvider);
      } else {
        await ref.read(repositoryProvider).requestCorrection(
              refillEventId: widget.event.id,
              reason: _reason.text.trim(),
            );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              offline
                  ? l10n.t('roomsMsgCorrectionQueued')
                  : l10n.t('roomsMsgCorrectionSubmitted'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RoomTemplateDialog extends ConsumerStatefulWidget {
  const _RoomTemplateDialog({
    required this.hotels,
    required this.products,
  });

  final List<Hotel> hotels;
  final List<Product> products;

  @override
  ConsumerState<_RoomTemplateDialog> createState() =>
      _RoomTemplateDialogState();
}

class _RoomTemplateDialogState extends ConsumerState<_RoomTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _floorNumber = TextEditingController(text: '1');
  final _firstRoomNumber = TextEditingController(text: '101');
  final _roomCount = TextEditingController(text: '10');
  late String _hotelId;
  late final Set<String> _selectedProductIds;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hotelId = widget.hotels.first.id;
    _selectedProductIds =
        widget.products.take(4).map((product) => product.id).toSet();
  }

  @override
  void dispose() {
    _floorNumber.dispose();
    _firstRoomNumber.dispose();
    _roomCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return AlertDialog(
      title: Text(l10n.t('roomsTooltipCreateTemplate')),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _hotelId,
                  decoration: InputDecoration(labelText: l10n.t('hotels')),
                  items: [
                    for (final hotel in widget.hotels)
                      DropdownMenuItem(
                        value: hotel.id,
                        child: Text(hotel.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _hotelId = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _floorNumber,
                        label: l10n.t('roomsLabelFloor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _firstRoomNumber,
                        label: l10n.t('roomsLabelRoom'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _roomCount,
                        label:
                            '${l10n.t('roomsLabelRoom')} count', // count is universal/clear, or let's use it dynamically
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.t('roomsLabelProductsInRoom'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final product in widget.products)
                      FilterChip(
                        label: Text(product.label(language)),
                        selected: _selectedProductIds.contains(product.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedProductIds.add(product.id);
                            } else {
                              _selectedProductIds.remove(product.id);
                            }
                          });
                        },
                      ),
                  ],
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
          icon: const Icon(Icons.auto_awesome_motion_outlined),
          label: Text(l10n.t('roomsBtnCreateRooms')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('roomsMsgSelectOneProduct'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(repositoryProvider).createRoomsFromTemplate(
            hotelId: _hotelId,
            floorNumber: int.parse(_floorNumber.text),
            firstRoomNumber: int.parse(_firstRoomNumber.text),
            roomCount: int.parse(_roomCount.text),
            productIds: _selectedProductIds.toList(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
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
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null || parsed <= 0) {
          return l10n.t('enterNumberError');
        }
        return null;
      },
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
