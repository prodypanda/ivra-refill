import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A high-performance, GPU-accelerated hydrodynamic liquid level capsule.
///
/// Renders fluid liquid inside a luxury glass vial with continuous
/// subtle surface wave oscillation, meniscus refraction highlight, and
/// a 3D glass specular reflection streak.
class FluidLiquidGauge extends StatefulWidget {
  const FluidLiquidGauge({
    required this.percentage,
    this.height = 12.0,
    this.width,
    this.color,
    this.backgroundColor,
    this.threshold,
    this.showWave = false,
    this.showGlassGleam = true,
    this.borderRadius,
    super.key,
  });

  /// Fill percentage from 0.0 to 1.0 (or clamped if passed > 1.0).
  final double percentage;

  /// Capsule height in logical pixels.
  final double height;

  /// Optional fixed width. If null, fills available horizontal space.
  final double? width;

  /// Liquid color. If null, adapts to current theme and threshold state.
  final Color? color;

  /// Background track color of the glass chamber.
  final Color? backgroundColor;

  /// Critical threshold (0.0 to 1.0). If [percentage] <= [threshold],
  /// shifts liquid into alert tones and renders a threshold marker pin.
  final double? threshold;

  /// Whether to render continuous subtle fluid oscillation. Defaults to false.
  final bool showWave;

  /// Whether to render the diagonal 3D glass specular gleam.
  final bool showGlassGleam;

  /// Optional border radius. Defaults to half height for a pill shape.
  final BorderRadius? borderRadius;

  @override
  State<FluidLiquidGauge> createState() => _FluidLiquidGaugeState();
}

