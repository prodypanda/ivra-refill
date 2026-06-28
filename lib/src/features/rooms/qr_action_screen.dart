import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/product_image.dart';
import '../shared/glass_card.dart';
import '../shared/premium_snackbar.dart';
import '../../ui/ivra_icons.dart';
import 'rooms_screen.dart'; // Reuses exposed dialog functions: showRefillHistory, showMarkDamagedDialog, showMarkLostDialog, replaceBottle

class QrActionScreen extends ConsumerStatefulWidget {
  const QrActionScreen({
    super.key,
    required this.hotelSlugOrId,
    required this.floor,
    required this.room,
    required this.sku,
  });

  final String hotelSlugOrId;
  final String floor;
  final String room;
  final String sku;

  @override
  ConsumerState<QrActionScreen> createState() => _QrActionScreenState();
}

class _QrActionScreenState extends ConsumerState<QrActionScreen> {
  bool _isPerformingAction = false;

  // Helper to normalize string for similarity match
  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final hotelsAsync = ref.watch(hotelsProvider);
    final roomProductsAsync = ref.watch(allRoomProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur background overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: () => context.go('/rooms'),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AsyncValueView<List<Hotel>>(
                value: hotelsAsync,
                onRetry: () => ref.invalidate(hotelsProvider),
                builder: (hotels) {
                  // 1. Resolve Hotel
                  final hotel = hotels.firstWhereOrNull((h) {
                    final normalizedH = _normalize(h.id);
                    final normalizedInput = _normalize(widget.hotelSlugOrId);
                    return normalizedH == normalizedInput ||
                        normalizedH.startsWith(normalizedInput) ||
                        normalizedInput.startsWith(normalizedH) ||
                        _normalize(h.name).contains(normalizedInput);
                  });

                  if (hotel == null) {
                    return _buildErrorCard(
                      context,
                      title: l10n.t('hotelNotFound') ?? 'Hotel Not Found',
                      message: 'Could not match hotel: "${widget.hotelSlugOrId}"',
                    );
                  }

                  // 2. Security Check (Gate hotel access)
                  final isAuthorized = currentUser != null &&
                      (currentUser.isIvraUser == true ||
                          currentUser.role == UserRole.hotelManager ||
                          currentUser.hotelId == hotel.id);

                  return AsyncValueView<List<RoomProduct>>(
                    value: roomProductsAsync,
                    onRetry: () => ref.invalidate(allRoomProductsProvider),
                    builder: (roomProducts) {
                      // 3. Resolve matched RoomProduct
                      final matchedItem = roomProducts.firstWhereOrNull((item) {
                        final floorInt = int.tryParse(widget.floor) ?? -1;
                        return item.hotelId == hotel.id &&
                            item.floorNumber == floorInt &&
                            item.roomNumber.toLowerCase() == widget.room.toLowerCase() &&
                            item.product.sku.toLowerCase() == widget.sku.toLowerCase();
                      });

                      if (matchedItem == null) {
                        return _buildErrorCard(
                          context,
                          title: l10n.t('productNotFound') ?? 'Product Not Found',
                          message: 'Room ${widget.room} (Floor ${widget.floor}) does not contain product SKU: "${widget.sku}"',
                        );
                      }

                      final productName = matchedItem.product.label(language);

                      return Hero(
                        tag: 'qr-overlay-card',
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Scanned Location Banner
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.qr_code_scanner,
                                      color: theme.colorScheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hotel.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Floor ${widget.floor} • Room ${widget.room}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => context.go('/rooms'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: theme.dividerColor),
                              const SizedBox(height: 20),

                              // Product display
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ProductImage(
                                        imagePath: matchedItem.product.imagePath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            matchedItem.product.sku,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          productName,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${matchedItem.product.bottleVolumeMl} ml',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Refills indicator
                              if (matchedItem.product.isRefillable) ...[
                                _buildStatsRow(
                                  context,
                                  label: l10n.t('roomsFillCount') ?? 'Refill Count',
                                  value: '${matchedItem.refillCount} / ${matchedItem.product.maxRefillCount}',
                                  isWarning: matchedItem.status == BottleStatus.refillLimitReached,
                                ),
                                const SizedBox(height: 8),
                              ],
                              _buildStatsRow(
                                context,
                                label: l10n.t('roomsBottleStatus') ?? 'Dispenser Status',
                                value: _getLocalizedStatusName(context, matchedItem.status),
                                isWarning: matchedItem.status == BottleStatus.needsReplacement ||
                                    matchedItem.status == BottleStatus.tooOld ||
                                    matchedItem.status == BottleStatus.refillLimitReached ||
                                    matchedItem.status == BottleStatus.damaged ||
                                    matchedItem.status == BottleStatus.lost,
                              ),
                              const SizedBox(height: 24),

                              // Security Gate Warning Dialog Card
                              if (!isAuthorized) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: theme.colorScheme.error),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.gpp_bad, color: theme.colorScheme.error),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              l10n.t('errorPermissionDenied') ?? 'Access Denied',
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                color: theme.colorScheme.onErrorContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.t('qrAccessDeniedMessage') ??
                                            'You are not authorized to perform actions at this hotel.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Action Buttons
                              if (_isPerformingAction)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                // Primary Action: Refill (Large button)
                                if (matchedItem.product.isRefillable) ...[
                                  FilledButton.icon(
                                    key: const ValueKey('refill_button'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: const Color(0xFF267D65),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: isAuthorized && matchedItem.canRefill
                                        ? () => _executeRefill(context, matchedItem)
                                        : null,
                                    icon: const Icon(IvraIcons.refillAction),
                                    label: Text(
                                      l10n.t('roomsBtnRefillBottle'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Warning Action: Replace (Large button)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(
                                      color: isAuthorized
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.outlineVariant,
                                    ),
                                    foregroundColor: isAuthorized
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: isAuthorized && matchedItem.status != BottleStatus.recycled
                                      ? () => _executeReplacement(context, matchedItem)
                                      : null,
                                  icon: const Icon(IvraIcons.replaceAction),
                                  label: Text(
                                    l10n.t('roomsBtnReplaceBottle'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Row of Small Actions (History, Damaged, Lost)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Small History Button
                                    _buildSmallActionButton(
                                      context,
                                      icon: Icons.history_outlined,
                                      label: l10n.t('roomsBtnHistory') ?? 'History',
                                      isEnabled: isAuthorized,
                                      onPressed: () => showRefillHistory(context, ref, matchedItem),
                                    ),
                                    // Small Damaged Button
                                    _buildSmallActionButton(
                                      context,
                                      icon: Icons.report_problem_outlined,
                                      label: l10n.t('bottleStatusDamaged') ?? 'Damaged',
                                      color: theme.colorScheme.error,
                                      isEnabled: isAuthorized,
                                      onPressed: () => showMarkDamagedDialog(context, ref, matchedItem),
                                    ),
                                    // Small Lost Button
                                    _buildSmallActionButton(
                                      context,
                                      icon: Icons.search_off_outlined,
                                      label: l10n.t('bottleStatusLost') ?? 'Lost',
                                      color: theme.colorScheme.onSurfaceVariant,
                                      isEnabled: isAuthorized,
                                      onPressed: () => showMarkLostDialog(context, ref, matchedItem),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);
    final finalColor = isEnabled ? (color ?? theme.colorScheme.primary) : theme.colorScheme.outlineVariant;

    return Expanded(
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: finalColor.withValues(alpha: 0.5)),
              foregroundColor: finalColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: isEnabled ? onPressed : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: finalColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: finalColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWarning ? theme.colorScheme.error : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Hero(
      tag: 'qr-overlay-error-card',
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/rooms'),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.t('btnBack')),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatusName(BuildContext context, BottleStatus status) {
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

  Future<void> _executeRefill(BuildContext context, RoomProduct item) async {
    setState(() => _isPerformingAction = true);
    final l10n = AppLocalizations.of(context);
    var isOffline = ref.read(offlineModeProvider);

    try {
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

      if (mounted) {
        HapticFeedback.mediumImpact();
        PremiumSnackbar.show(
          context,
          isOffline
              ? '${l10n.t('roomsRefillQueued')} ${item.roomNumber}'
              : '${l10n.t('roomsRefillRecorded')} ${item.roomNumber}',
          icon: IvraIcons.refillAction,
        );
        // Automatically pop back to Rooms Screen after success
        context.go('/rooms');
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isPerformingAction = false);
      }
    }
  }

  Future<void> _executeReplacement(BuildContext context, RoomProduct item) async {
    setState(() => _isPerformingAction = true);
    try {
      // Reuses the exposed replacement helper
      await replaceBottle(context, ref, item);
      if (mounted) {
        context.go('/rooms');
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isPerformingAction = false);
      }
    }
  }
}
