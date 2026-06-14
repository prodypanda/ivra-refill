import 'dart:ui';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../l10n/app_localizations.dart';

class PremiumQrScannerDialog extends StatefulWidget {
  const PremiumQrScannerDialog({
    super.key,
    required this.demoCodes,
  });

  final List<String> demoCodes;

  static Future<String?> show(
    BuildContext context, {
    required List<String> demoCodes,
  }) async {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => PremiumQrScannerDialog(demoCodes: demoCodes),
    );
  }

  @override
  State<PremiumQrScannerDialog> createState() => _PremiumQrScannerDialogState();
}

class _PremiumQrScannerDialogState extends State<PremiumQrScannerDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  late final TextEditingController _inputController;
  MobileScannerController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
    Navigator.of(context).pop(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: colorScheme.surface.withValues(alpha: 0.88),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('qrScanTitle'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Viewfinder Simulator
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.45),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.antiAlias,
                          children: [
                            // Camera preview or fallback glass backdrop
                            if (!_isCameraInitialized)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                  child: Container(color: Colors.transparent),
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
                                              color: Colors.redAccent,
                                              size: 36,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              isPermission
                                                  ? 'Camera permission denied'
                                                  : 'Camera unavailable',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
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
                            // Target Overlay Icon (only visible when camera not working / initializing)
                            if (!_isCameraInitialized)
                              Center(
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 56,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            // Corners Overlay
                            const _ViewfinderCorners(),
                            // Scanning Laser Animation
                            AnimatedBuilder(
                              animation: _scanController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanController.value * 220,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary,
                                          blurRadius: 8,
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
                    const SizedBox(height: 20),

                    // Manual Entry TextField
                    TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: l10n.t('qrScanPlaceholder'),
                        prefixIcon: const Icon(Icons.keyboard_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                          onPressed: () => _onCodeScanned(_inputController.text),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: _onCodeScanned,
                    ),
                    const SizedBox(height: 20),

                    // Demo QR codes picker
                    if (widget.demoCodes.isNotEmpty) ...[
                      Text(
                        l10n.t('qrDemoCodes'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final code in widget.demoCodes)
                                ActionChip(
                                  label: Text(
                                    code.startsWith('room:')
                                        ? code.split(':').last.toUpperCase()
                                        : code.toUpperCase(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  avatar: Icon(
                                    code.startsWith('room:')
                                        ? Icons.meeting_room_outlined
                                        : Icons.spa_outlined,
                                    size: 14,
                                  ),
                                  onPressed: () => _onCodeScanned(code),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
