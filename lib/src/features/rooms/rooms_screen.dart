import 'dart:convert';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../ui/ivra_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../shared/product_image.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/centered_sheet.dart';
import '../shared/glass_card.dart';
import '../shared/page_scaffold.dart';
import '../shared/empty_state.dart';
import '../shared/premium_snackbar.dart';
import '../shared/shimmer_loading.dart';
import '../shared/premium_loading.dart';
import '../shared/premium_confirm_dialog.dart';
import '../shared/premium_qr_scanner_dialog.dart';
import '../shared/refill_percentage_dialog.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({
    super.key,
    this.autoStartScan = false,
    this.hotelId,
    this.floorNumber,
    this.roomNumber,
  });

  static const route = '/rooms';
  final bool autoStartScan;
  final String? hotelId;
  final String? floorNumber;
  final String? roomNumber;

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  String _searchQuery = '';
  String _productSearchQuery = '';
  String _statusFilter = 'all'; // 'all', 'ok', 'refill', 'attention'
  bool _showDetailedView = false; // true = Detailed, false = Compact
  final Set<int> _expandedFloors = <int>{};
  late final TextEditingController _searchController;
  late final TextEditingController _productSearchController;
  bool _scanTriggered = false;
  bool _hasAutoOpened = false;

  // Recently-visited room numbers for the currently loaded hotel, most-recent
  // first. Persisted per hotel so housekeeping staff can jump back to rooms
  // they just worked on without re-searching.
  static const _maxRecentRooms = 8;
  String? _recentRoomsHotelId;
  List<String> _recentRooms = const [];

  String _recentRoomsKey(String hotelId) => 'recent_rooms_$hotelId';

  Future<void> _loadRecentRooms(String hotelId) async {
    if (_recentRoomsHotelId == hotelId) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentRoomsKey(hotelId)) ?? const [];
    if (!mounted) return;
    setState(() {
      _recentRoomsHotelId = hotelId;
      _recentRooms = stored;
    });
  }

  Future<void> _recordRecentRoom(String hotelId, String roomNumber) async {
    final trimmed = roomNumber.trim();
    if (trimmed.isEmpty) return;
    final updated = <String>[
      trimmed,
      ..._recentRooms.where((r) => r != trimmed),
    ].take(_maxRecentRooms).toList();
    if (mounted) {
      setState(() {
        _recentRoomsHotelId = hotelId;
        _recentRooms = updated;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentRoomsKey(hotelId), updated);
  }

  Future<void> _clearRecentRooms(String hotelId) async {
    if (mounted) setState(() => _recentRooms = const []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentRoomsKey(hotelId));
  }

  void _applyRoomSearch(String roomNumber) {
    _searchController.text = roomNumber;
    setState(() => _searchQuery = roomNumber.trim());
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _productSearchController = TextEditingController();
    if (widget.hotelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHotelIdProvider.notifier).state = widget.hotelId;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isCompact = MediaQuery.of(context).size.width < 600;

    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final canCreateRoomsFromTemplate = (currentUser?.isIvraUser == true) ||
        (currentUser?.role == UserRole.hotelManager && currentUser?.hotelId == selectedHotelId);

    final hotelsAsync = ref.watch(hotelsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final roomProductsAsync = ref.watch(roomProductsProvider);

    final combinedAsync = roomsAsync.when<AsyncValue<List<_RoomGroup>>>(
      data: (rooms) {
        return roomProductsAsync.when<AsyncValue<List<_RoomGroup>>>(
          data: (products) {
            final groups = rooms.map((room) {
              final roomProducts = products.where((p) => p.roomId == room.id).toList();
              return _RoomGroup(roomInfo: room, products: roomProducts);
            }).toList();
            return AsyncValue.data(groups);
          },
          error: (err, stack) => AsyncValue.error(err, stack),
          loading: () => const AsyncValue.loading(),
        );
      },
      error: (err, stack) => AsyncValue.error(err, stack),
      loading: () => const AsyncValue.loading(),
    );

    // Load the recent-rooms list for the active hotel (no-op if unchanged).
    if (selectedHotelId != null && _recentRoomsHotelId != selectedHotelId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRecentRooms(selectedHotelId);
      });
    }

    if (widget.autoStartScan && !_scanTriggered && roomProductsAsync.hasValue) {
      _scanTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
          final roomProducts = roomProductsAsync.value ?? const [];
          final hotelItems = selectedHotelId != null
              ? roomProducts.where((item) => item.hotelId == selectedHotelId).toList()
              : roomProducts;

          await _scanRoomOrProductQr(context, hotelItems);
          if (context.mounted) {
            context.go(RoomsScreen.route);
          }
        }
      });
    }

    final combinedValue = combinedAsync.valueOrNull;
    if (combinedValue != null && widget.roomNumber != null && !_hasAutoOpened) {
      final matchedGroup = combinedValue.cast<_RoomGroup?>().firstWhere(
        (g) => g?.roomNumber.toLowerCase() == widget.roomNumber!.toLowerCase(),
        orElse: () => null,
      );
      if (matchedGroup != null) {
        _hasAutoOpened = true;
        _expandedFloors.add(matchedGroup.floorNumber);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRoomDetailsDialog(context, matchedGroup);
        });
      }
    }

    return PageScaffold(
      title: l10n.t('rooms'),
      onRefresh: () async {
        ref.invalidate(hotelsProvider);
        ref.invalidate(roomsProvider);
        ref.invalidate(roomProductsProvider);
        await Future.wait([
          ref.read(hotelsProvider.future),
          ref.read(roomsProvider.future),
          ref.read(roomProductsProvider.future),
        ]);
      },
      actions: [
        if (isCompact)
          IconButton(
            tooltip: l10n.t('roomsGestionExpressQr'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/qr');
            },
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              foregroundColor: primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: Text(
              l10n.t('roomsGestionExpressQr'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/qr');
            },
          ),
        const SizedBox(width: 8),
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
                  value: combinedAsync,
                  onRetry: () {
                    ref.invalidate(roomsProvider);
                    ref.invalidate(roomProductsProvider);
                  },
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
                  builder: (groups) {
                    if (groups.isEmpty) {
                      return EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: l10n.t('roomsNoRoomsFound'),
                        message: canCreateRoomsFromTemplate
                            ? l10n.t('roomsEmptyHotelWithTemplate')
                            : l10n.t('roomsEmptyHotelNoTemplate'),
                      );
                    }

                    // Apply search query and status filter at room level
                    final filteredGroups = groups.where((group) {
                      // Search filter
                      if (_searchQuery.isNotEmpty) {
                        if (!group.roomNumber
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) {
                          return false;
                        }
                      }

                      // Product search filter
                      if (_productSearchQuery.isNotEmpty) {
                        final query = _productSearchQuery.toLowerCase();
                        final matches = group.products.any((item) {
                          final name = item.product.label(Localizations.localeOf(context).languageCode).toLowerCase();
                          final sku = item.product.sku.toLowerCase();
                          return name.contains(query) || sku.contains(query);
                        });
                        if (!matches) {
                          return false;
                        }
                      }

                      // Status filter
                      if (_statusFilter != 'all') {
                        final overallStatus =
                            _getRoomOverallStatus(group.products);
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

                    if (filteredGroups.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_outlined,
                        title: l10n.t('roomsNoRoomsFound'),
                        message: l10n.t('roomsSearchEmptyHint'),
                      );
                    }

                    // Group rooms by floor
                    final Map<int, List<_RoomGroup>> roomsByFloor = {};
                    for (final group in filteredGroups) {
                      roomsByFloor.putIfAbsent(group.floorNumber, () => []).add(group);
                    }

                    final sortedFloors = roomsByFloor.keys.toList()..sort();
                    final isMobile = MediaQuery.sizeOf(context).width < 720;
                    final canDeleteRooms = ref.watch(hasPermissionProvider('manage_rooms')) &&
                        (currentUser?.isIvraUser == true || currentUser?.hotelId == selectedHotelId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isMobile) ...[
                          _RoomsMobileSummary(
                            rooms: filteredGroups,
                            getStatus: _getRoomOverallStatus,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildCollapseExpandBar(sortedFloors, l10n, theme),
                        const SizedBox(height: 8),
                        for (final floor in sortedFloors) ...[
                          (() {
                            final floorRooms = roomsByFloor[floor]!;
                            final floorHasCritical = floorRooms.any((group) {
                              final status = _getRoomOverallStatus(group.products);
                              return status == _RoomOverallStatus.attentionRequired;
                            });
                            final floorHasWarning = floorRooms.any((group) {
                              final status = _getRoomOverallStatus(group.products);
                              return status == _RoomOverallStatus.refillNeeded;
                            });
                            return _buildFloorHeader(
                              floor,
                              l10n,
                              theme,
                              primaryColor,
                              isExpanded: _expandedFloors.contains(floor) ||
                                  _searchQuery.isNotEmpty ||
                                  _productSearchQuery.isNotEmpty,
                              roomCount: floorRooms.length,
                              hasCritical: floorHasCritical,
                              hasWarning: floorHasWarning,
                              onToggle: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (_expandedFloors.contains(floor)) {
                                    _expandedFloors.remove(floor);
                                  } else {
                                    _expandedFloors.add(floor);
                                  }
                                });
                              },
                              onAddRoom: canDeleteRooms
                                  ? () => _showAddRoomDialog(
                                      context, ref, selectedHotelId, floor)
                                  : null,
                              onDeleteFloor: canDeleteRooms
                                  ? () => _confirmDeleteFloor(context, ref, floor)
                                  : null,
                            );
                          })(),
                          if (_expandedFloors.contains(floor) ||
                              _searchQuery.isNotEmpty ||
                              _productSearchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: _showDetailedView
                                ? Column(
                                    key: const ValueKey('detailed_view'),
                                    children: [
                                      for (final group in _sortRoomsInFloor(
                                          roomsByFloor[floor]!))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                            child: _RoomCard(
                                              roomId: group.roomId,
                                              roomProducts: group.products,
                                              roomNumber: group.roomNumber,
                                              floorNumber: group.floorNumber,
                                              hotelId: group.hotelId,
                                              onDeleteRoom: canDeleteRooms
                                                  ? () => _confirmDeleteRoom(
                                                      context, ref, group.roomId, group.roomNumber)
                                                  : null,
                                              productSearchQuery: _productSearchQuery,
                                            ),),
                                    ],
                                  )
                                : Padding(
                                    key: const ValueKey('compact_view'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        for (final group in _sortRoomsInFloor(
                                            roomsByFloor[floor]!))
                                          _CompactRoomTile(
                                            roomNumber: group.roomNumber,
                                            roomProducts: group.products,
                                            onTap: () => _showRoomDetailsDialog(
                                              context,
                                              group,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                          ],
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

  List<_RoomGroup> _sortRoomsInFloor(
    List<_RoomGroup> floorRooms,
  ) {
    return floorRooms.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.roomNumber) ?? 0;
        final bNum = int.tryParse(b.roomNumber) ?? 0;
        if (aNum != 0 && bNum != 0) {
          return aNum.compareTo(bNum);
        }
        return a.roomNumber.compareTo(b.roomNumber);
      });
  }

  _RoomOverallStatus _getRoomOverallStatus(List<RoomProduct> products) {
    if (products.isEmpty) return _RoomOverallStatus.noProducts;
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

  Widget _buildCollapseExpandBar(
    List<int> sortedFloors,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: [
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _expandedFloors.clear());
          },
          icon: const Icon(Icons.unfold_less_rounded, size: 18),
          label: Text(l10n.t('roomsCollapseAll')),
        ),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _expandedFloors.addAll(sortedFloors));
          },
          icon: const Icon(Icons.unfold_more_rounded, size: 18),
          label: Text(l10n.t('roomsExpandAll')),
        ),
      ],
    );
  }

  Widget _buildFloorHeader(
    int floor,
    AppLocalizations l10n,
    ThemeData theme,
    Color primaryColor, {
    required bool isExpanded,
    required int roomCount,
    required bool hasCritical,
    required bool hasWarning,
    required VoidCallback onToggle,
    VoidCallback? onAddRoom,
    VoidCallback? onDeleteFloor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.chevron_right_rounded,
                  color: primaryColor, size: 26),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.2),
                    primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(Icons.layers_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                '${l10n.t('roomsLabelFloor')} $floor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$roomCount',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ),
            if (hasCritical) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.t('roomsStatusAttentionRequired'),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
            ] else if (hasWarning) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.t('roomsStatusRefillNeeded'),
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
            ],
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.5),
                      primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            if (onAddRoom != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.t('roomsBtnAddRoom'),
                icon: Icon(Icons.add_circle_outline, color: primaryColor),
                onPressed: onAddRoom,
              ),
            ],
            if (onDeleteFloor != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.t('delete'),
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: onDeleteFloor,
              ),
            ],
          ],
        ),
      ),
        ),
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
    final roomProducts = ref.watch(roomProductsProvider).valueOrNull ?? const [];
    final hotelItems = selectedHotelId != null
        ? roomProducts.where((item) => item.hotelId == selectedHotelId).toList()
        : const <RoomProduct>[];

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
              final roomSearchField = SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.t('roomsSearchPlaceholder'),
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: Colors.grey),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                        IconButton(
                          tooltip: l10n.t('qrScanTitle'),
                          icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                          onPressed: () => _scanRoomOrProductQr(context, hotelItems),
                        ),
                      ],
                    ),
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

              final productSearchField = SizedBox(
                height: 44,
                child: TextField(
                  controller: _productSearchController,
                  decoration: InputDecoration(
                    hintText: l10n.t('roomsSearchProductPlaceholder'),
                    prefixIcon:
                        const Icon(Icons.spa_outlined, size: 20, color: Colors.grey),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_productSearchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _productSearchController.clear();
                              setState(() {
                                _productSearchQuery = '';
                              });
                            },
                          ),
                        IconButton(
                          tooltip: l10n.t('qrScanTitle'),
                          icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                          onPressed: () => _scanProductQrGlobal(context, hotelItems),
                        ),
                      ],
                    ),
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
                      _productSearchQuery = val.trim();
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
                  HapticFeedback.lightImpact();
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
                    Expanded(child: roomSearchField),
                    const SizedBox(width: 12),
                    Expanded(child: productSearchField),
                    const SizedBox(width: 16),
                    viewToggle,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  roomSearchField,
                  const SizedBox(height: 12),
                  productSearchField,
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
                    HapticFeedback.lightImpact();
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
                    HapticFeedback.lightImpact();
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
                    HapticFeedback.lightImpact();
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
                    HapticFeedback.lightImpact();
                    if (selected) setState(() => _statusFilter = 'attention');
                  },
                ),
              ],
            ),
          ),
          // Recent rooms shortcut
          if (selectedHotelId != null && _recentRooms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  l10n.t('roomsRecentTitle'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _clearRecentRooms(selectedHotelId);
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                  child: Text(l10n.t('roomsRecentClear')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final roomNumber in _recentRooms)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(Icons.meeting_room_outlined,
                            size: 16, color: primaryColor),
                        label: Text(roomNumber),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _applyRoomSearch(roomNumber);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scanRoomOrProductQr(BuildContext context, List<RoomProduct> hotelItems) async {
    final roomCodes = hotelItems.map((e) => 'room:${e.hotelId}:${e.roomNumber}').toSet().toList();
    final productCodes = hotelItems.map((e) => 'product:${e.product.sku}').toSet().toList();
    final allDemoCodes = [...roomCodes, ...productCodes];

    final code = await PremiumQrScannerDialog.show(context, demoCodes: allDemoCodes);
    if (code == null || code.trim().isEmpty) return;

    final trimmed = code.trim();
    if (trimmed.startsWith('room:')) {
      final parts = trimmed.split(':');
      if (parts.length >= 3) {
        final hotelId = parts[1];
        final roomNumber = parts[2];
        ref.read(selectedHotelIdProvider.notifier).state = hotelId;
        _searchController.text = roomNumber;
        setState(() {
          _searchQuery = roomNumber;
        });
        _recordRecentRoom(hotelId, roomNumber);
      }
    } else if (trimmed.startsWith('product:')) {
      final sku = trimmed.split(':')[1];
      _productSearchController.text = sku;
      setState(() {
        _productSearchQuery = sku;
      });
    } else {
      // Check if it matches a product SKU in hotelItems
      final isSku = hotelItems.any((e) => e.product.sku.toLowerCase() == trimmed.toLowerCase());
      if (isSku) {
        _productSearchController.text = trimmed;
        setState(() {
          _productSearchQuery = trimmed;
        });
      } else {
        // Assume it's a room number
        _searchController.text = trimmed;
        setState(() {
          _searchQuery = trimmed;
        });
      }
    }
  }

  Future<void> _scanProductQrGlobal(BuildContext context, List<RoomProduct> hotelItems) async {
    final productCodes = hotelItems.map((e) => 'product:${e.product.sku}').toSet().toList();
    final code = await PremiumQrScannerDialog.show(context, demoCodes: productCodes);
    if (code == null || code.trim().isEmpty) return;

    final trimmed = code.trim();
    final sku = trimmed.startsWith('product:') ? trimmed.split(':')[1] : trimmed;
    _productSearchController.text = sku;
    setState(() {
      _productSearchQuery = sku;
    });
  }

  void _showRoomDetailsDialog(
    BuildContext context,
    _RoomGroup group,
  ) {
    _recordRecentRoom(group.hotelId, group.roomNumber);
    showCenteredFormSheet<void>(
      context: context,
      scrollable: false,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: _RoomCard(
          roomId: group.roomId,
          roomProducts: group.products,
          roomNumber: group.roomNumber,
          floorNumber: group.floorNumber,
          hotelId: group.hotelId,
          isDialog: true,
          productSearchQuery: _productSearchQuery,
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

    await showCenteredFormSheet<void>(
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

  Future<void> _showAddRoomDialog(
    BuildContext context,
    WidgetRef ref,
    String hotelId,
    int floorNumber,
  ) async {
    final products = await ref.read(productsProvider.future);
    if (!context.mounted) return;

    await showCenteredFormSheet<void>(
      context: context,
      builder: (context) => _AddRoomDialog(
        hotelId: hotelId,
        floorNumber: floorNumber,
        products: products,
      ),
    );

    ref.invalidate(hotelsProvider);
    ref.invalidate(roomsProvider);
    ref.invalidate(roomProductsProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> _confirmDeleteRoom(
      BuildContext context, WidgetRef ref, String roomId, String roomNumber) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await PremiumConfirmDialog.show(
      context,
      title: l10n.t('delete'),
      message: l10n.tParams('confirmDeleteRoom', {'roomNumber': roomNumber}),
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteRoom(roomId);
        ref.invalidate(roomsProvider);
        ref.invalidate(roomProductsProvider);
      } catch (e) {
        if (context.mounted) {
          PremiumSnackbar.showError(context, e);
        }
      }
    }
  }

  Future<void> _confirmDeleteFloor(
      BuildContext context, WidgetRef ref, int floorNumber) async {
    final l10n = AppLocalizations.of(context);
    
    final roomsList = await ref.read(roomsProvider.future);
    if (!context.mounted) return;
    final floorInfo = roomsList.where((r) => r.floorNumber == floorNumber).firstOrNull;
    if (floorInfo == null) return;
    final floorId = floorInfo.floorId;

    final confirmed = await PremiumConfirmDialog.show(
      context,
      title: l10n.t('delete'),
      message: l10n.tParams('confirmDeleteFloor', {'floorNumber': floorNumber.toString()}),
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteFloor(floorId);
        ref.invalidate(roomsProvider);
        ref.invalidate(roomProductsProvider);
      } catch (e) {
        if (context.mounted) {
          PremiumSnackbar.showError(context, e);
        }
      }
    }
  }
}

enum _RoomOverallStatus { allOk, refillNeeded, attentionRequired, noProducts }

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
    final l10n = AppLocalizations.of(context);
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

    if (roomProducts.isEmpty) {
      overallColor = Colors.blue.shade600;
      overallIcon = Icons.info_outline;
    } else if (hasCritical) {
      overallColor = theme.colorScheme.error;
      overallIcon = Icons.warning_amber_rounded;
    } else if (hasWarning) {
      overallColor = Colors.orange.shade700;
      overallIcon = Icons.hourglass_empty_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: overallColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: overallColor.withValues(alpha: 0.2),
          highlightColor: overallColor.withValues(alpha: 0.1),
          child: Ink(
            width: 110,
            height: 110, // Made it a bit taller for better spacing
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  overallColor.withValues(alpha: 0.15),
                  overallColor.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: overallColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Top Right Icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(overallIcon, size: 20, color: overallColor),
                ),
                // Top Left Product Count
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 10,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${roomProducts.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Center Room Number
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        roomNumber,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        l10n.t('roomsLabelRoom'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom highlight bar
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: overallColor.withValues(alpha: 0.6),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
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

// Extracted top-level private helpers for both product-centric and room-centric views
Future<void> showRefillHistory(
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

  await showCenteredFormSheet<void>(
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
  await showCenteredFormSheet<void>(
    context: context,
    builder: (context) => _RoomEditRequestDialog(
      roomId: item.roomId,
      roomNumber: item.roomNumber,
      floorNumber: item.floorNumber,
      hotelId: item.hotelId,
    ),
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
  await showCenteredFormSheet<void>(
    context: context,
    builder: (context) => _BottleLifecycleEditDialog(item: item),
  );

  ref.invalidate(approvalsProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);
}

Future<void> showMarkDamagedDialog(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  await showCenteredFormSheet<void>(
    context: context,
    builder: (context) => _MarkDamagedDialog(item: item),
  );

  ref.invalidate(approvalsProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);
}

Future<void> showMarkLostDialog(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  await showCenteredFormSheet<void>(
    context: context,
    builder: (context) => _MarkLostDialog(item: item),
  );

  ref.invalidate(approvalsProvider);
  ref.invalidate(hotelsProvider);
  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);
}

Future<bool?> _showInsufficientStockDialog({
  required BuildContext context,
  required String productName,
  required String message,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Text(l10n.t('inventoryEnforceTitle')),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.t('inventoryEnforceBtnProceed')),
        ),
      ],
    ),
  );
}

Future<bool?> _showHousekeeperStockDialog({
  required BuildContext context,
  required String message,
  required bool showProceedAction,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Text(l10n.t('inventoryEnforceTitle')),
        ],
      ),
      content: Text(message),
      actions: [
        if (showProceedAction) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('btnCancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('btnConfirm')),
          ),
        ] else ...[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('btnOk')),
          ),
        ],
      ],
    ),
  );
}