class _FluidLiquidGaugeState extends State<FluidLiquidGauge>
    with SingleTickerProviderStateMixin {
  AnimationController? _waveController;

  @override
  void initState() {
    super.initState();
    if (widget.showWave) {
      _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(FluidLiquidGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showWave != oldWidget.showWave) {
      if (widget.showWave) {
        _waveController ??= AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3200),
        );
        if (!_waveController!.isAnimating) _waveController!.repeat();
      } else {
        _waveController?.stop();
      }
    }
  }

  @override
  void dispose() {
    _waveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final isBotanical = themeExt?.isBotanical ?? false;
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final clampedPercentage = widget.percentage.clamp(0.0, 1.0);
    final isLow = widget.threshold != null && clampedPercentage <= widget.threshold!;

    final liquidColor = widget.color ??
        (isLow
            ? theme.colorScheme.error
            : (isBotanical ? const Color(0xFF10B981) : theme.colorScheme.primary));

    final trackColor = widget.backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    final radius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = widget.width ?? constraints.maxWidth;

          return SizedBox(
            width: effectiveWidth,
            height: widget.height,
            child: ClipRRect(
              borderRadius: radius,
              child: Container(
                color: trackColor,
                child: (_waveController != null && widget.showWave && !disableAnimations)
                    ? AnimatedBuilder(
                        animation: _waveController!,
                        builder: (context, _) => CustomPaint(
                          size: Size(effectiveWidth, widget.height),
                          painter: _FluidLiquidPainter(
                            percentage: clampedPercentage,
                            liquidColor: liquidColor,
                            wavePhase: _waveController!.value,
                            showWave: true,
                            showGlassGleam: widget.showGlassGleam,
                            threshold: widget.threshold,
                            isBotanical: isBotanical,
                            isDark: isDark,
                          ),
                        ),
                      )
                    : CustomPaint(
                        size: Size(effectiveWidth, widget.height),
                        painter: _FluidLiquidPainter(
                          percentage: clampedPercentage,
                          liquidColor: liquidColor,
                          wavePhase: 0.0,
                          showWave: false,
                          showGlassGleam: widget.showGlassGleam,
                          threshold: widget.threshold,
                          isBotanical: isBotanical,
                          isDark: isDark,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FluidLiquidPainter extends CustomPainter {
  _FluidLiquidPainter({
    required this.percentage,
    required this.liquidColor,
    required this.wavePhase,
    required this.showWave,
    required this.showGlassGleam,
    required this.threshold,
    required this.isBotanical,
    required this.isDark,
  });

  final double percentage;
  final Color liquidColor;
  final double wavePhase;
  final bool showWave;
  final bool showGlassGleam;
  final double? threshold;
  final bool isBotanical;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (percentage <= 0.001) return;

    final fillWidth = size.width * percentage;
    final h = size.height;

    // 1. Draw Liquid Body with Hydrodynamic Meniscus
    final liquidPath = Path();
    liquidPath.moveTo(0, 0);

    if (percentage >= 0.999 || !showWave) {
      // Full fill or static wave
      liquidPath.lineTo(fillWidth, 0);
      liquidPath.lineTo(fillWidth, h);
      liquidPath.lineTo(0, h);
    } else {
      // Hydrodynamic curved leading wave edge (meniscus)
      const waveAmplitude = 1.8;
      final waveAngle = wavePhase * 2 * math.pi;

      liquidPath.lineTo(fillWidth, 0);
      // Sinusoidal vertical meniscus wave at the right boundary
      for (double y = 0; y <= h; y += 1.5) {
        final waveOffset =
            math.sin((y / h * 2 * math.pi) + waveAngle) * waveAmplitude;
        liquidPath.lineTo(
          (fillWidth + waveOffset).clamp(0.0, size.width),
          y,
        );
      }
      liquidPath.lineTo(0, h);
    }
    liquidPath.close();

    // Luxurious 3D fluid gradient (surface caustics and deep pool)
    final surfaceHighlight = isBotanical
        ? Color.lerp(liquidColor, const Color(0xFFD4AF37), 0.25)! // Gold-infused jade
        : Color.lerp(liquidColor, Colors.white, 0.35)!; // Amber champagne glow

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surfaceHighlight,
          liquidColor,
          Color.lerp(liquidColor, Colors.black, 0.2)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, fillWidth, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(liquidPath, liquidPaint);

    // 2. Liquid Surface Refraction Glow (Top Edge Highlight)
    final surfaceGleamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, fillWidth, 2))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(0, 1),
      Offset(fillWidth, 1),
      surfaceGleamPaint,
    );

    // 3. Leading Meniscus Luminous Cap
    if (fillWidth > 4.0 && fillWidth < size.width - 2.0) {
      final meniscusPaint = Paint()
        ..color = surfaceHighlight.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      final meniscusPath = Path();
      if (showWave) {
        final waveAngle = wavePhase * 2 * math.pi;
        meniscusPath.moveTo(fillWidth, 0);
        for (double y = 0; y <= h; y += 1.5) {
          final waveOffset =
              math.sin((y / h * 2 * math.pi) + waveAngle) * 1.8;
          meniscusPath.lineTo(
            (fillWidth + waveOffset).clamp(0.0, size.width),
            y,
          );
        }
      } else {
        meniscusPath.moveTo(fillWidth, 0);
        meniscusPath.lineTo(fillWidth, h);
      }
      canvas.drawPath(meniscusPath, meniscusPaint);
    }

    // 4. Diagonal 3D Specular Glass Reflection
    if (showGlassGleam && size.width > 20) {
      final gleamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.30 : 0.45),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width * 0.45, h))
        ..style = PaintingStyle.fill;

      final gleamPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.35, 0)
        ..lineTo(size.width * 0.15, h)
        ..lineTo(0, h)
        ..close();

      canvas.drawPath(gleamPath, gleamPaint);
    }

    // 5. Critical Threshold Marker
    if (threshold != null && threshold! > 0.0 && threshold! < 1.0) {
      final thresholdX = size.width * threshold!;
      final markerPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.75)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(thresholdX, 0),
        Offset(thresholdX, h),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FluidLiquidPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.liquidColor != liquidColor ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.showWave != showWave ||
        oldDelegate.showGlassGleam != showGlassGleam ||
        oldDelegate.threshold != threshold ||
        oldDelegate.isBotanical != isBotanical ||
        oldDelegate.isDark != isDark;
  }
}
