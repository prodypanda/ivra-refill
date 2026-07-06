import 'dart:async';
import 'dart:ui';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../shared/shimmer_loading.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/product_image.dart';
import '../shared/glass_card.dart';
import '../shared/premium_snackbar.dart';
import '../shared/refill_percentage_dialog.dart';
import '../../ui/ivra_icons.dart';
import 'rooms_screen.dart'; // Reuses exposed dialog functions: showRefillHistory, showMarkDamagedDialog, showMarkLostDialog, replaceBottle
import '../../services/qr_code_pdf_service.dart';

enum ActionResult { none, success, failure }
enum _QrTab { scan, generate }
enum _QrScope { room, dispenser }

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

class _QrActionScreenState extends ConsumerState<QrActionScreen>
    with SingleTickerProviderStateMixin {
  bool _isPerformingAction = false;
  ActionResult _actionResult = ActionResult.none;
  String? _actionMessage;

  // Tab & Generator States
  _QrTab _activeTab = _QrTab.scan;
  _QrScope _scope = _QrScope.dispenser;
  String? _selectedHotelId;
  String _selectedRoomNumber = 'all_rooms';
  String _selectedProductSku = 'all_room_products';
  bool _isGeneratingPdf = false;

  // Tap-to-scan state fields
  List<Barcode> _detectedBarcodes = [];
  Size? _lastCaptureSize;
  Timer? _clearBarcodesTimer;

  // Scanner Mode State Controllers
  late final AnimationController _scanController;
  late final TextEditingController _inputController;
  MobileScannerController? _cameraController;
  bool _isCameraInitialized = false;

  // Helper to normalize string for similarity match
  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    final isScanMode = widget.hotelSlugOrId.isEmpty ||
        widget.floor.isEmpty ||
        widget.room.isEmpty ||
        widget.sku.isEmpty;

    final bool isTestEnv = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');

    if (isScanMode && !isTestEnv) {
      _scanController.repeat(reverse: true);
    }

    _inputController = TextEditingController();
    if (isScanMode) {
      _initCamera();
    }
  }

  void _initCamera() {
    final bool isTestEnv = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestEnv) {
      return;
    }
    if (_cameraController != null) return;
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void didUpdateWidget(covariant QrActionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasScanMode = oldWidget.hotelSlugOrId.isEmpty ||
        oldWidget.floor.isEmpty ||
        oldWidget.room.isEmpty ||
        oldWidget.sku.isEmpty;

    final isScanMode = widget.hotelSlugOrId.isEmpty ||
        widget.floor.isEmpty ||
        widget.room.isEmpty ||
        widget.sku.isEmpty;

    if (!wasScanMode && isScanMode) {
      // Transitioning back to scanning mode (e.g. from error/action screen via GoRouter)
      setState(() {
        _actionResult = ActionResult.none;
        _actionMessage = null;
        _activeTab = _QrTab.scan;
      });
      _cameraController?.dispose();
      _cameraController = null;
      _initCamera();

      final bool isTestEnv = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTestEnv) {
        _scanController.repeat(reverse: true);
      }
    } else if (wasScanMode && !isScanMode) {
      // Transitioning to action screen
      _scanController.stop();
      _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
        _cameraController = null;
      });
    }
  }

  @override
  void dispose() {
    _clearBarcodesTimer?.cancel();
    _scanController.dispose();
    _inputController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _onCodeScanned(String code) {
    if (code.trim().isEmpty) return;
    HapticFeedback.mediumImpact();

    final normalized = code.trim();
    String? hotelId;
    String? floor;
    String? room;
    String? sku;

    try {
      final uri = Uri.parse(normalized);
      if (uri.path.contains('/q/')) {
        final segments = uri.pathSegments;
        final qIndex = segments.indexOf('q');
        if (qIndex != -1 && segments.length >= qIndex + 4) {
          hotelId = segments[qIndex + 1];
          floor = segments[qIndex + 2];
          room = segments[qIndex + 3];
          if (segments.length > qIndex + 4) {
            sku = segments[qIndex + 4];
          }
        }
      } else if (uri.path.contains('/qr') || uri.path.contains('/app/qr')) {
        hotelId = uri.queryParameters['hId'];
        floor = uri.queryParameters['f'];
        room = uri.queryParameters['r'];
        sku = uri.queryParameters['sku'];
      }
    } catch (_) {
      // Not a valid URL
    }

    // Fallback: Check if it looks like a manual segment paste
    if (hotelId == null && normalized.contains('/')) {
      final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.length >= 3) {
        // Find if any segment is a known product SKU or similar, or just assume format
        hotelId = segments[0];
        floor = segments[1];
        room = segments[2];
        if (segments.length >= 4) {
          sku = segments[3];
        }
      }
    }

    if (hotelId != null && floor != null && room != null) {
      // Clear action state before transition
      setState(() {
        _actionResult = ActionResult.none;
        _actionMessage = null;
      });
      if (sku != null && sku.trim().isNotEmpty) {
        context.go('/q/$hotelId/$floor/$room/$sku');
      } else {
        context.go('/rooms?hotelId=$hotelId&floorNumber=$floor&roomNumber=$room');
      }
    } else {
      PremiumSnackbar.show(
        context,
        'Invalid QR format. Use: /q/hotel/floor/room[/sku]',
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final precisionScanWindow = ref.watch(precisionScanWindowEnabledProvider);
    final tapToScanEnabled = ref.watch(tapToScanEnabledProvider);

    final isScanMode = widget.hotelSlugOrId.isEmpty ||
        widget.floor.isEmpty ||
        widget.room.isEmpty ||
        widget.sku.isEmpty;

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
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isScanMode
                  ? _buildScannerView(context)
                  : _buildActionView(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- Scan Mode UI ---
  Widget _buildScannerView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final precisionScanWindow = ref.watch(precisionScanWindowEnabledProvider);
    final tapToScanEnabled = ref.watch(tapToScanEnabledProvider);
    final language = Localizations.localeOf(context).languageCode;

    // Dynamic mock codes matching the mock repository for testing on desktop
    final List<String> demoQrCodes = [
      'https://ivra-refill.web.app/q/hotel-seaside/1/101/IVR-SHA-1L',
      'https://ivra-refill.web.app/q/hotel-seaside/1/101/IVR-HWA-1L',
      'https://ivra-refill.web.app/q/hotel-seaside/2/205/IVR-GEL-1L',
      'https://ivra-refill.web.app/q/hotel-beachfront/1/101/IVR-SHA-1L',
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _activeTab == _QrTab.scan
                              ? (l10n.t('qrScanTitle') ?? 'Scan QR Code')
                              : (l10n.t('qrGenerateTabGenerate') ?? 'Generate QR Codes'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            // Segmented Tab Selector
            SegmentedButton<_QrTab>(
              segments: [
                ButtonSegment<_QrTab>(
                  value: _QrTab.scan,
                  label: Text(l10n.t('qrGenerateTabScan') ?? 'Scan QR'),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                ButtonSegment<_QrTab>(
                  value: _QrTab.generate,
                  label: Text(l10n.t('qrGenerateTabGenerate') ?? 'Generate'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
              ],
              selected: {_activeTab},
              onSelectionChanged: (val) {
                HapticFeedback.lightImpact();
                final newTab = val.first;
                if (newTab == _QrTab.generate) {
                  _scanController.stop();
                  _cameraController?.dispose();
                  setState(() {
                    _isCameraInitialized = false;
                    _cameraController = null;
                    _activeTab = newTab;
                  });
                } else {
                  setState(() {
                    _activeTab = newTab;
                  });
                  _initCamera();
                  final bool isTestEnv = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
                  if (!isTestEnv) {
                    _scanController.repeat(reverse: true);
                  }
                }
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                selectedForegroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 20),

            // Conditional View Render
            if (_activeTab == _QrTab.scan) ...[
              // Viewfinder Simulator
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      if (!_isCameraInitialized)
                        Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: _cameraController,
                                scanWindow: precisionScanWindow ? const Rect.fromLTWH(0, 0, 240, 240) : null,
                                onDetect: (capture) {
                                  final List<Barcode> barcodes = capture.barcodes;
                                  final sensorSize = capture.size;
                                  if (sensorSize != null) {
                                    _lastCaptureSize = sensorSize;
                                  }

                                  final filtered = barcodes.where((b) => b.rawValue != null).toList();
                                  if (filtered.isEmpty) return;

                                  if (tapToScanEnabled) {
                                    _clearBarcodesTimer?.cancel();
                                    setState(() {
                                      _detectedBarcodes = filtered;
                                    });
                                    _clearBarcodesTimer = Timer(const Duration(milliseconds: 2000), () {
                                      if (mounted) {
                                        setState(() {
                                          _detectedBarcodes = [];
                                        });
                                      }
                                    });
                                  } else {
                                    _onCodeScanned(filtered.first.rawValue!);
                                  }
                                },
                                errorBuilder: (context, error) {
                                  final isPermission = error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied;
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPermission
                                                ? Icons.no_photography_outlined
                                                : Icons.error_outline_rounded,
                                            color: colorScheme.error,
                                            size: 36,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            isPermission
                                                ? (l10n.t('qrCameraPermission') ?? 'Camera permission denied')
                                                : (l10n.t('qrCameraUnavailable') ?? 'Camera unavailable'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (tapToScanEnabled)
                                ..._buildInteractiveBoxes(const Size(240, 240), theme),
                            ],
                          ),
                        ),
                      // Corners
                      const _ViewfinderCorners(),
                      // Laser Scanner Line
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          return Positioned(
                            top: _scanController.value * 240,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary,
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.1),
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (tapToScanEnabled && _detectedBarcodes.length > 1) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.t('qrMultipleDetected') ?? 'Multiple QR codes detected. Tap to select:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _detectedBarcodes.length,
                    itemBuilder: (context, index) {
                      final barcode = _detectedBarcodes[index];
                      final val = barcode.rawValue;
                      if (val == null) return const SizedBox.shrink();

                      // Map label for button
                      String label = '';
                      final uri = Uri.tryParse(val);
                      final products = ref.read(productsProvider).valueOrNull ?? [];
                      if (uri != null) {
                        final segments = uri.pathSegments;
                        if (segments.length >= 5) {
                          final sku = segments.last;
                          final prod = products.firstWhereOrNull((p) => p.sku.toLowerCase() == sku.toLowerCase());
                          label = prod != null ? '${prod.label(language)} ($sku)' : sku;
                        } else if (segments.length >= 4) {
                          label = '${l10n.t('room') ?? 'Room'} ${segments.last}';
                        }
                      }
                      if (label.isEmpty) {
                        label = val.split('/').last;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ActionChip(
                          avatar: Icon(Icons.qr_code_2_rounded, size: 16, color: colorScheme.primary),
                          label: Text(
                            label,
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.7),
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _onCodeScanned(val);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Manual Entry Input
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: l10n.t('qrScanPlaceholder') ?? 'Enter code or URL manually...',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onPressed: () => _onCodeScanned(_inputController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _onCodeScanned,
              ),
              const SizedBox(height: 24),

              // Demo Codes Area
              Text(
                l10n.t('qrDemoCodes') ?? 'Quick scan demo/test codes:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final code in demoQrCodes)
                        ActionChip(
                          avatar: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 14,
                          ),
                          label: Text(
                            _extractDemoLabel(code),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => _onCodeScanned(code),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Generator Panel
              _buildGeneratorForm(context),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInteractiveBoxes(Size widgetSize, ThemeData theme) {
    if (_detectedBarcodes.isEmpty) return [];
    final sensorSize = _lastCaptureSize ?? const Size(1280, 720);
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final products = ref.read(productsProvider).valueOrNull ?? [];

    return _detectedBarcodes.map((barcode) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) return const SizedBox.shrink();

      final corners = barcode.corners;
      if (corners == null || corners.isEmpty) return const SizedBox.shrink();
      double minX = corners[0].dx;
      double minY = corners[0].dy;
      double maxX = corners[0].dx;
      double maxY = corners[0].dy;
      for (final corner in corners) {
        if (corner.dx < minX) minX = corner.dx;
        if (corner.dy < minY) minY = corner.dy;
        if (corner.dx > maxX) maxX = corner.dx;
        if (corner.dy > maxY) maxY = corner.dy;
      }
      final bbox = Rect.fromLTRB(minX, minY, maxX, maxY);

      double sensorWidth = sensorSize.width;
      double sensorHeight = sensorSize.height;
      if (sensorWidth > sensorHeight) {
        sensorWidth = sensorSize.height;
        sensorHeight = sensorSize.width;
      }

      final double scaleX = widgetSize.width / sensorWidth;
      final double scaleY = widgetSize.height / sensorHeight;

      final rect = Rect.fromLTRB(
        bbox.left * scaleX,
        bbox.top * scaleY,
        bbox.right * scaleX,
        bbox.bottom * scaleY,
      );

      final left = rect.left.clamp(0.0, widgetSize.width - 40.0);
      final top = rect.top.clamp(0.0, widgetSize.height - 40.0);
      final width = rect.width.clamp(40.0, widgetSize.width - left);
      final height = rect.height.clamp(40.0, widgetSize.height - top);

      String label = '';
      final uri = Uri.tryParse(rawValue);
      if (uri != null) {
        final segments = uri.pathSegments;
        if (segments.length >= 5) {
          final sku = segments.last;
          final prod = products.firstWhereOrNull((p) => p.sku.toLowerCase() == sku.toLowerCase());
          label = prod != null ? prod.label(language) : sku;
        } else if (segments.length >= 4) {
          label = '${l10n.t('room') ?? 'Room'} ${segments.last}';
        }
      }
      if (label.isEmpty) {
        label = rawValue.split('/').last;
      }

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _onCodeScanned(rawValue);
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: -24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGeneratorForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final hotelsAsync = ref.watch(hotelsProvider);
    final roomProductsAsync = ref.watch(allRoomProductsProvider);
    final currentUser = ref.watch(currentUserProvider.select((s) => s.valueOrNull));
    final isSpecialUser = currentUser?.role == UserRole.appAdmin || currentUser?.role == UserRole.appManager;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hotel Selector
        AsyncValueView<List<Hotel>>(
          value: hotelsAsync,
          onRetry: () => ref.invalidate(hotelsProvider),
          builder: (hotels) {
            // Set initial selected hotel ID if not set or invalid
            if (_selectedHotelId == null || !hotels.any((h) => h.id == _selectedHotelId)) {
              if (currentUser != null && !isSpecialUser && currentUser.hotelId != null) {
                _selectedHotelId = currentUser.hotelId;
              } else if (hotels.isNotEmpty) {
                _selectedHotelId = hotels.first.id;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('qrGenerateHotel') ?? 'Hotel',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (isSpecialUser)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedHotelId,
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      for (final h in hotels)
                        DropdownMenuItem(
                          value: h.id,
                          child: Text(h.name),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedHotelId = val;
                        _selectedRoomNumber = 'all_rooms';
                        _selectedProductSku = 'all_room_products';
                      });
                    },
                  )
                else
                  // For managers/staff, display non-editable card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      hotels.firstWhere((h) => h.id == _selectedHotelId, orElse: () => hotels.first).name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // QR Label Scope Selector
        Text(
          l10n.t('qrGenerateScope') ?? 'QR Label Type',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<_QrScope>(
          segments: [
            ButtonSegment<_QrScope>(
              value: _QrScope.room,
              label: Text(l10n.t('qrGenerateScopeRoom') ?? 'Room Door (No SKU)'),
              icon: const Icon(Icons.meeting_room_outlined),
            ),
            ButtonSegment<_QrScope>(
              value: _QrScope.dispenser,
              label: Text(l10n.t('qrGenerateScopeDispenser') ?? 'Dispenser (With SKU)'),
              icon: const Icon(Icons.sanitizer_outlined),
            ),
          ],
          selected: {_scope},
          onSelectionChanged: (val) {
            HapticFeedback.lightImpact();
            setState(() {
              _scope = val.first;
              _selectedRoomNumber = 'all_rooms';
              _selectedProductSku = 'all_room_products';
            });
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            selectedForegroundColor: colorScheme.primary,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 16),

        // Dynamic Room & Product inputs based on allRoomProductsProvider
        AsyncValueView<List<RoomProduct>>(
          value: roomProductsAsync,
          onRetry: () => ref.invalidate(allRoomProductsProvider),
          builder: (allProducts) {
            final hotelProducts = allProducts.where((p) => p.hotelId == _selectedHotelId).toList();

            // Get unique room numbers
            final rooms = hotelProducts
                .map((p) => p.roomNumber)
                .toSet()
                .toList()
              ..sort((a, b) {
                final na = int.tryParse(a);
                final nb = int.tryParse(b);
                if (na != null && nb != null) return na.compareTo(nb);
                return a.compareTo(b);
              });

            final productsAsync = ref.watch(productsProvider);
            return AsyncValueView<List<Product>>(
              value: productsAsync,
              onRetry: () => ref.invalidate(productsProvider),
              builder: (masterProducts) {
                final sortedMasterProducts = masterProducts.toList()..sort((a, b) => a.sku.compareTo(b.sku));

                // Validate active choices
                if (_selectedRoomNumber != 'all_rooms' && !rooms.contains(_selectedRoomNumber)) {
                  _selectedRoomNumber = 'all_rooms';
                }
                if (_selectedProductSku != 'all_room_products' &&
                    _selectedProductSku != 'all_inventory_products' &&
                    !sortedMasterProducts.any((p) => p.sku == _selectedProductSku)) {
                  _selectedProductSku = 'all_room_products';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Room Selector
                    Text(
                      l10n.t('qrGenerateRoom') ?? 'Room',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedRoomNumber,
                      borderRadius: BorderRadius.circular(16),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all_rooms',
                          child: Text(l10n.t('qrGenerateAllRooms') ?? 'All Rooms'),
                        ),
                        for (final r in rooms)
                          DropdownMenuItem(
                            value: r,
                            child: Text(l10n.tParams('roomNumberLabel', {'number': r.toString()})),
                          ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedRoomNumber = val ?? 'all_rooms';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Selector (Only if scope is dispenser)
                    if (_scope == _QrScope.dispenser) ...[
                      Text(
                        l10n.t('qrGenerateProduct') ?? 'Product',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedProductSku,
                        borderRadius: BorderRadius.circular(16),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all_room_products',
                            child: Text(l10n.t('qrGenAllRoomProducts') ?? 'All products in the selected room'),
                          ),
                          DropdownMenuItem(
                            value: 'all_inventory_products',
                            child: Text(l10n.t('qrGenAllInventoryProducts') ?? 'All products in the inventory'),
                          ),
                          for (final p in sortedMasterProducts)
                            DropdownMenuItem(
                              value: p.sku,
                              child: Text(l10n.tParams('productSkuLabelReverse', {'sku': p.sku, 'label': p.label(language)})),
                            ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedProductSku = val ?? 'all_room_products';
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                );
              },
            );
          },
        ),

        // Generate & Download Button
        _isGeneratingPdf
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(),
                ),
              )
            : FilledButton.icon(
                onPressed: () => _handlePdfGeneration(context),
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  l10n.t('qrGenerateBtnDownload') ?? 'Generate & Download PDF',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
      ],
    );
  }

  Future<void> _handlePdfGeneration(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    try {
      final allRoomProducts = ref.read(allRoomProductsProvider).valueOrNull ?? [];
      final hotels = ref.read(hotelsProvider).valueOrNull ?? [];
      final masterProducts = ref.read(productsProvider).valueOrNull ?? [];

      final hotel = hotels.firstWhereOrNull((h) => h.id == _selectedHotelId);
      if (hotel == null) {
        throw Exception('Selected hotel not found');
      }

      final hotelProducts = allRoomProducts.where((p) => p.hotelId == _selectedHotelId).toList();

      // Get unique rooms in the hotel with their floor numbers
      final uniqueRoomsMap = <String, int>{}; // roomNumber -> floorNumber
      for (final p in hotelProducts) {
        uniqueRoomsMap[p.roomNumber] = p.floorNumber;
      }

      // Filter rooms list to process
      final roomsToProcess = <String>[];
      if (_selectedRoomNumber != 'all_rooms') {
        roomsToProcess.add(_selectedRoomNumber);
        // Ensure we have a floor number mapped; fallback to 1
        if (!uniqueRoomsMap.containsKey(_selectedRoomNumber)) {
          uniqueRoomsMap[_selectedRoomNumber] = 1;
        }
      } else {
        roomsToProcess.addAll(uniqueRoomsMap.keys);
      }

      final labelList = <QrCodeLabelData>[];

      if (_scope == _QrScope.room) {
        // Room Door QR (No SKU)
        for (final roomNum in roomsToProcess) {
          final floorNum = uniqueRoomsMap[roomNum] ?? 1;
          labelList.add(QrCodeLabelData(
            hotelName: hotel.name,
            floor: '$floorNum',
            room: roomNum,
            url: 'https://refill.ivra-cosmetics.com/q/${hotel.id}/$floorNum/$roomNum',
          ));
        }
      } else {
        // Dispenser scope (with SKU)
        if (_selectedProductSku == 'all_room_products') {
          // Only generate for products already placed in the selected room(s)
          for (final item in hotelProducts) {
            if (_selectedRoomNumber == 'all_rooms' || item.roomNumber == _selectedRoomNumber) {
              labelList.add(QrCodeLabelData(
                hotelName: hotel.name,
                floor: '${item.floorNumber}',
                room: item.roomNumber,
                productName: item.product.label(language),
                productSku: item.product.sku,
                url: 'https://refill.ivra-cosmetics.com/q/${hotel.id}/${item.floorNumber}/${item.roomNumber}/${item.product.sku.toUpperCase().startsWith('IVR-') ? item.product.sku : 'IVR-${item.product.sku}'}',
              ));
            }
          }
        } else if (_selectedProductSku == 'all_inventory_products') {
          // Generate for ALL master products in the selected room(s)
          for (final roomNum in roomsToProcess) {
            final floorNum = uniqueRoomsMap[roomNum] ?? 1;
            for (final p in masterProducts) {
              labelList.add(QrCodeLabelData(
                hotelName: hotel.name,
                floor: '$floorNum',
                room: roomNum,
                productName: p.label(language),
                productSku: p.sku,
                url: 'https://refill.ivra-cosmetics.com/q/${hotel.id}/$floorNum/$roomNum/${p.sku.toUpperCase().startsWith('IVR-') ? p.sku : 'IVR-${p.sku}'}',
              ));
            }
          }
        } else {
          // Specific SKU selected
          final selectedProd = masterProducts.firstWhereOrNull((p) => p.sku == _selectedProductSku);
          if (selectedProd == null) {
            throw Exception('Selected product SKU not found in catalog');
          }
          for (final roomNum in roomsToProcess) {
            final floorNum = uniqueRoomsMap[roomNum] ?? 1;
            labelList.add(QrCodeLabelData(
              hotelName: hotel.name,
              floor: '$floorNum',
              room: roomNum,
              productName: selectedProd.label(language),
              productSku: selectedProd.sku,
              url: 'https://refill.ivra-cosmetics.com/q/${hotel.id}/$floorNum/$roomNum/${selectedProd.sku.toUpperCase().startsWith('IVR-') ? selectedProd.sku : 'IVR-${selectedProd.sku}'}',
            ));
          }
        }
      }

      if (labelList.isEmpty) {
        throw Exception('No rooms or products match your configuration');
      }

      // Sort labels by floor then room for printing convenience
      labelList.sort((a, b) {
        final fa = int.tryParse(a.floor) ?? 0;
        final fb = int.tryParse(b.floor) ?? 0;
        if (fa != fb) return fa.compareTo(fb);

        final ra = int.tryParse(a.room) ?? 0;
        final rb = int.tryParse(b.room) ?? 0;
        if (ra != rb) return ra.compareTo(rb);
        return a.room.compareTo(b.room);
      });

      // Generate PDF
      final pdfService = ref.read(qrCodePdfServiceProvider);
      final pdfBytes = await pdfService.generateQrPdf(
        labels: labelList,
        languageCode: language,
      );

      // Trigger download
      final fileName = 'ivra-qr-codes-${_normalize(hotel.name)}-${_scope.name}.pdf';
      await ref.read(exportFileServiceProvider).saveBytes(
            fileName: fileName,
            bytes: pdfBytes,
            mimeType: 'application/pdf',
          );

      if (mounted) {
        PremiumSnackbar.show(
          context,
          l10n.t('qrGenerateSuccess') ?? 'PDF generated and downloaded successfully',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  String _extractDemoLabel(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final qIndex = segments.indexOf('q');
      if (qIndex != -1 && segments.length > qIndex + 4) {
        final hotel = segments[qIndex + 1].replaceAll('hotel-', '').toUpperCase();
        final room = segments[qIndex + 3];
        final sku = segments[qIndex + 4].replaceAll('IVR-', '');
        return '$hotel R$room • $sku';
      }
    } catch (_) {}
    return url;
  }

  // --- Action View UI (Matched product) ---
  Widget _buildActionView(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hotelsAsync = ref.watch(hotelsProvider);
    final roomProductsAsync = ref.watch(allRoomProductsProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
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
              message: l10n.tParams('qrHotelNotFoundMessage', {'hotel': widget.hotelSlugOrId}) ?? 'Could not match hotel: "${widget.hotelSlugOrId}"',
            );
          }

          // 2. Security Check (Gate hotel access)
          final currentUser = ref.watch(currentUserProvider.select((s) => s.valueOrNull));
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
                // Scan & Assign: product not in room, offer to assign it
                return _buildScanAssignCard(
                  context,
                  hotel: hotel,
                  floor: widget.floor,
                  room: widget.room,
                  sku: widget.sku,
                  language: language,
                );
              }

              // 4. Render based on Action Results
              if (_actionResult != ActionResult.none) {
                return _buildResultCard(context, matchedItem);
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
                      // Location Banner
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
                                  l10n.tParams('qrFloorRoom', {'floor': widget.floor, 'room': widget.room}) ?? 'Floor ${widget.floor} \u2022 Room ${widget.room}',
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
                        value: _getStatusText(context, matchedItem),
                        isWarning: matchedItem.status == BottleStatus.needsReplacement ||
                            matchedItem.status == BottleStatus.tooOld ||
                            matchedItem.status == BottleStatus.refillLimitReached ||
                            matchedItem.status == BottleStatus.damaged ||
                            matchedItem.status == BottleStatus.lost,
                      ),
                      const SizedBox(height: 24),

                      // Security warning card
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
                        // Primary Actions
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
                              l10n.t('roomsBtnRefillBottle') ?? 'Refill bottle',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        OutlinedButton.icon(
                          key: const ValueKey('replace_button'),
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
                            l10n.t('roomsBtnReplaceBottle') ?? 'Replace bottle',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sub Action Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSmallActionButton(
                              context,
                              icon: Icons.history_outlined,
                              label: l10n.t('roomsBtnHistory') ?? 'History',
                              isEnabled: isAuthorized,
                              onPressed: () => showRefillHistory(context, ref, matchedItem),
                            ),
                            _buildSmallActionButton(
                              context,
                              icon: Icons.report_problem_outlined,
                              label: l10n.t('bottleStatusDamaged') ?? 'Damaged',
                              color: theme.colorScheme.error,
                              isEnabled: isAuthorized && matchedItem.status != BottleStatus.damaged && matchedItem.status != BottleStatus.lost,
                              onPressed: () => showMarkDamagedDialog(context, ref, matchedItem),
                            ),
                            _buildSmallActionButton(
                              context,
                              icon: Icons.search_off_outlined,
                              label: l10n.t('bottleStatusLost') ?? 'Lost',
                              color: theme.colorScheme.onSurfaceVariant,
                              isEnabled: isAuthorized && matchedItem.status != BottleStatus.lost && matchedItem.status != BottleStatus.damaged,
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
    );
  }

  // --- Result View UI ---
  Widget _buildResultCard(BuildContext context, RoomProduct updatedItem) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final isSuccess = _actionResult == ActionResult.success;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result Status Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFF267D65).withValues(alpha: 0.15)
                        : colorScheme.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSuccess ? const Color(0xFF267D65) : colorScheme.error,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    color: isSuccess ? const Color(0xFF267D65) : colorScheme.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSuccess ? (l10n.t('qrActionSuccess') ?? 'Action Successful') : (l10n.t('qrActionFailed') ?? 'Action Failed'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? const Color(0xFF267D65) : colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _actionMessage ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),

          // Updated Product Summary
          Text(
            l10n.t('qrUpdatedStatus') ?? 'Updated Dispenser Status:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: ProductImage(
                          imagePath: updatedItem.product.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            updatedItem.product.label(language),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.tParams('qrRoomFloor', {'room': updatedItem.roomNumber, 'floor': '${updatedItem.floorNumber}'}) ?? 'Room ${updatedItem.roomNumber} \u2022 Floor ${updatedItem.floorNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (updatedItem.product.isRefillable) ...[
                  _buildStatsRow(
                    context,
                    label: l10n.t('roomsFillCount') ?? 'Refill Count',
                    value: '${updatedItem.refillCount} / ${updatedItem.product.maxRefillCount}',
                    isWarning: updatedItem.status == BottleStatus.refillLimitReached,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildStatsRow(
                  context,
                  label: l10n.t('roomsBottleStatus') ?? 'Dispenser Status',
                  value: _getStatusText(context, updatedItem),
                  isWarning: updatedItem.status == BottleStatus.needsReplacement ||
                      updatedItem.status == BottleStatus.tooOld ||
                      updatedItem.status == BottleStatus.refillLimitReached,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Next Action Buttons
          FilledButton.icon(
            key: const ValueKey('scan_another_button'),
            onPressed: () => context.go('/qr'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              l10n.t('qrScanAnother') ?? 'Scan another QR code',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/rooms'),
            icon: const Icon(Icons.dashboard_outlined),
            label: Text(
              l10n.t('qrReturnRooms') ?? 'Return to rooms',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Subcomponents & Helpers ---
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
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWarning ? theme.colorScheme.error : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // --- Scan & Assign Flow ---

  Widget _buildScanAssignCard(
    BuildContext context, {
    required Hotel hotel,
    required String floor,
    required String room,
    required String sku,
    required String language,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final inventoryAsync = ref.watch(inventoryProvider);
    final productsAsync = ref.watch(productsProvider);

    // If action result already set (from a completed assign), show the result card
    if (_actionResult != ActionResult.none) {
      final isSuccess = _actionResult == ActionResult.success;
      return Hero(
        tag: 'qr-overlay-assign-result',
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: isSuccess ? Colors.green : colorScheme.error,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isSuccess
                          ? (l10n.t('scanAssignSuccess') ?? 'Product Assigned Successfully')
                          : (l10n.t('scanAssignFailed') ?? 'Assignment Failed'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green : colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              if (_actionMessage != null) ...[
                const SizedBox(height: 12),
                Text(_actionMessage!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go('/qr'),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(l10n.t('qrTryScanAgain') ?? 'Scan another'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/rooms?hotelId=${hotel.id}&floorNumber=$floor&roomNumber=$room'),
                icon: const Icon(Icons.meeting_room_rounded),
                label: Text(l10n.t('goToRoom') ?? 'Go to Room'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return productsAsync.when(
      loading: () => Padding(padding: EdgeInsets.all(16.0), child: ShimmerLoading(width: double.infinity, height: 100)),
      error: (e, _) => _buildErrorCard(
        context,
        title: l10n.t('errorLoadingProducts') ?? 'Error',
        message: e.toString(),
      ),
      data: (products) {
        final product = products.firstWhereOrNull(
          (p) => p.sku.toLowerCase() == sku.toLowerCase(),
        );

        if (product == null) {
          return _buildErrorCard(
            context,
            title: l10n.t('productNotFound') ?? 'Product Not Found',
            message: l10n.tParams('qrUnknownSku', {'sku': sku}) ??
                'SKU "$sku" does not match any known product.',
          );
        }

        final productName = product.label(language);

        return inventoryAsync.when(
          loading: () => Padding(padding: EdgeInsets.all(16.0), child: ShimmerLoading(width: double.infinity, height: 100)),
          error: (e, _) => _buildErrorCard(
            context,
            title: l10n.t('errorLoadingInventory') ?? 'Error',
            message: e.toString(),
          ),
          data: (inventoryItems) {
            final inventoryItem = inventoryItems.firstWhereOrNull(
              (i) => i.hotelId == hotel.id && i.product.sku.toLowerCase() == sku.toLowerCase(),
            );
            final stock = inventoryItem?.fullBottles ?? 0;
            final hasStock = stock > 0;

            return Hero(
              tag: 'qr-overlay-assign-card',
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: colorScheme.onTertiaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.t('scanAssignTitle') ?? 'Assign Product to Room',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.hotel_rounded, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${hotel.name} · ${l10n.t('floor') ?? 'Floor'} $floor · ${l10n.t('room') ?? 'Room'} $room',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Product info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: ProductImage(imagePath: product.imagePath),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SKU: ${product.sku}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inventory Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasStock
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasStock ? Icons.inventory_2_rounded : Icons.warning_amber_rounded,
                            size: 18,
                            color: hasStock ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasStock
                                  ? (l10n.tParams('scanAssignInStock', {'count': stock.toString()}) ??
                                      '$stock in stock — will deduct 1 and assign to room')
                                  : (l10n.t('scanAssignOutOfStock') ??
                                      'Out of stock — 1 unit will be auto-added to inventory then assigned'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: hasStock ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      l10n.t('scanAssignDescription') ??
                          'This product is not yet assigned to this room. Tap below to assign it.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    if (_isPerformingAction)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (hasStock)
                        FilledButton.icon(
                          onPressed: () => _executeScanAssign(
                            hotelId: hotel.id,
                            floor: floor,
                            room: room,
                            productSku: sku,
                            autoAdjustInventory: false,
                          ),
                          icon: const Icon(Icons.add_task_rounded),
                          label: Text(l10n.t('scanAssignButton') ?? 'Assign to Room'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _showAutoAddConfirmation(
                            hotelId: hotel.id,
                            floor: floor,
                            room: room,
                            productSku: sku,
                            productName: productName,
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(l10n.t('scanAssignAutoAdd') ?? 'Add to Inventory & Assign'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/qr'),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(l10n.t('qrTryScanAgain') ?? 'Scan another'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAutoAddConfirmation({
    required String hotelId,
    required String floor,
    required String room,
    required String productSku,
    required String productName,
  }) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.tertiary, size: 36),
        title: Text(l10n.t('scanAssignAutoAddTitle') ?? 'Add to Inventory?'),
        content: Text(
          l10n.tParams('scanAssignAutoAddMessage', {'product': productName}) ??
              'Product "$productName" is out of stock. Would you like to automatically add 1 unit to inventory and assign it to this room?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('btnCancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('scanAssignConfirm') ?? 'Yes, add & assign'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _executeScanAssign(
        hotelId: hotelId,
        floor: floor,
        room: room,
        productSku: productSku,
        autoAdjustInventory: true,
      );
    }
  }

  Future<void> _executeScanAssign({
    required String hotelId,
    required String floor,
    required String room,
    required String productSku,
    required bool autoAdjustInventory,
  }) async {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final isHousekeeper = currentUser?.role == UserRole.housekeeper;
    var effectiveAutoAdjust = autoAdjustInventory;

    // Housekeepers place products from their own cart. If the product is not
    // in the cart, offer to transfer 1 full bottle from the hotel inventory
    // to the cart first; if the hotel has none either, block and notify.
    if (isHousekeeper) {
      try {
        final products = await ref.read(productsProvider.future);
        final selectedProduct = products.firstWhereOrNull((p) => p.sku == productSku);
        if (selectedProduct == null) {
          throw StateError('Unknown product SKU: $productSku');
        }
        final language = mounted ? Localizations.localeOf(context).languageCode : 'en';
        final productName = selectedProduct.label(language);

        final allocations = await ref.read(housekeeperAllocationsProvider.future);
        final allocation = allocations.firstWhereOrNull(
          (a) => a.product.id == selectedProduct.id,
        );
        final cartBottles = allocation?.fullBottles ?? 0;

        if (cartBottles <= 0) {
          final inventory = await ref.read(inventoryProvider.future);
          final hotelStockItem = inventory.firstWhereOrNull(
            (stock) => stock.product.id == selectedProduct.id,
          );
          final hotelBottles = hotelStockItem?.fullBottles ?? 0;

          if (hotelBottles > 0) {
            if (!mounted) return;
            final proceed = await showHousekeeperStockDialog(
              context: context,
              message: l10n.tParams('housekeeperAddGetFromHotel', {
                'product': productName,
                'room': room,
                'count': hotelBottles.toString(),
              }),
              showProceedAction: true,
            );
            if (proceed != true) return;

            await ref.read(repositoryProvider).checkoutHousekeeperStock(
                  housekeeperId: currentUser!.id,
                  productId: selectedProduct.id,
                  fullBottles: 1,
                  fullBidons: 0,
                );
          } else {
            if (!mounted) return;
            await showHousekeeperStockDialog(
              context: context,
              message: l10n.tParams('housekeeperAddNotifyManager', {
                'product': productName,
                'room': room,
              }),
              showProceedAction: false,
            );
            return;
          }
        }
        // Placement always comes from the housekeeper cart, never directly
        // from the hotel inventory.
        effectiveAutoAdjust = false;
      } catch (e) {
        if (mounted) {
          setState(() {
            _actionResult = ActionResult.failure;
            _actionMessage = e.toString();
          });
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isPerformingAction = true);
    try {
      await ref.read(repositoryProvider).addProductToRoom(
            hotelId: hotelId,
            floor: floor,
            roomNumber: room,
            productSku: productSku,
            autoAdjustInventory: effectiveAutoAdjust,
            deductFromHousekeeperId: isHousekeeper ? currentUser?.id : null,
          );

      ref.invalidate(allRoomProductsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(housekeeperAllocationsProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _actionResult = ActionResult.success;
          _actionMessage = l10n.tParams('scanAssignSuccessMessage', {
                'product': productSku,
                'room': room,
                'floor': floor,
              }) ??
              'Product $productSku has been assigned to Room $room (Floor $floor).';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionResult = ActionResult.failure;
          _actionMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPerformingAction = false);
      }
    }
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/qr'),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(l10n.t('qrTryScanAgain') ?? 'Try scanning again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/rooms'),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.t('btnBack') ?? 'Back'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatusName(BuildContext context, BottleStatus status) {
    final l10n = AppLocalizations.of(context);
    return switch (status) {
      BottleStatus.active => l10n.t('bottleStatusActive') ?? 'Active',
      BottleStatus.needsRefill => l10n.t('bottleStatusNeedsRefill') ?? 'Needs Refill',
      BottleStatus.refilled => l10n.t('bottleStatusRefilled') ?? 'Refilled',
      BottleStatus.refillLimitReached => l10n.t('bottleStatusRefillLimitReached') ?? 'Refill Limit Reached',
      BottleStatus.tooOld => l10n.t('bottleStatusTooOld') ?? 'Too Old',
      BottleStatus.needsReplacement => l10n.t('bottleStatusNeedsReplacement') ?? 'Needs Replacement',
      BottleStatus.recycled => l10n.t('bottleStatusRecycled') ?? 'Recycled',
      BottleStatus.damaged => l10n.t('bottleStatusDamaged') ?? 'Damaged',
      BottleStatus.lost => l10n.t('bottleStatusLost') ?? 'Lost',
    };
  }

  String _getStatusText(BuildContext context, RoomProduct item) {
    final statusText = _getLocalizedStatusName(context, item.status);
    if (item.status == BottleStatus.refilled && item.lastRefillAt != null) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.lastRefillAt!.toLocal());
      return '$statusText ($dateStr)';
    }
    return statusText;
  }

  Future<void> _executeRefill(BuildContext context, RoomProduct item) async {
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

    // Housekeepers use their own cart stock first; if empty, they are asked
    // to transfer a bidon from the hotel inventory to their cart before refilling.
    if (!mounted) return;
    final canProceed = await checkAndCheckoutHousekeeperRefillStock(context, ref, item);
    if (!canProceed) return;
    if (!mounted) return;

    setState(() => _isPerformingAction = true);
    final l10n = AppLocalizations.of(context);
    var isOffline = ref.read(offlineModeProvider);
    final structuredNotes = '[Refill: $refillPercentage%] $notes'.trim();

    try {
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

      ref.invalidate(allRoomProductsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(refillEventsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(housekeeperAllocationsProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _actionResult = ActionResult.success;
          _actionMessage = isOffline
              ? '${l10n.t('roomsRefillQueued') ?? 'Refill queued'} ${item.roomNumber}'
              : '${l10n.t('roomsRefillRecorded') ?? 'Refill recorded'} ${item.roomNumber}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionResult = ActionResult.failure;
          _actionMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPerformingAction = false);
      }
    }
  }

  Future<void> _executeReplacement(BuildContext context, RoomProduct item) async {
    setState(() => _isPerformingAction = true);
    final l10n = AppLocalizations.of(context);
    try {
      await replaceBottle(context, ref, item);
      ref.invalidate(allRoomProductsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(refillEventsProvider);

      if (mounted) {
        setState(() {
          _actionResult = ActionResult.success;
          _actionMessage = '${l10n.t('roomsReplacementRecorded') ?? 'Replacement recorded'} ${item.roomNumber}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionResult = ActionResult.failure;
          _actionMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPerformingAction = false);
      }
    }
  }
}

class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    const size = 16.0;
    const thickness = 3.0;

    return Stack(
      children: [
        // Top-Left
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Top-Right
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Bottom-Left
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
        // Bottom-Right
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