Future<void> replaceBottle(
  BuildContext context,
  WidgetRef ref,
  RoomProduct item,
) async {
  final l10n = AppLocalizations.of(context);
  var isOffline = ref.read(offlineModeProvider);

  // Check inventory stock
  final currentUser = ref.read(currentUserProvider).valueOrNull;
  final isHousekeeper = currentUser?.role == UserRole.housekeeper;

  var autoAdjust = false;

  if (isHousekeeper) {
    List<HousekeeperAllocation> allocations = [];
    try {
      allocations = await ref.read(housekeeperAllocationsProvider.future);
    } catch (_) {
      allocations = ref.read(housekeeperAllocationsProvider).valueOrNull ?? [];
    }

    final housekeeperAllocation = allocations.firstWhere(
      (a) => a.product.id == item.product.id,
      orElse: () => HousekeeperAllocation(
        id: '',
        housekeeperId: currentUser?.id ?? '',
        hotelId: item.hotelId,
        product: item.product,
        fullBottles: 0,
        emptyBottles: 0,
        fullBidons: 0,
        openBidons: 0,
        emptyBidons: 0,
        openBidonVolumeLeftMl: 0,
      ),
    );

    if (housekeeperAllocation.fullBottles == 0) {
      List<InventoryItem> inventory = [];
      try {
        inventory = await ref.read(inventoryProvider.future);
      } catch (_) {
        inventory = ref.read(inventoryProvider).valueOrNull ?? [];
      }

      final hotelStockItem = inventory.firstWhere(
        (stock) => stock.product.id == item.product.id,
        orElse: () => InventoryItem(
          id: '',
          hotelId: item.hotelId,
          product: item.product,
          fullBottles: 0,
          emptyBottles: 0,
          fullBidons: 0,
          openBidons: 0,
          emptyBidons: 0,
        ),
      );
      final hotelBottles = hotelStockItem.fullBottles;
      final language = Localizations.localeOf(context).languageCode;
      final productName = item.product.label(language);

      if (hotelBottles > 0) {
        final proceed = await _showHousekeeperStockDialog(
          context: context,
          message: l10n.tParams('housekeeperReplaceGetFromHotel', {
            'product': productName,
            'room': item.roomNumber,
            'count': hotelBottles.toString(),
          }),
          showProceedAction: true,
        );
        if (proceed != true) return;
        
        // Deduct 1 full bottle from hotel central inventory and add to housekeeper allocation/cart
        await ref.read(repositoryProvider).checkoutHousekeeperStock(
          housekeeperId: currentUser!.id,
          productId: item.product.id,
          fullBottles: 1,
          fullBidons: 0,
        );
        autoAdjust = false;
      } else {
        await _showHousekeeperStockDialog(
          context: context,
          message: l10n.tParams('housekeeperReplaceNotifyManager', {
            'product': productName,
            'room': item.roomNumber,
          }),
          showProceedAction: false,
        );
        return; // Cannot proceed
      }
    }
  } else {
    List<InventoryItem> inventory = [];
    try {
      inventory = await ref.read(inventoryProvider.future);
    } catch (_) {
      inventory = ref.read(inventoryProvider).valueOrNull ?? [];
    }

    final stockItem = inventory.firstWhere(
      (stock) => stock.product.id == item.product.id,
      orElse: () => InventoryItem(
        id: '',
        hotelId: item.hotelId,
        product: item.product,
        fullBottles: 0,
        emptyBottles: 0,
        fullBidons: 0,
        openBidons: 0,
        emptyBidons: 0,
      ),
    );

    if (stockItem.fullBottles == 0) {
      final language = Localizations.localeOf(context).languageCode;
      final proceed = await _showInsufficientStockDialog(
        context: context,
        productName: item.product.label(language),
        message: l10n.tParams('inventoryEnforceReplaceContent', {
          'product': item.product.label(language),
          'room': item.roomNumber,
        }),
      );
      if (proceed != true) return;
      autoAdjust = true;
    }
  }

  if (!isOffline) {
    try {
      await ref.read(repositoryProvider).replaceBottle(
            roomProductId: item.id,
            notes: l10n.t('roomsReplacementNotes'),
            autoAdjustInventory: autoAdjust,
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
        'autoAdjustInventory': autoAdjust,
      },
    );
    ref.invalidate(offlineActionsProvider);
  }

  ref.invalidate(roomProductsProvider);
  ref.invalidate(refillEventsProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(housekeeperAllocationsProvider);
  ref.invalidate(suggestedOrdersProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(dashboardProvider);

  if (!context.mounted) return;
  PremiumSnackbar.show(
    context,
    isOffline
        ? '${l10n.t('roomsReplacementQueued')} ${item.roomNumber}'
        : '${l10n.t('roomsReplacementRecorded')} ${item.roomNumber}',
    icon: IvraIcons.replaceAction,
  );
}

class _AddProductToRoomDialog extends ConsumerStatefulWidget {
  const _AddProductToRoomDialog({
    required this.hotelId,
    required this.floorNumber,
    required this.roomNumber,
    required this.existingProductIds,
  });

  final String hotelId;
  final int floorNumber;
  final String roomNumber;
  final Set<String> existingProductIds;

  @override
  ConsumerState<_AddProductToRoomDialog> createState() => _AddProductToRoomDialogState();
}

class _AddProductToRoomDialogState extends ConsumerState<_AddProductToRoomDialog> {
  String? _selectedSku;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(l10n.t('roomsAddProductTitle')),
        ],
      ),
      content: productsAsync.when(
        data: (products) {
          final availableProducts = products
              .where((p) => !widget.existingProductIds.contains(p.id))
              .toList();

          if (availableProducts.isEmpty) {
            return Text(l10n.t('roomsNoRoomsFound'));
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.t('roomsSelectProduct'),
                  border: const OutlineInputBorder(),
                ),
                value: _selectedSku,
                items: availableProducts.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.sku,
                    child: Text('${p.label(language)} (${p.sku})'),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (val) {
                        setState(() {
                          _selectedSku = val;
                        });
                      },
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Text(e.toString()),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton(
          onPressed: _selectedSku == null || _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await ref.read(repositoryProvider).addProductToRoom(
                          hotelId: widget.hotelId,
                          floor: widget.floorNumber.toString(),
                          roomNumber: widget.roomNumber,
                          productSku: _selectedSku!,
                          autoAdjustInventory: true,
                        );

                    ref.invalidate(roomProductsProvider);
                    ref.invalidate(dashboardProvider);
                    ref.invalidate(roomsProvider);

                    if (context.mounted) {
                      HapticFeedback.mediumImpact();
                      PremiumSnackbar.show(
                        context,
                        l10n.t('roomsProductAdded'),
                        icon: Icons.check_circle_outline,
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      PremiumSnackbar.showError(context, e);
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.t('btnConfirm')),
        ),
      ],
    );
  }
}

