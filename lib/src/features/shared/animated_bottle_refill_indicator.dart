import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBottleRefillIndicator extends StatefulWidget {
  const AnimatedBottleRefillIndicator({
    super.key,
    required this.refillPercentage,
    required this.bottleVolumeMl,
    required this.isInteracting,
    this.baseColor,
    this.accentColor,
    this.width = 150,
    this.height = 240,
  });

  /// The refill percentage as a value from 0.0 to 1.0 (0% to 100%)
  final double refillPercentage;

  /// The total volume capacity of the bottle in milliliters
  final int bottleVolumeMl;

  /// Whether the user is currently dragging/holding the slider
  final bool isInteracting;

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
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Initial fill is 0.0 if interacting, otherwise target value
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.isInteracting ? 0.0 : widget.refillPercentage,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.decelerate,
    ));

    if (!widget.isInteracting) {
      _fillController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(AnimatedBottleRefillIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isInteracting != widget.isInteracting ||
        oldWidget.refillPercentage != widget.refillPercentage) {
      _fillController.stop();

      final double currentVal = _fillAnimation.value;

      if (widget.isInteracting) {
        // Evaporating down to 0.0 quickly and smoothly when dragging/holding
        _fillAnimation = Tween<double>(
          begin: currentVal,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: _fillController,
          curve: Curves.easeOutCubic,
        ));
        _fillController.duration = const Duration(milliseconds: 350);
        _fillController.forward(from: 0.0);
      } else {
        // Filling up to the target value when released
        _fillAnimation = Tween<double>(
          begin: currentVal,
          end: widget.refillPercentage,
        ).animate(CurvedAnimation(
          parent: _fillController,
          curve: Curves.easeOutBack, // Playful, smooth fill bounce!
        ));
        _fillController.duration = const Duration(milliseconds: 1200);
        _fillController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
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
      animation: Listenable.merge([_waveController, _fillController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _BottlePainter(
            refillPercentage: _fillAnimation.value,
            bottleVolumeMl: widget.bottleVolumeMl,
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
    required this.bottleVolumeMl,
    required this.waveValue,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
  });

  final double refillPercentage;
  final int bottleVolumeMl;
  final double waveValue;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate dimensions based on canvas size
    final xLeft = size.width * 0.22; // Nudge in slightly to leave room for left scale ruler
    final xRight = size.width * 0.88;
    final yBottom = size.height * 0.93;
    final yTop = size.height * 0.18; // Shortened neck/mouth (was 0.08)
    final yShoulder = size.height * 0.42; // Adjusted shoulder proportion (was 0.38)
    final yNeckBase = size.height * 0.34; // Adjusted neck base (was 0.28)
    final xNeckLeft = xLeft + (xRight - xLeft) * 0.34;
    final xNeckRight = xLeft + (xRight - xLeft) * 0.66;
    const cornerRadius = 16.0;

    // 1. Draw a soft, premium drop shadow beneath the bottle base
    final shadowPaint = Paint()
      ..color = isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawOval(
      Rect.fromLTRB(xLeft - 6, yBottom - 4, xRight + 6, yBottom + 8),
      shadowPaint,
    );

    // Main bottle path
    final bottlePath = Path();
    bottlePath.moveTo(xLeft + cornerRadius, yBottom);
    bottlePath.lineTo(xRight - cornerRadius, yBottom);
    // Draw convex (outward rounded) bottom right corner with clockwise: true
    bottlePath.arcToPoint(
      Offset(xRight, yBottom - cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );
    bottlePath.lineTo(xRight, yShoulder);
    bottlePath.quadraticBezierTo(xRight, yNeckBase, xNeckRight, yNeckBase);
    bottlePath.lineTo(xNeckRight, yTop);
    bottlePath.lineTo(xNeckLeft, yTop);
    bottlePath.lineTo(xNeckLeft, yNeckBase);
    bottlePath.quadraticBezierTo(xLeft, yNeckBase, xLeft, yShoulder);
    bottlePath.lineTo(xLeft, yBottom - cornerRadius);
    // Draw convex (outward rounded) bottom left corner with clockwise: true
    bottlePath.arcToPoint(
      Offset(xLeft + cornerRadius, yBottom),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );
    bottlePath.close();

    // 2. Draw frosted glass textured background gradient inside the bottle
    final glassBgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)]
            : [Colors.black.withOpacity(0.04), Colors.black.withOpacity(0.01)],
      ).createShader(Rect.fromLTRB(xLeft, yTop, xRight, yBottom))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottlePath, glassBgPaint);

    // Clip rendering inside the glass bottle shape for liquids & bubbles
    canvas.save();
    canvas.clipPath(bottlePath);

    final yMaxLiquid = size.height * 0.36; // Lowered liquid top to match shoulder adjustments
    final yMinLiquid = size.height * 0.91;
    final liquidSpan = yMinLiquid - yMaxLiquid;

    // A. Draw newly added liquid (accentColor) at the top
    if (refillPercentage > 0.001) {
      final addedWavePath = Path();
      const waveAmplitude = 4.5;
      const waveFrequency = 0.055;

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

      // Liquid container linear gradient for rich 3D shading
      final paintAdded = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withOpacity(0.85),
            accentColor,
          ],
        ).createShader(Rect.fromLTRB(xLeft, yMaxLiquid, xRight, yMinLiquid));
      canvas.drawPath(addedWavePath, paintAdded);
    }

    // B. Draw pre-existing liquid (baseColor) on top to overlay beautifully
    final double existingRatio = 1.0 - refillPercentage;
    final double ySplit = yMinLiquid - existingRatio * liquidSpan;

    if (existingRatio > 0.001) {
      final existingWavePath = Path();
      const waveAmplitude = 3.5;
      const waveFrequency = 0.045;

      existingWavePath.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 2.0) {
        // Draw with inverted phase to make the liquid interface look dynamically wavy
        final y = ySplit +
            waveAmplitude *
                math.sin((x * waveFrequency) - (waveValue * 2 * math.pi));
        existingWavePath.lineTo(x, y);
      }
      existingWavePath.lineTo(size.width, size.height);
      existingWavePath.lineTo(0, size.height);
      existingWavePath.close();

      final paintExisting = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withOpacity(0.9),
            baseColor,
          ],
        ).createShader(Rect.fromLTRB(xLeft, ySplit, xRight, yMinLiquid));
      canvas.drawPath(existingWavePath, paintExisting);
    }

    // C. Draw Rising & Swaying Micro-Bubbles inside liquid columns
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final bubbleStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int idx = 0; idx < 10; idx++) {
      // Deterministic values based on bubble index
      final double seedX = math.sin(idx * 452.3) * 0.5 + 0.5;
      final double seedSize = math.sin(idx * 219.4) * 0.5 + 0.5;
      final double seedDelay = math.cos(idx * 311.1) * 0.5 + 0.5;

      // Vertical animation cycle
      final double progress = (waveValue + seedDelay) % 1.0;
      final double yBubble = yMinLiquid - progress * liquidSpan;

      // Only paint if the bubble is in the active liquid span
      if (yBubble >= yMaxLiquid && yBubble <= yMinLiquid) {
        // Dynamic horizontal swaying using sine curve
        final double startX = xLeft + 16 + seedX * (xRight - xLeft - 32);
        final double sway = math.sin(progress * 4 * math.pi + idx) * 4.0;
        final double xBubble = startX + sway;
        final double radius = 1.8 + seedSize * 2.5;

        canvas.drawCircle(Offset(xBubble, yBubble), radius, bubblePaint);
        canvas.drawCircle(Offset(xBubble, yBubble), radius, bubbleStrokePaint);
      }
    }

    // D. Draw Dynamic Text Labels Inside the liquid columns
    final double xCenter = (xLeft + xRight) / 2.0;

    // Format helper
    String formatVolume(double ml) {
      if (ml >= 1000.0) {
        final double l = ml / 1000.0;
        return '${l.toStringAsFixed(l == l.roundToDouble() ? 0 : 1)}L';
      } else {
        return '${ml.round()}ml';
      }
    }

    void drawInBottleText(double x, double y, String label, String value) {
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              height: 1.25,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Upper region (To Add, accentColor)
    final double upperHeight = ySplit - yMaxLiquid;
    if (upperHeight >= 32.0) {
      drawInBottleText(
        xCenter,
        yMaxLiquid + upperHeight / 2.0,
        "To Add",
        "+${formatVolume(refillPercentage * bottleVolumeMl)}",
      );
    } else if (upperHeight >= 14.0) {
      final textSpan = TextSpan(
        text: "To Add: +${formatVolume(refillPercentage * bottleVolumeMl)}",
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(xCenter - textPainter.width / 2, yMaxLiquid + upperHeight / 2.0 - textPainter.height / 2),
      );
    }

    // Lower region (Existing, baseColor)
    final double lowerHeight = yMinLiquid - ySplit;
    if (lowerHeight >= 32.0) {
      drawInBottleText(
        xCenter,
        ySplit + lowerHeight / 2.0,
        "Existing",
        formatVolume((1.0 - refillPercentage) * bottleVolumeMl),
      );
    } else if (lowerHeight >= 14.0) {
      final textSpan = TextSpan(
        text: "Existing: ${formatVolume((1.0 - refillPercentage) * bottleVolumeMl)}",
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(xCenter - textPainter.width / 2, ySplit + lowerHeight / 2.0 - textPainter.height / 2),
      );
    }

    canvas.restore();

    // 3. Draw high-end 3D glossy pill highlights on the glass bottle surface
    final glossyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.40),
          Colors.white.withOpacity(0.04),
        ],
      ).createShader(Rect.fromLTRB(xLeft + 5, yShoulder, xLeft + 11, yBottom))
      ..style = PaintingStyle.fill;

    final glossyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(xLeft + 4, yShoulder + 12, xLeft + 9, yBottom - 16),
        const Radius.circular(3),
      ));
    canvas.drawPath(glossyPath, glossyPaint);

    // 4. Draw outer glass container stroke
    final strokePaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.24)
          : Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawPath(bottlePath, strokePaint);

    // Draw Cap/Pump details
    final capPath = Path();
    capPath.moveTo(xNeckLeft - 2, yTop);
    capPath.lineTo(xNeckRight + 2, yTop);
    capPath.lineTo(xNeckRight + 2, yTop - 12);
    capPath.lineTo(xNeckLeft - 2, yTop - 12);
    capPath.close();

    final capPaint = Paint()
      ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade400
      ..style = PaintingStyle.fill;
    canvas.drawPath(capPath, capPaint);

    final capStroke = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.25)
          : Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(capPath, capStroke);

    // 5. Draw Left-side Graduated Ruler Scale and tick marks
    final scalePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.35) : Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 10; i++) {
      final double ratio = i / 10.0;
      final double yLevel = yMinLiquid - ratio * liquidSpan;
      final bool isMajor = i % 2 == 0 || i == 10;
      final double tickLength = isMajor ? 8.0 : 4.0;

      canvas.drawLine(
        Offset(xLeft - tickLength, yLevel),
        Offset(xLeft - 1, yLevel),
        scalePaint,
      );

      if (isMajor) {
        final double volume = ratio * bottleVolumeMl;
        final String text = formatVolume(volume);
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.45),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(xLeft - tickLength - 4 - textPainter.width, yLevel - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) {
    return oldDelegate.refillPercentage != refillPercentage ||
        oldDelegate.bottleVolumeMl != bottleVolumeMl ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
