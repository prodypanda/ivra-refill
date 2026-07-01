import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBottleRefillIndicator extends StatefulWidget {
  const AnimatedBottleRefillIndicator({
    super.key,
    required this.refillPercentage,
    this.baseColor,
    this.accentColor,
    this.width = 150,
    this.height = 240,
  });

  /// The refill percentage as a value from 0.0 to 1.0 (0% to 100%)
  final double refillPercentage;

  /// Color representing pre-existing volume in the bottle
  final Color? baseColor;

  /// Color representing newly added refill volume
  final Color? accentColor;

  final double width;
  final double height;

  @override
  State<AnimatedBottleRefillIndicator> createState() =>
      _AnimatedBottleRefillIndicatorState();
}

class _AnimatedBottleRefillIndicatorState
    extends State<AnimatedBottleRefillIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Design-system-aligned luxurious colors
    final finalBaseColor = widget.baseColor ?? theme.colorScheme.primary;
    final finalAccentColor = widget.accentColor ??
        (isDark ? Colors.cyanAccent.shade400 : Colors.teal.shade400);

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _BottlePainter(
            refillPercentage: widget.refillPercentage,
            waveValue: _waveController.value,
            baseColor: finalBaseColor,
            accentColor: finalAccentColor,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _BottlePainter extends CustomPainter {
  _BottlePainter({
    required this.refillPercentage,
    required this.waveValue,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
  });

  final double refillPercentage;
  final double waveValue;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate dimensions based on canvas size
    final xLeft = size.width * 0.15;
    final xRight = size.width * 0.85;
    final yBottom = size.height * 0.94;
    final yTop = size.height * 0.08;
    final yShoulder = size.height * 0.38;
    final yNeckBase = size.height * 0.28;
    final xNeckLeft = size.width * 0.38;
    final xNeckRight = size.width * 0.62;
    const cornerRadius = 16.0;

    // Main bottle path
    final bottlePath = Path();
    bottlePath.moveTo(xLeft + cornerRadius, yBottom);
    bottlePath.lineTo(xRight - cornerRadius, yBottom);
    bottlePath.arcToPoint(
      Offset(xRight, yBottom - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    bottlePath.lineTo(xRight, yShoulder);
    bottlePath.quadraticBezierTo(xRight, yNeckBase, xNeckRight, yNeckBase);
    bottlePath.lineTo(xNeckRight, yTop);
    bottlePath.lineTo(xNeckLeft, yTop);
    bottlePath.lineTo(xNeckLeft, yNeckBase);
    bottlePath.quadraticBezierTo(xLeft, yNeckBase, xLeft, yShoulder);
    bottlePath.lineTo(xLeft, yBottom - cornerRadius);
    bottlePath.arcToPoint(
      Offset(xLeft + cornerRadius, yBottom),
      radius: const Radius.circular(cornerRadius),
    );
    bottlePath.close();

    // Clip rendering inside the glass bottle shape
    canvas.save();
    canvas.clipPath(bottlePath);

    final yMaxLiquid = size.height * 0.30;
    final yMinLiquid = size.height * 0.93;
    final liquidSpan = yMinLiquid - yMaxLiquid;

    // 1. Draw newly added liquid (accentColor)
    if (refillPercentage > 0.001) {
      final addedWavePath = Path();
      const waveAmplitude = 4.0;
      const waveFrequency = 0.06;

      addedWavePath.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 2.0) {
        final y = yMaxLiquid +
            waveAmplitude *
                math.sin((x * waveFrequency) + (waveValue * 2 * math.pi));
        addedWavePath.lineTo(x, y);
      }
      addedWavePath.lineTo(size.width, size.height);
      addedWavePath.lineTo(0, size.height);
      addedWavePath.close();

      final paintAdded = Paint()..color = accentColor;
      canvas.drawPath(addedWavePath, paintAdded);
    }

    // 2. Draw pre-existing liquid (baseColor) on top to overlay beautifully
    final double existingRatio = 1.0 - refillPercentage;
    if (existingRatio > 0.001) {
      final ySplit = yMinLiquid - existingRatio * liquidSpan;
      final existingWavePath = Path();
      const waveAmplitude = 3.0;
      const waveFrequency = 0.045;

      existingWavePath.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 2.0) {
        // Draw with inverted phase to make the interface look dynamically wavy
        final y = ySplit +
            waveAmplitude *
                math.sin((x * waveFrequency) - (waveValue * 2 * math.pi));
        existingWavePath.lineTo(x, y);
      }
      existingWavePath.lineTo(size.width, size.height);
      existingWavePath.lineTo(0, size.height);
      existingWavePath.close();

      final paintExisting = Paint()..color = baseColor;
      canvas.drawPath(existingWavePath, paintExisting);
    }

    canvas.restore();

    // 3. Draw outer glass container stroke
    final strokePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(bottlePath, strokePaint);

    // Draw Cap/Pump details
    final capPath = Path();
    capPath.moveTo(xNeckLeft - 2, yTop);
    capPath.lineTo(xNeckRight + 2, yTop);
    capPath.lineTo(xNeckRight + 2, yTop - 14);
    capPath.lineTo(xNeckLeft - 2, yTop - 14);
    capPath.close();

    final capPaint = Paint()
      ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade400
      ..style = PaintingStyle.fill;
    canvas.drawPath(capPath, capPaint);

    final capStroke = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(capPath, capStroke);

    // Subtle premium glass glare vertical line
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.15 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final highlightPath = Path();
    highlightPath.moveTo(xLeft + 8, yShoulder + 12);
    highlightPath.lineTo(xLeft + 8, yBottom - 20);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) {
    return oldDelegate.refillPercentage != refillPercentage ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