// Room-Centric Grouped Card Widget
class _RoomCard extends ConsumerStatefulWidget {
  const _RoomCard({
    required this.roomId,
    required this.roomProducts,
    required this.roomNumber,
    required this.floorNumber,
    required this.hotelId,
    this.isDialog = false,
    this.onDeleteRoom,
    this.productSearchQuery = '',
    super.key,
  });

  final String roomId;
  final List<RoomProduct> roomProducts;
  final String roomNumber;
  final int floorNumber;
  final String hotelId;
  final bool isDialog;
  final VoidCallback? onDeleteRoom;
  final String productSearchQuery;

  @override
  ConsumerState<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends ConsumerState<_RoomCard> {
  bool _isHovered = false;

  Future<void> _scanCardProductQr(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final allProducts = ref.read(roomProductsProvider).valueOrNull ?? widget.roomProducts;
    final currentRoomProducts = allProducts.where((p) => p.roomId == widget.roomId).toList();
    final products = currentRoomProducts.map((e) => 'product:${e.product.sku}').toList();

    final code = await PremiumQrScannerDialog.show(context, demoCodes: products);
    if (code == null) return;

    final sku = code.startsWith('product:') ? code.split(':')[1] : code;
    final matchedItem = currentRoomProducts.where((e) => e.product.sku.toLowerCase() == sku.toLowerCase()).firstOrNull;

    if (matchedItem == null) {
      if (mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('roomsNoRoomsFound'),
          icon: Icons.error_outline_rounded,
        );
      }
      return;
    }

    if (!mounted) return;

    final selection = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.t('qrActionPrompt')),
          content: Text(l10n.t('qrActionMessage').replaceAll('{product}', matchedItem.product.label(Localizations.localeOf(context).languageCode))),
          actions: [
            if (matchedItem.product.isRefillable)
              TextButton(
                onPressed: () => Navigator.of(context).pop('refill'),
                child: Text(l10n.t('qrActionRefill')),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('replace'),
              child: Text(l10n.t('qrActionReplace')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('btnCancel')),
            ),
          ],
        );
      },
    );

    if (selection == 'refill') {
      if (matchedItem.canRefill) {
        await _performRefillAction(matchedItem);
      } else {
        if (mounted) {
          PremiumSnackbar.show(
            context,
            l10n.t('bottleCannotRefillRecycled'),
            icon: Icons.error_outline_rounded,
          );
        }
      }
    } else if (selection == 'replace') {
      if (matchedItem.status != BottleStatus.recycled) {
        if (mounted) {
          await replaceBottle(context, ref, matchedItem);
        }
      }
    }
  }

  Future<void> _performRefillAction(RoomProduct item) async {
    final percentageEnabled = ref.read(percentageRefillEnabledProvider);
    final int refillPercentage;
    final String notes;

    if (percentageEnabled) {
      final result = await RefillPercentageDialog.show(context, item);
      if (result == null) return; // cancelled or closed
      refillPercentage = result.refillPercentage;
      notes = result.notes;
    } else {
      refillPercentage = 100;
      notes = '';
    }

    final structuredNotes = '[Refill: $refillPercentage%] $notes'.trim();
    final l10n = AppLocalizations.of(context);
    try {
      var isOffline = ref.read(offlineModeProvider);
      if (!isOffline) {
        try {
          await ref.read(repositoryProvider).recordRefill(
                roomProductId: item.id,
                notes: structuredNotes,
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
              payload: {
                'roomProductId': item.id,
                'notes': structuredNotes,
              },
            );
        ref.invalidate(offlineActionsProvider);
      }

      ref.invalidate(roomProductsProvider);
      ref.invalidate(refillEventsProvider);
      ref.invalidate(approvalsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(inventoryProvider);

      if (mounted) {
        PremiumSnackbar.show(
          context,
          isOffline
              ? '${l10n.t('roomsRefillQueued')} ${item.roomNumber}'
              : '${l10n.t('roomsRefillRecorded')} ${item.roomNumber}',
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    }
  }

  void _showAddProductDialog(BuildContext context, List<RoomProduct> currentProducts) {
    showDialog<void>(
      context: context,
      builder: (context) => _AddProductToRoomDialog(
        hotelId: widget.hotelId,
        floorNumber: widget.floorNumber,
        roomNumber: widget.roomNumber,
        existingProductIds: currentProducts.map((p) => p.product.id).toSet(),
      ),
    );
  }

  Future<void> _showEditRoomLocal(BuildContext context) async {
    await showCenteredFormSheet<void>(
      context: context,
      builder: (context) => _RoomEditRequestDialog(
        roomId: widget.roomId,
        roomNumber: widget.roomNumber,
        floorNumber: widget.floorNumber,
        hotelId: widget.hotelId,
      ),
    );
    ref.invalidate(approvalsProvider);
    ref.invalidate(hotelsProvider);
    ref.invalidate(roomsProvider);
    ref.invalidate(roomProductsProvider);
    ref.invalidate(dashboardProvider);
    if (widget.isDialog && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteRoomLocal(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await PremiumConfirmDialog.show(
      context,
      title: l10n.t('delete'),
      message: l10n.tParams('confirmDeleteRoom', {'roomNumber': widget.roomNumber}),
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteRoom(widget.roomId);
        ref.invalidate(roomsProvider);
        ref.invalidate(roomProductsProvider);
        ref.invalidate(dashboardProvider);
        if (widget.isDialog) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          PremiumSnackbar.showError(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProductsAsync = ref.watch(roomProductsProvider);
    final roomProducts = roomProductsAsync.valueOrNull
        ?.where((p) => p.roomId == widget.roomId)
        .toList() ?? widget.roomProducts;

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720 && !widget.isDialog;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final canManageRooms = ref.watch(hasPermissionProvider('manage_rooms')) &&
        (currentUser?.isIvraUser == true || currentUser?.hotelId == selectedHotelId);
    final isHousekeeper = currentUser?.role == UserRole.housekeeper && currentUser?.hotelId == widget.hotelId;
    final canEditRoomProducts = isHousekeeper || canManageRooms;

    var overallStatus = l10n.t('roomsStatusAllOk');
    var overallColor = Colors.orange.shade700;
    var overallIcon = Icons.check_circle_outline;

    final hasCritical = roomProducts.any((item) =>
        item.status == BottleStatus.refillLimitReached ||
        item.status == BottleStatus.tooOld ||
        item.status == BottleStatus.needsReplacement ||
        item.status == BottleStatus.damaged ||
        item.status == BottleStatus.lost);

    final hasWarning = roomProducts
        .any((item) => item.status == BottleStatus.needsRefill);

    if (roomProducts.isEmpty) {
      overallStatus = l10n.t('roomsStatusNoProducts');
      overallColor = Colors.blue.shade600;
      overallIcon = Icons.info_outline;
    } else if (hasCritical) {
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

    final lang = Localizations.localeOf(context).languageCode;
    final displayedProducts = roomProducts.where((item) {
      if (widget.productSearchQuery.isEmpty) return true;
      final name = item.product.label(lang).toLowerCase();
      final sku = item.product.sku.toLowerCase();
      final query = widget.productSearchQuery.toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 28 : 16),
            boxShadow: [
              BoxShadow(
                color: overallColor.withValues(alpha: _isHovered ? 0.3 : 0.0),
                blurRadius: _isHovered ? 20 : 0,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: isMobile ? 28 : 16,
            borderColor: overallColor.withValues(alpha: _isHovered ? 0.6 : 0.2),
            borderWidth: _isHovered ? 2.0 : 1.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 12)
                      .copyWith(left: 16, right: 16),
                  decoration: BoxDecoration(
                    color:
                        overallColor.withValues(alpha: isMobile ? 0.14 : 0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMobile ? 28 : 16),
                      topRight: Radius.circular(isMobile ? 28 : 16),
                    ),
                  ),
                  child: widget.isDialog
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.meeting_room_outlined,
                                    color: overallColor),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.t('roomsLabelRoom')} ${widget.roomNumber}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: l10n.t('qrScanTitle'),
                                  icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                                  color: overallColor,
                                  onPressed: () => _scanCardProductQr(context),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${l10n.t('roomsLabelFloor')} ${widget.floorNumber}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => Navigator.of(context).pop(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: overallColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color:
                                            overallColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(overallIcon,
                                          size: 14, color: overallColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        overallStatus,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: overallColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (canManageRooms) ...[
                                  IconButton(
                                    tooltip: l10n.t('roomsDialogRoomEditTitle'),
                                    icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                                    onPressed: () => _showEditRoomLocal(context),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: l10n.t('delete'),
                                    icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                    onPressed: () => _confirmDeleteRoomLocal(context),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        )
                      : (isMobile
                          ? _MobileRoomHeader(
                              roomNumber: widget.roomNumber,
                              floorNumber: widget.floorNumber,
                              status: overallStatus,
                              statusColor: overallColor,
                              statusIcon: overallIcon,
                              onScanPressed: () => _scanCardProductQr(context),
                              onEdit: canManageRooms ? () => _showEditRoomLocal(context) : null,
                              onDelete: canManageRooms ? () => _confirmDeleteRoomLocal(context) : null,
                            )
                          : Row(
                              children: [
                                Icon(Icons.meeting_room_outlined,
                                    color: overallColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l10n.t('roomsLabelRoom')} ${widget.roomNumber}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: l10n.t('qrScanTitle'),
                                  icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                                  color: overallColor,
                                  onPressed: () => _scanCardProductQr(context),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${l10n.t('roomsLabelFloor')} ${widget.floorNumber}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: overallColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              overallColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(overallIcon,
                                            size: 14, color: overallColor),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            overallStatus,
                                            style:
                                                theme.textTheme.bodySmall?.copyWith(
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
                                if (canManageRooms) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: l10n.t('roomsDialogRoomEditTitle'),
                                    icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                                    onPressed: () => _showEditRoomLocal(context),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: l10n.t('delete'),
                                    icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                    onPressed: () => _confirmDeleteRoomLocal(context),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            )),
                ),
                const Divider(height: 1),
                if (widget.isDialog)
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 14 : 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (displayedProducts.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      l10n.t('roomsNoProducts'),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              else
                                for (int i = 0; i < displayedProducts.length; i++) ...[
                                  if (i > 0) Divider(height: isMobile ? 18 : 24),
                                  _RoomCardProductRow(item: displayedProducts[i]),
                                ],
                              if (canEditRoomProducts) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: const Size(120, 40),
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                    ),
                                    onPressed: () => _showAddProductDialog(context, roomProducts),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(l10n.t('roomsBtnAddProduct')),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (displayedProducts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                l10n.t('roomsNoProducts'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          for (int i = 0; i < displayedProducts.length; i++) ...[
                            if (i > 0) Divider(height: isMobile ? 18 : 24),
                            _RoomCardProductRow(item: displayedProducts[i]),
                          ],
                        if (canEditRoomProducts) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: const Size(120, 40),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              onPressed: () => _showAddProductDialog(context, roomProducts),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.t('roomsBtnAddProduct')),
                            ),
                          ),
                        ],
                      ],
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

class _MobileRoomHeader extends StatelessWidget {
  const _MobileRoomHeader({
    required this.roomNumber,
    required this.floorNumber,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.onScanPressed,
    this.onEdit,
    this.onDelete,
  });

  final String roomNumber;
  final int floorNumber;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onScanPressed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.meeting_room_outlined, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${l10n.t('roomsLabelRoom')} $roomNumber',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.t('qrScanTitle'),
              icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
              color: statusColor,
              onPressed: onScanPressed,
              visualDensity: VisualDensity.compact,
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.t('roomsDialogRoomEditTitle'),
                icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.t('delete'),
                icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RoomHeaderChip(
              icon: Icons.layers_outlined,
              label: '${l10n.t('roomsLabelFloor')} $floorNumber',
              color: theme.colorScheme.primary,
              filled: false,
            ),
            _RoomHeaderChip(
              icon: statusIcon,
              label: status,
              color: statusColor,
              filled: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoomHeaderChip extends StatelessWidget {
  const _RoomHeaderChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.12)
            : theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomsMobileSummary extends StatelessWidget {
  const _RoomsMobileSummary({
    required this.rooms,
    required this.getStatus,
  });

  final List<_RoomGroup> rooms;
  final _RoomOverallStatus Function(List<RoomProduct> products) getStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    var attention = 0;
    var refill = 0;
    var ok = 0;

    for (final room in rooms) {
      switch (getStatus(room.products)) {
        case _RoomOverallStatus.attentionRequired:
          attention++;
        case _RoomOverallStatus.refillNeeded:
          refill++;
        case _RoomOverallStatus.allOk:
          ok++;
        case _RoomOverallStatus.noProducts:
          break;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 28,
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          _RoomsSummaryTile(
            value: rooms.length,
            label: l10n.t('rooms'),
            icon: Icons.meeting_room_outlined,
            color: theme.colorScheme.primary,
          ),
          _RoomsSummaryTile(
            value: attention,
            label: l10n.t('roomsStatusAttentionRequired'),
            icon: Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
          ),
          _RoomsSummaryTile(
            value: refill,
            label: l10n.t('roomsStatusRefillNeeded'),
            icon: Icons.hourglass_empty_rounded,
            color: Colors.orange.shade700,
          ),
          _RoomsSummaryTile(
            value: ok,
            label: l10n.t('roomsStatusAllOk'),
            icon: Icons.check_circle_outline,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }
}

class _RoomsSummaryTile extends StatelessWidget {
  const _RoomsSummaryTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
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
    final canSubmitEditRequests = ref.watch(hasPermissionProvider('submit_edit_requests'));
    final isHousekeeper = currentUser?.role == UserRole.housekeeper && currentUser?.hotelId == item.hotelId;
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final canManageRooms = ref.watch(hasPermissionProvider('manage_rooms')) &&
        (currentUser?.isIvraUser == true || currentUser?.hotelId == selectedHotelId);
    final canEditRoomProducts = isHousekeeper || canManageRooms;

    Future<void> confirmRemoveProduct() async {
      final confirmed = await PremiumConfirmDialog.show(
        context,
        title: l10n.t('delete'),
        message: l10n.tParams('roomsConfirmRemoveProduct', {
          'productName': item.product.label(language),
          'roomNumber': item.roomNumber,
        }),
      );

      if (confirmed && context.mounted) {
        try {
          await ref.read(repositoryProvider).removeProductFromRoom(roomProductId: item.id);
          ref.invalidate(roomProductsProvider);
          ref.invalidate(dashboardProvider);
          ref.invalidate(roomsProvider);

          if (context.mounted) {
            HapticFeedback.mediumImpact();
            PremiumSnackbar.show(
              context,
              l10n.t('roomsProductRemoved'),
              icon: Icons.delete_outline,
            );
          }
        } catch (e) {
          if (context.mounted) {
            PremiumSnackbar.showError(context, e);
          }
        }
      }
    }

    final statusColor = switch (item.status) {
      BottleStatus.refillLimitReached ||
      BottleStatus.tooOld ||
      BottleStatus.needsReplacement ||
      BottleStatus.damaged ||
      BottleStatus.lost =>
        theme.colorScheme.error,
      BottleStatus.needsRefill => Colors.orange.shade700,
      _ => Colors.green.shade700,
    };

    Future<void> performRefill() async {
      final percentageEnabled = ref.read(percentageRefillEnabledProvider);
      final int refillPercentage;
      final String notes;

      if (percentageEnabled) {
        final result = await RefillPercentageDialog.show(context, item);
        if (result == null) return; // cancelled or closed
        refillPercentage = result.refillPercentage;
        notes = result.notes;
      } else {
        refillPercentage = 100;
        notes = '';
      }

      final structuredNotes = '[Refill: $refillPercentage%] $notes'.trim();

      var isOffline = ref.read(offlineModeProvider);
      if (!isOffline) {
        try {
          await ref.read(repositoryProvider).recordRefill(
                roomProductId: item.id,
                notes: structuredNotes,
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
          payload: {
            'roomProductId': item.id,
            'notes': structuredNotes,
          },
        );
        ref.invalidate(offlineActionsProvider);
      }
      ref.invalidate(roomProductsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(refillEventsProvider);
      ref.invalidate(inventoryProvider);
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        PremiumSnackbar.show(
          context,
          isOffline
              ? '${l10n.t('roomsRefillQueued')} ${item.roomNumber}'
              : '${l10n.t('roomsRefillRecorded')} ${item.roomNumber}',
          icon: IvraIcons.refillAction,
        );
      }
    }

    final content = LayoutBuilder(
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
          child: ProductImage(
            imagePath: item.product.imagePath,
            fit: BoxFit.cover,
            iconSize: 20,
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${(item.product.bottleVolumeMl / 1000).toStringAsFixed(0)}L',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
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
            if (item.product.isRefillable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${l10n.t('roomsLabelRefills')}: ${item.refillCount}/${item.product.maxRefillCount}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${l10n.t('roomsLabelAge')}: ${item.bottleAgeDays(DateTime.now())}${l10n.t('roomsLabelDaysUnit')}/${item.product.maxBottleAgeDays}${l10n.t('roomsLabelDaysUnit')}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getLocalizedBottleStatus(context, item.status),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );

        final actions = Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (item.product.isRefillable) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: const Color(0xFF267D65),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                      ),
                      onPressed: item.canRefill ? performRefill : null,
                      icon: const Icon(IvraIcons.refillAction, size: 18),
                      label:
                          Text(l10n.t('roomsBtnRefillBottle'), style: const TextStyle(fontSize: 12)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.t('roomsBtnReplaceBottle'),
                      icon: const Icon(IvraIcons.replaceAction, size: 24),
                      onPressed: item.status == BottleStatus.recycled
                          ? null
                          : () => replaceBottle(context, ref, item),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: const Color(0xFF267D65),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                      ),
                      onPressed: item.status == BottleStatus.recycled
                          ? null
                          : () => replaceBottle(context, ref, item),
                      icon: const Icon(IvraIcons.replaceAction, size: 18),
                      label:
                          Text(l10n.t('roomsBtnReplaceBottle'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.t('roomsBtnHistory'),
                    icon: const Icon(Icons.history_outlined, size: 24),
                    onPressed: () => showRefillHistory(context, ref, item),
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
              ),
            ),
            if (canSubmitEditRequests) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.t('bottleStatusDamaged'),
                icon: const Icon(Icons.report_problem_outlined, size: 20),
                color: theme.colorScheme.error,
                onPressed: () => showMarkDamagedDialog(context, ref, item),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.t('bottleStatusLost'),
                icon: const Icon(Icons.search_off_outlined, size: 20),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: () => showMarkLostDialog(context, ref, item),
              ),
            ],
            if (canEditRoomProducts) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.t('delete'),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: theme.colorScheme.error,
                onPressed: confirmRemoveProduct,
              ),
            ],
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
            Expanded(
              flex: 4,
              child: actions,
            ),
          ],
        );
      },
    );

    if (!item.canRefill) return content;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: ValueKey('refill_${item.id}'),
        direction: DismissDirection.startToEnd,
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF267D65),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              const Icon(IvraIcons.refillAction, size: 28, color: Colors.white),
              const SizedBox(width: 8),
              Text(l10n.t('refill'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.lightImpact();
          await performRefill();
          return false;
        },
        child: content,
      ),
    );
  }
}

class _MarkDamagedDialog extends ConsumerStatefulWidget {
  const _MarkDamagedDialog({required this.item});

  final RoomProduct item;

  @override
  ConsumerState<_MarkDamagedDialog> createState() => _MarkDamagedDialogState();
}

class _MarkDamagedDialogState extends ConsumerState<_MarkDamagedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  XFile? _selectedImage;
  var _isSaving = false;

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context);
    XFile? image;
    try {
      final picker = ImagePicker();
      try {
        image = await picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        image = await picker.pickMedia();
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.show(
          context,
          '${l10n.t('productsImageUploadFailed')} ($e)',
          icon: Icons.error_outline,
          isError: true,
        );
      }
      return;
    }
    if (image == null) return;

    final ext = image.name.split('.').last.toLowerCase();
    final allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowed.contains(ext)) {
      if (mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('productsInvalidImageFormat'),
          icon: Icons.error_outline,
          isError: true,
        );
      }
      return;
    }

    setState(() => _selectedImage = image);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.t('roomsBtnMarkDamaged')} - ${l10n.t('roomsLabelRoom')} ${widget.item.roomNumber}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _isSaving ? null : _pickImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerLow,
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      _selectedImage!.path,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                                      radius: 16,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                        onPressed: () => setState(() => _selectedImage = null),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onSurfaceVariant, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.t('roomsUploadProofAction'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.t('roomsNotesOptional'),
                      hintText: l10n.t('roomsNotesOptional'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.t('btnSubmitRequest')),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final language = Localizations.localeOf(context).languageCode;
      final title = 'Mark damaged - ${widget.item.product.label(language)} in Room ${widget.item.roomNumber}';

      String? imageUrl;
      if (_selectedImage != null) {
        final supabaseEnabled = ref.read(useSupabaseProvider);
        final bytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.name.split('.').last.toLowerCase();
        if (!supabaseEnabled) {
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          imageUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        } else {
          final fileName = 'proofs/${DateTime.now().millisecondsSinceEpoch}.$ext';
          await Supabase.instance.client.storage
              .from('products')
              .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
          imageUrl = Supabase.instance.client.storage
              .from('products')
              .getPublicUrl(fileName);
        }
      }

      final oldData = {
        'status': widget.item.status.value,
        'bottle_started_at': _formatDate(widget.item.bottleStartedAt),
      };
      final newData = {
        'status': BottleStatus.damaged.value,
        'bottle_started_at': _formatDate(widget.item.bottleStartedAt),
        'notes': _notesController.text.trim(),
        if (imageUrl != null) 'proof_photo_url': imageUrl,
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
        PremiumSnackbar.showSuccess(
          context,
          offline
              ? l10n.t('roomsMsgEditRequestQueued')
              : appliedImmediately
                  ? l10n.t('roomsMsgDetailsUpdated')
                  : l10n.t('roomsMsgEditRequestSubmitted'),
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MarkLostDialog extends ConsumerStatefulWidget {
  const _MarkLostDialog({required this.item});

  final RoomProduct item;

  @override
  ConsumerState<_MarkLostDialog> createState() => _MarkLostDialogState();
}

class _MarkLostDialogState extends ConsumerState<_MarkLostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  var _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.t('roomsBtnMarkLost')} - ${l10n.t('roomsLabelRoom')} ${widget.item.roomNumber}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.t('roomsNotesOptional'),
                  hintText: l10n.t('roomsNotesOptional'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.t('btnSubmitRequest')),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final language = Localizations.localeOf(context).languageCode;
      final title = 'Mark lost - ${widget.item.product.label(language)} in Room ${widget.item.roomNumber}';

      final oldData = {
        'status': widget.item.status.value,
        'bottle_started_at': _formatDate(widget.item.bottleStartedAt),
      };
      final newData = {
        'status': BottleStatus.lost.value,
        'bottle_started_at': _formatDate(widget.item.bottleStartedAt),
        'notes': _notesController.text.trim(),
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
        PremiumSnackbar.showSuccess(
          context,
          offline
              ? l10n.t('roomsMsgEditRequestQueued')
              : appliedImmediately
                  ? l10n.t('roomsMsgDetailsUpdated')
                  : l10n.t('roomsMsgEditRequestSubmitted'),
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.t('roomsDialogBottleEditTitle')} ${widget.item.roomNumber}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
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
                          child: Text(_getLocalizedBottleStatus(context, status)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.pending_actions_outlined),
                  label: Text(l10n.t('btnSubmitRequest')),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      final language = Localizations.localeOf(context).languageCode;
      final title = l10n.tParams('roomsEditProductTitle', {
        'productName': widget.item.product.label(language),
        'roomNumber': widget.item.roomNumber,
      });
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
        PremiumSnackbar.showSuccess(context, offline
                  ? l10n.t('roomsMsgEditRequestQueued')
                  : appliedImmediately
                      ? l10n.t('roomsMsgDetailsUpdated')
                      : l10n.t('roomsMsgEditRequestSubmitted'),);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RoomEditRequestDialog extends ConsumerStatefulWidget {
  const _RoomEditRequestDialog({
    required this.roomId,
    required this.roomNumber,
    required this.floorNumber,
    required this.hotelId,
  });

  final String roomId;
  final String roomNumber;
  final int floorNumber;
  final String hotelId;

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
  List<String>? _selectedProductIds;

  @override
  void initState() {
    super.initState();
    _roomNumber = TextEditingController(text: widget.roomNumber);
    _floorNumber = TextEditingController(
      text: widget.floorNumber.toString(),
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
    final language = Localizations.localeOf(context).languageCode;

    final productsAsync = ref.watch(productsProvider);
    final roomProductsAsync = ref.watch(roomProductsProvider);

    final products = productsAsync.valueOrNull ?? [];
    final roomProducts = roomProductsAsync.valueOrNull ?? [];

    if (_selectedProductIds == null && roomProductsAsync.hasValue) {
      _selectedProductIds = roomProducts
          .where((rp) => rp.roomId == widget.roomId)
          .map((rp) => rp.product.id)
          .toList();
    }

    final isLoading = productsAsync.isLoading || roomProductsAsync.isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.t('roomsDialogRoomEditTitle')} ${widget.roomNumber}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _roomNumber,
                    decoration: InputDecoration(
                        labelText: l10n.t('roomsLabelRoomNumber')),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.t('requiredField');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _NumberField(
                    controller: _floorNumber,
                    label: l10n.t('roomsLabelFloorNumber'),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.t('roomsLabelManageProducts'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoading || _selectedProductIds == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No products found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: products.map((product) {
                          final isSelected =
                              _selectedProductIds!.contains(product.id);
                          return FilterChip(
                            label: Text(product.label(language)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedProductIds!.add(product.id);
                                } else {
                                  _selectedProductIds!.remove(product.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.pending_actions_outlined),
                  label: Text(l10n.t('btnSubmitRequest')),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      final roomProducts = ref.read(roomProductsProvider).valueOrNull ?? [];
      final oldProductIds = roomProducts
          .where((rp) => rp.roomId == widget.roomId)
          .map((rp) => rp.product.id)
          .toList();

      final newProductIds = _selectedProductIds ?? oldProductIds;
      final addedProductIds = newProductIds.where((pid) => !oldProductIds.contains(pid)).toList();

      final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
      final products = ref.read(productsProvider).valueOrNull ?? [];
      var needsAutoAdjust = false;

      for (final pid in addedProductIds) {
        final product = products.firstWhere((p) => p.id == pid);
        final stockItem = inventory.firstWhere(
          (stock) => stock.product.id == pid,
          orElse: () => InventoryItem(
            id: '',
            hotelId: widget.hotelId,
            product: product,
            fullBottles: 0,
            emptyBottles: 0,
            fullBidons: 0,
            openBidons: 0,
            emptyBidons: 0,
          ),
        );
        if (stockItem.fullBottles == 0) {
          final language = Localizations.localeOf(context).languageCode;
          final proceed = await _showInsufficientStockDialog(
            context: context,
            productName: product.label(language),
            message: l10n.tParams('inventoryEnforceTemplateContent', {
              'total': '1',
              'product': product.label(language),
              'current': '0',
              'needed': '1',
            }),
          );
          if (proceed != true) {
            setState(() => _isSaving = false);
            return;
          }
          needsAutoAdjust = true;
        }
      }

      final oldData = {
        'room_number': widget.roomNumber,
        'floor_number': widget.floorNumber,
        'product_ids': oldProductIds,
      };
      final newData = {
        'room_number': _roomNumber.text.trim(),
        'floor_number': int.parse(_floorNumber.text),
        'product_ids': newProductIds,
        'auto_adjust_inventory': needsAutoAdjust,
      };
      final offline = ref.read(offlineModeProvider);
      final appliedImmediately = await _submitPendingEditRequest(
        ref: ref,
        hotelId: widget.hotelId,
        title: l10n.tParams('roomsEditRoomTitle', {
          'roomNumber': widget.roomNumber,
        }),
        targetTable: 'rooms',
        targetId: widget.roomId,
        oldData: oldData,
        newData: newData,
      );
      if (mounted) {
        Navigator.of(context).pop();
        PremiumSnackbar.showSuccess(
          context,
          offline
              ? l10n.t('roomsMsgRoomEditQueued')
              : appliedImmediately
                  ? l10n.t('roomsMsgRoomDetailsUpdated')
                  : l10n.t('roomsMsgRoomEditSubmitted'),
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
  final applyImmediately = (currentUser?.isIvraUser == true) ||
      (currentUser?.role == UserRole.hotelManager && currentUser?.hotelId == hotelId);

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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.t('roomsLabelRoom')} ${item.roomNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.product.label(language)} ${l10n.t('roomsDialogHistoryTitle')}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: events.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l10n.t('roomsNoHistoryRecorded')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: events.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final canUndo = event.canUndo(now, currentUser.id);
                        // Events are ordered most-recent-first, so the oldest
                        // event is the last one. A bottle-replaced event that is
                        // the very first event for this product represents the
                        // initial placement (a new bottle was put in the room),
                        // not a replacement of a previous bottle.
                        final isInitialPlacement =
                            event.type == RefillEventType.bottleReplaced &&
                                index == events.length - 1 &&
                                event.previousRefillCount == 0;
                        final isStatusChange = event.type == RefillEventType.bottleReplaced &&
                            event.notes != null &&
                            event.notes!.startsWith('Status changed from ');

                        int? parsedPercentage;
                        String? parsedUserNotes;
                        if (event.notes != null) {
                          if (event.notes!.startsWith('[Refill: ')) {
                            final match = RegExp(r'^\[Refill:\s*(\d+)%\]\s*(.*)$').firstMatch(event.notes!);
                            if (match != null) {
                              parsedPercentage = int.tryParse(match.group(1) ?? '');
                              final rawNotes = match.group(2)?.trim();
                              if (rawNotes != null && rawNotes.isNotEmpty) {
                                parsedUserNotes = rawNotes;
                              }
                            }
                          } else if (!isStatusChange) {
                            parsedUserNotes = event.notes;
                          }
                        }

                        String label = _eventLabel(l10n, event.type, isInitialPlacement);
                        Widget subtitleWidget;

                        if (isStatusChange) {
                          final parts = event.notes!.split(' ');
                          final oldStatusVal = parts.length > 3 ? parts[3] : '';
                          final newStatusVal = parts.length > 5 ? parts[5] : '';
                          final oldStatus = BottleStatus.fromValue(oldStatusVal);
                          final newStatus = BottleStatus.fromValue(newStatusVal);
                          final oldLocalized = _getLocalizedBottleStatus(context, oldStatus);
                          final newLocalized = _getLocalizedBottleStatus(context, newStatus);
                          
                          label = l10n.tParams('roomsHistoryStatusChanged', {
                            'oldValue': oldLocalized,
                            'newValue': newLocalized,
                          });
                        }

                        final performerStr = event.performedByName != null && event.performedByName!.isNotEmpty
                            ? ' | ${event.performedByName}'
                            : '';
                        final subtitleText = isStatusChange
                            ? '${_formatDateTime(event.occurredAt)}$performerStr'
                            : '${_formatDateTime(event.occurredAt)}$performerStr | ${event.previousRefillCount} -> ${event.newRefillCount}';

                        Widget? proofPhotoWidget;
                        if (event.proofPhotoUrl != null && event.proofPhotoUrl!.isNotEmpty) {
                          proofPhotoWidget = Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            InteractiveViewer(
                                              child: Image.network(event.proofPhotoUrl!),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white),
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                              ),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                      image: DecorationImage(
                                        image: NetworkImage(event.proofPhotoUrl!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        subtitleWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(subtitleText),
                            if (parsedUserNotes != null && parsedUserNotes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                parsedUserNotes,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                                    ),
                              ),
                            ],
                            if (proofPhotoWidget != null) proofPhotoWidget,
                          ],
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(isInitialPlacement
                              ? Icons.add_circle_outline
                              : isStatusChange
                                  ? Icons.published_with_changes_outlined
                                  : _eventIcon(event.type)),
                          title: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(label),
                              if (parsedPercentage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '$parsedPercentage%',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: subtitleWidget,
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
                                                .read(
                                                    offlineSyncServiceProvider)
                                                .enqueue(
                                              type: SyncActionType.undoRefill,
                                              payload: {
                                                'refillEventId': event.id
                                              },
                                            );
                                            ref.invalidate(
                                                offlineActionsProvider);
                                          } else {
                                            await ref
                                                .read(repositoryProvider)
                                                .undoRefill(
                                                    refillEventId: event.id);
                                          }
                                          ref.invalidate(roomProductsProvider);
                                          ref.invalidate(refillEventsProvider);
                                          ref.invalidate(approvalsProvider);
                                          ref.invalidate(dashboardProvider);
                                          ref.invalidate(inventoryProvider);
                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  offline
                                                      ? l10n.t(
                                                          'roomsMsgUndoQueued')
                                                      : l10n.t(
                                                          'roomsMsgRefillUndone'),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.t('roomsBtnClose')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _eventLabel(
    AppLocalizations l10n,
    RefillEventType type,
    bool isInitialPlacement,
  ) {
    if (isInitialPlacement) return l10n.t('roomsHistoryNewBottle');
    return switch (type) {
      RefillEventType.refill => l10n.t('roomsHistoryRefill'),
      RefillEventType.undo => l10n.t('undo'),
      RefillEventType.correctionRequested => l10n.t('metricPendingApprovals'),
      RefillEventType.correctionApproved => l10n.t('refillEventApproved'),
      RefillEventType.correctionRejected => l10n.t('refillEventRejected'),
      RefillEventType.bottleReplaced => l10n.t('roomsBtnReplaceBottle'),
    };
  }

  IconData _eventIcon(RefillEventType type) {
    return switch (type) {
      RefillEventType.refill => IvraIcons.refillAction,
      RefillEventType.undo => Icons.undo_outlined,
      RefillEventType.correctionRequested => Icons.assignment_late_outlined,
      RefillEventType.correctionApproved => Icons.task_alt_outlined,
      RefillEventType.correctionRejected => Icons.block_outlined,
      RefillEventType.bottleReplaced => IvraIcons.replaceAction,
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
    await showCenteredFormSheet<void>(
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('roomsBtnRequestCorrection'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.assignment_late_outlined),
                  label: Text(l10n.t('btnSubmitRequest')),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
        PremiumSnackbar.showSuccess(context, offline
                  ? l10n.t('roomsMsgCorrectionQueued')
                  : l10n.t('roomsMsgCorrectionSubmitted'),);
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('roomsTooltipCreateTemplate'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _hotelId,
                        decoration:
                            InputDecoration(labelText: l10n.t('hotels')),
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
                              selected:
                                  _selectedProductIds.contains(product.id),
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.auto_awesome_motion_outlined),
                  label: Text(l10n.t('roomsBtnCreateRooms')),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final firstRoomNumber = int.parse(_firstRoomNumber.text);
    final roomCount = int.parse(_roomCount.text);

    // The template generates sequential room numbers starting at
    // [firstRoomNumber]. Detect collisions with existing rooms in the selected
    // hotel before hitting the backend so the user gets an immediate, clear
    // error instead of a partial/failed bulk create.
    final generatedNumbers = <String>[
      for (var i = 0; i < roomCount; i++) '${firstRoomNumber + i}',
    ];

    setState(() => _isSaving = true);
    try {
      List<RoomInfo> existingRooms;
      try {
        existingRooms =
            await ref.read(repositoryProvider).rooms(hotelId: _hotelId);
      } catch (_) {
        // If we cannot load existing rooms (e.g. offline), skip the client-side
        // duplicate check and let the backend enforce uniqueness.
        existingRooms = const [];
      }

      final existingNumbers = existingRooms
          .where((room) => room.hotelId == _hotelId)
          .map((room) => room.roomNumber.trim())
          .toSet();
      final duplicates = generatedNumbers
          .where(existingNumbers.contains)
          .toList(growable: false);

      if (duplicates.isNotEmpty) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l10n.tParams('roomsMsgDuplicateRoomNumbers',
                    {'numbers': duplicates.join(', ')}),
              ),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
      final products = ref.read(productsProvider).valueOrNull ?? [];
      var needsAutoAdjust = false;
      
      for (final pid in _selectedProductIds) {
        final product = products.firstWhere((p) => p.id == pid);
        final stockItem = inventory.firstWhere(
          (stock) => stock.product.id == pid,
          orElse: () => InventoryItem(
            id: '',
            hotelId: _hotelId,
            product: product,
            fullBottles: 0,
            emptyBottles: 0,
            fullBidons: 0,
            openBidons: 0,
            emptyBidons: 0,
          ),
        );
        if (stockItem.fullBottles < roomCount) {
          final language = Localizations.localeOf(context).languageCode;
          final proceed = await _showInsufficientStockDialog(
            context: context,
            productName: product.label(language),
            message: l10n.tParams('inventoryEnforceTemplateContent', {
              'total': roomCount.toString(),
              'product': product.label(language),
              'current': stockItem.fullBottles.toString(),
              'needed': (roomCount - stockItem.fullBottles).toString(),
            }),
          );
          if (proceed != true) {
            setState(() => _isSaving = false);
            return;
          }
          needsAutoAdjust = true;
        }
      }

      await ref.read(repositoryProvider).createRoomsFromTemplate(
            hotelId: _hotelId,
            floorNumber: int.parse(_floorNumber.text),
            firstRoomNumber: firstRoomNumber,
            roomCount: roomCount,
            productIds: _selectedProductIds.toList(),
            autoAdjustInventory: needsAutoAdjust,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      // Surface the actual backend reason (e.g. "Room count must be between 1
      // and 500") instead of letting the failure propagate as an uncaught
      // error that only shows up as a raw HTTP 400 in the browser console.
      if (mounted) {
        PremiumSnackbar.show(
          context,
          _roomTemplateErrorMessage(error),
          icon: Icons.error_outline,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Extracts a human-readable message from a failed room-template create.
  ///
  /// Postgres RPC validation errors (raised via `raise exception` in
  /// `create_rooms_from_template`) arrive as a [PostgrestException] whose
  /// `message` is the exact reason, e.g. "Room count must be between 1 and
  /// 500". For anything else fall back to the string form.
  String _roomTemplateErrorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }
    return error.toString();
  }
}

class _AddRoomDialog extends ConsumerStatefulWidget {
  const _AddRoomDialog({
    required this.hotelId,
    required this.floorNumber,
    required this.products,
  });

  final String hotelId;
  final int floorNumber;
  final List<Product> products;

  @override
  ConsumerState<_AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends ConsumerState<_AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumber;
  late final Set<String> _selectedProductIds;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _roomNumber = TextEditingController();
    _selectedProductIds =
        widget.products.take(4).map((product) => product.id).toSet();
  }

  @override
  void dispose() {
    _roomNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.t('roomsDialogAddRoomTitle')} ${widget.floorNumber}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _roomNumber,
                        decoration: InputDecoration(
                            labelText: l10n.t('roomsLabelRoomNumber')),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.t('requiredField');
                          }
                          return null;
                        },
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
                              selected:
                                  _selectedProductIds.contains(product.id),
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.add_outlined),
                  label: Text(l10n.t('roomsBtnAddRoom')),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final roomNumber = _roomNumber.text.trim();
    final parsedRoomNumber = int.tryParse(roomNumber);
    if (parsedRoomNumber == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('enterNumberError'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Guard against creating a duplicate room number in the same hotel.
      List<RoomInfo> existingRooms;
      try {
        existingRooms =
            await ref.read(repositoryProvider).rooms(hotelId: widget.hotelId);
      } catch (_) {
        existingRooms = const [];
      }
      final exists = existingRooms.any((room) =>
          room.hotelId == widget.hotelId &&
          room.roomNumber.trim() == roomNumber);
      if (exists) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l10n.tParams(
                    'roomsMsgDuplicateRoomNumbers', {'numbers': roomNumber}),
              ),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
      var needsAutoAdjust = false;
      
      for (final pid in _selectedProductIds) {
        final product = widget.products.firstWhere((p) => p.id == pid);
        final stockItem = inventory.firstWhere(
          (stock) => stock.product.id == pid,
          orElse: () => InventoryItem(
            id: '',
            hotelId: widget.hotelId,
            product: product,
            fullBottles: 0,
            emptyBottles: 0,
            fullBidons: 0,
            openBidons: 0,
            emptyBidons: 0,
          ),
        );
        if (stockItem.fullBottles == 0) {
          final language = Localizations.localeOf(context).languageCode;
          final proceed = await _showInsufficientStockDialog(
            context: context,
            productName: product.label(language),
            message: l10n.tParams('inventoryEnforceTemplateContent', {
              'total': '1',
              'product': product.label(language),
              'current': '0',
              'needed': '1',
            }),
          );
          if (proceed != true) {
            setState(() => _isSaving = false);
            return;
          }
          needsAutoAdjust = true;
        }
      }

      await ref.read(repositoryProvider).createRoomsFromTemplate(
            hotelId: widget.hotelId,
            floorNumber: widget.floorNumber,
            firstRoomNumber: parsedRoomNumber,
            roomCount: 1,
            productIds: _selectedProductIds.toList(),
            autoAdjustInventory: needsAutoAdjust,
          );
      if (mounted) {
        Navigator.of(context).pop();
        PremiumSnackbar.showSuccess(context, l10n.t('roomsMsgRoomAdded'));
      }
    } catch (error) {
      if (mounted) {
        PremiumSnackbar.show(
          context,
          error is PostgrestException ? error.message : error.toString(),
          icon: Icons.error_outline,
          isError: true,
        );
      }
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

class _RoomGroup {
  const _RoomGroup({
    required this.roomInfo,
    required this.products,
  });

  final RoomInfo roomInfo;
  final List<RoomProduct> products;

  String get roomId => roomInfo.id;
  String get roomNumber => roomInfo.roomNumber;
  int get floorNumber => roomInfo.floorNumber;
  String get hotelId => roomInfo.hotelId;
}

String _getLocalizedBottleStatus(BuildContext context, BottleStatus status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    BottleStatus.active => l10n.t('bottleStatusActive'),
    BottleStatus.needsRefill => l10n.t('bottleStatusNeedsRefill'),
    BottleStatus.refilled => l10n.t('bottleStatusRefilled'),
    BottleStatus.refillLimitReached => l10n.t('bottleStatusRefillLimitReached'),
    BottleStatus.tooOld => l10n.t('bottleStatusTooOld'),
    BottleStatus.needsReplacement => l10n.t('bottleStatusNeedsReplacement'),
    BottleStatus.recycled => l10n.t('bottleStatusRecycled'),
    BottleStatus.damaged => l10n.t('bottleStatusDamaged'),
    BottleStatus.lost => l10n.t('bottleStatusLost'),
  };
}
