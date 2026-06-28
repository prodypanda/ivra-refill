import 'dart:ui';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  String _selectedProductSku = 'all_products';
  bool _isGeneratingPdf = false;

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
    _initCamera();
  }

  void _initCamera() {
    final bool isTestEnv = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestEnv) {
      return;
    }
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
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
                setState(() {
                  _activeTab = val.first;
                });
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
                          child: MobileScanner(
                            controller: _cameraController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _onCodeScanned(barcode.rawValue!);
                                  break;
                                }
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

  Widget _buildGeneratorForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final hotelsAsync = ref.watch(hotelsProvider);
    final roomProductsAsync = ref.watch(allRoomProductsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
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
                        _selectedProductSku = 'all_products';
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
              _selectedProductSku = 'all_products';
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

            // Get unique products (SKUs)
            final products = hotelProducts
                .map((p) => p.product)
                .toSet()
                .toList()
              ..sort((a, b) => a.sku.compareTo(b.sku));

            // Validate active choices
            if (_selectedRoomNumber != 'all_rooms' && !rooms.contains(_selectedRoomNumber)) {
              _selectedRoomNumber = 'all_rooms';
            }
            if (_selectedProductSku != 'all_products' && !products.any((p) => p.sku == _selectedProductSku)) {
              _selectedProductSku = 'all_products';
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
                        child: Text('Room $r'),
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
                        value: 'all_products',
                        child: Text(l10n.t('qrGenerateAllProducts') ?? 'All Products'),
                      ),
                      for (final p in products)
                        DropdownMenuItem(
                          value: p.sku,
                          child: Text('${p.sku} - ${p.label(language)}'),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedProductSku = val ?? 'all_products';
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ],
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
      final allProducts = ref.read(allRoomProductsProvider).valueOrNull ?? [];
      final hotels = ref.read(hotelsProvider).valueOrNull ?? [];

      final hotel = hotels.firstWhereOrNull((h) => h.id == _selectedHotelId);
      if (hotel == null) {
        throw Exception('Selected hotel not found');
      }

      // Filter products based on selections
      var matchedProducts = allProducts.where((p) => p.hotelId == _selectedHotelId).toList();
      if (_selectedRoomNumber != 'all_rooms') {
        matchedProducts = matchedProducts.where((p) => p.roomNumber == _selectedRoomNumber).toList();
      }
      if (_scope == _QrScope.dispenser && _selectedProductSku != 'all_products') {
        matchedProducts = matchedProducts.where((p) => p.product.sku == _selectedProductSku).toList();
      }

      if (matchedProducts.isEmpty) {
        throw Exception('No rooms or products match your configuration');
      }

      final labelList = <QrCodeLabelData>[];

      if (_scope == _QrScope.room) {
        // Group matched products by unique room
        final uniqueRooms = <String, RoomProduct>{};
        for (final p in matchedProducts) {
          final key = '${p.floorNumber}_${p.roomNumber}';
          uniqueRooms[key] = p;
        }

        for (final item in uniqueRooms.values) {
          labelList.add(QrCodeLabelData(
            hotelName: hotel.name,
            floor: '${item.floorNumber}',
            room: item.roomNumber,
            url: 'https://refill.ivra-cosmetics.com/q/${hotel.id}/${item.floorNumber}/${item.roomNumber}',
          ));
        }
      } else {
        // Dispenser labels - one label per matching RoomProduct
        for (final item in matchedProducts) {
          labelList.add(QrCodeLabelData(
            hotelName: hotel.name,
            floor: '${item.floorNumber}',
            room: item.roomNumber,
            productName: item.product.label(language),
            productSku: item.product.sku,
            url: 'https://refill.ivra-cosmetics.com/q/${hotel.id}/${item.floorNumber}/${item.roomNumber}/IVR-${item.product.sku}',
          ));
        }
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
          final currentUser = ref.watch(currentUserProvider).valueOrNull;
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
                  message: l10n.tParams('qrProductNotFoundMessage', {'room': widget.room, 'floor': widget.floor, 'sku': widget.sku}) ?? 'Room ${widget.room} (Floor ${widget.floor}) does not contain product SKU: "${widget.sku}"',
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

      ref.invalidate(allRoomProductsProvider);
      ref.invalidate(roomProductsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(refillEventsProvider);

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
