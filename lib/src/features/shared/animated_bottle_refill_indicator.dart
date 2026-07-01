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
    this.existingLabel,
    this.toAddLabel,
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

  /// Localized label for existing volume
  final String? existingLabel;

  /// Localized label for newly added volume
  final String? toAddLabel;

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
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isInteracting) {
      _fillAnimation = const AlwaysStoppedAnimation<double>(0.0);
    } else {
      _fillAnimation = Tween<double>(
        begin: 0.0,
        end: widget.refillPercentage,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      if (widget.refillPercentage > 0.0) {
        _fillController.forward(from: 0.0);
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedBottleRefillIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isInteracting != widget.isInteracting) {
      _fillController.stop();

      if (widget.isInteracting) {
        _fillAnimation = const AlwaysStoppedAnimation<double>(0.0);
      } else {
        _fillAnimation = Tween<double>(
          begin: 0.0,
          end: widget.refillPercentage,
        ).animate(CurvedAnimation(
          parent: _fillController,
          curve: Curves.easeOutCubic,
        ));
        _fillController.forward(from: 0.0);
      }
    } else if (!widget.isInteracting &&
        oldWidget.refillPercentage != widget.refillPercentage) {
      _fillController.stop();
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: widget.refillPercentage,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      _fillController.forward(from: 0.0);
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
            targetRefillPercentage: widget.refillPercentage,
            isInteracting: widget.isInteracting,
            bottleVolumeMl: widget.bottleVolumeMl,
            waveValue: _waveController.value,
            baseColor: finalBaseColor,
            accentColor: finalAccentColor,
            isDark: isDark,
            existingLabel: widget.existingLabel ?? "Existing",
            toAddLabel: widget.toAddLabel ?? "To Add",
          ),
        );
      },
    );
  }
}

class _BottlePainter extends CustomPainter {
  _BottlePainter({
    required this.refillPercentage,
    required this.targetRefillPercentage,
    required this.isInteracting,
    required this.bottleVolumeMl,
    required this.waveValue,
    required this.baseColor,
    required this.accentColor,
    required this.isDark,
    required this.existingLabel,
    required this.toAddLabel,
  });

  final double refillPercentage;
  final double targetRefillPercentage;
  final bool isInteracting;
  final int bottleVolumeMl;
  final double waveValue;
  final Color baseColor;
  final Color accentColor;
  final bool isDark;
  final String existingLabel;
  final String toAddLabel;

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate dimensions based on canvas size
    final xLeft = size.width * 0.22; // Nudge in slightly to leave room for left scale ruler
    final xRight = size.width * 0.88;
    final yBottom = size.height * 0.93;
    final yTop = size.height * 0.25; // Shortened neck/mouth (was 0.18)
    final yShoulder = size.height * 0.42; // Adjusted shoulder proportion (was 0.42)
    final yNeckBase = size.height * 0.32; // Adjusted neck base (was 0.34)
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
    // Draw convex (outward rounded) bottom right corner with quadraticBezierTo
    bottlePath.quadraticBezierTo(xRight, yBottom, xRight, yBottom - cornerRadius);
    bottlePath.lineTo(xRight, yShoulder);
    bottlePath.quadraticBezierTo(xRight, yNeckBase, xNeckRight, yNeckBase);
    bottlePath.lineTo(xNeckRight, yTop);
    bottlePath.lineTo(xNeckLeft, yTop);
    bottlePath.lineTo(xNeckLeft, yNeckBase);
    bottlePath.quadraticBezierTo(xLeft, yNeckBase, xLeft, yShoulder);
    bottlePath.lineTo(xLeft, yBottom - cornerRadius);
    // Draw convex (outward rounded) bottom left corner with quadraticBezierTo
    bottlePath.quadraticBezierTo(xLeft, yBottom, xLeft + cornerRadius, yBottom);
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

    // Liquid physical ratios:
    final double r_old = (1.0 - targetRefillPercentage).clamp(0.0, 1.0);
    final double r_new = (isInteracting ? 0.0 : refillPercentage).clamp(0.0, targetRefillPercentage);

    final double ySplit = yMinLiquid - r_old * liquidSpan;
    final double yNewSurface = yMinLiquid - (r_old + r_new) * liquidSpan;

    // Center coordinates for falling stream calculations
    final double xCenter = (xNeckLeft + xNeckRight) / 2.0;

    // Calculate dynamic stream opacity for water pouring effect
    double streamOpacity = 0.0;
    if (!isInteracting && targetRefillPercentage > 0.001) {
      final double progress = targetRefillPercentage > 0.001 ? (r_new / targetRefillPercentage) : 0.0;
      if (progress > 0.0 && progress < 1.0) {
        if (progress < 0.15) {
          streamOpacity = progress / 0.15;
        } else if (progress > 0.85) {
          streamOpacity = (1.0 - progress) / 0.15;
        } else {
          streamOpacity = 1.0;
        }
      }
    }

    // A. Draw newly added liquid (accentColor) at the top
    if (r_new > 0.001) {
      final addedWavePath = Path();
      const waveAmplitude = 4.5;
      const waveFrequency = 0.055;

      addedWavePath.moveTo(xLeft - 10, size.height);
      for (double x = xLeft - 10; x <= xRight + 10; x += 2.0) {
        // Physical Splash Ripple Perturbation: decays exponentially from the stream impact point
        final double centerDist = (x - xCenter).abs();
        final double ripplePerturbation = math.sin((centerDist * 0.15) - (waveValue * 8 * math.pi)) * 
            6.0 * streamOpacity * math.exp(-centerDist * 0.04);

        final y = yNewSurface + ripplePerturbation +
            waveAmplitude *
                math.sin((x * waveFrequency) + (waveValue * 2 * math.pi));
        addedWavePath.lineTo(x, y);
      }
      addedWavePath.lineTo(xRight + 10, size.height);
      addedWavePath.lineTo(xLeft - 10, size.height);
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
        ).createShader(Rect.fromLTRB(xLeft, yNewSurface, xRight, yMinLiquid));
      canvas.drawPath(addedWavePath, paintAdded);

      // Meniscus Glowing Highlight along the surface wave of the newly added liquid
      final addedSurfaceWave = Path();
      for (double x = xLeft; x <= xRight; x += 2.0) {
        final double centerDist = (x - xCenter).abs();
        final double ripplePerturbation = math.sin((centerDist * 0.15) - (waveValue * 8 * math.pi)) * 
            6.0 * streamOpacity * math.exp(-centerDist * 0.04);

        final y = yNewSurface + ripplePerturbation +
            waveAmplitude *
                math.sin((x * waveFrequency) + (waveValue * 2 * math.pi));
        if (x == xLeft) {
          addedSurfaceWave.moveTo(x, y);
        } else {
          addedSurfaceWave.lineTo(x, y);
        }
      }
      final surfaceCapPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawPath(addedSurfaceWave, surfaceCapPaint);
    }

    // B. Draw pre-existing liquid (baseColor) on top to overlay beautifully
    if (r_old > 0.001) {
      final existingWavePath = Path();
      const waveAmplitude = 3.5;
      const waveFrequency = 0.045;

      existingWavePath.moveTo(xLeft - 10, size.height);
      for (double x = xLeft - 10; x <= xRight + 10; x += 2.0) {
        // Draw with inverted phase to make the liquid interface look dynamically wavy
        final y = ySplit +
            waveAmplitude *
                math.sin((x * waveFrequency) - (waveValue * 2 * math.pi));
        existingWavePath.lineTo(x, y);
      }
      existingWavePath.lineTo(xRight + 10, size.height);
      existingWavePath.lineTo(xLeft - 10, size.height);
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

      // Meniscus Glowing Highlight along the surface wave of the existing liquid
      final existingSurfaceWave = Path();
      for (double x = xLeft; x <= xRight; x += 2.0) {
        final y = ySplit +
            waveAmplitude *
                math.sin((x * waveFrequency) - (waveValue * 2 * math.pi));
        if (x == xLeft) {
          existingSurfaceWave.moveTo(x, y);
        } else {
          existingSurfaceWave.lineTo(x, y);
        }
      }
      final existingCapPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(existingSurfaceWave, existingCapPaint);
    }

    // C. Draw falling liquid stream flowing from the cap down to the rising liquid surface
    if (streamOpacity > 0.01) {
      final double streamWidth = 8.0 * streamOpacity;
      final streamPath = Path();

      // Gravity Tapering: Stream is wider at top nozzle, narrower at the bottom landing point!
      streamPath.moveTo(xCenter - streamWidth / 2, yTop);
      for (double y = yTop; y <= yNewSurface; y += 4.0) {
        final double tY = (y - yTop) / (yNewSurface - yTop);
        final double widthFactor = 1.0 - (0.35 * tY); // Taper down to 65% width
        final double currentWidth = streamWidth * widthFactor;
        final double sway = math.sin((y * 0.1) - (waveValue * 4 * math.pi)) * 1.5;
        streamPath.lineTo(xCenter - currentWidth / 2 + sway, y);
      }
      streamPath.lineTo(xCenter + (streamWidth * 0.65) / 2, yNewSurface);
      for (double y = yNewSurface; y >= yTop; y -= 4.0) {
        final double tY = (y - yTop) / (yNewSurface - yTop);
        final double widthFactor = 1.0 - (0.35 * tY);
        final double currentWidth = streamWidth * widthFactor;
        final double sway = math.sin((y * 0.1) - (waveValue * 4 * math.pi)) * 1.5;
        streamPath.lineTo(xCenter + currentWidth / 2 + sway, y);
      }
      streamPath.close();

      final streamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withOpacity(0.95 * streamOpacity),
            accentColor.withOpacity(0.75 * streamOpacity),
          ],
        ).createShader(Rect.fromLTRB(xCenter - streamWidth, yTop, xCenter + streamWidth, yNewSurface))
        ..style = PaintingStyle.fill;

      canvas.drawPath(streamPath, streamPaint);

      // Shimmer threads inside stream for glittering wet flowing texture
      final shimmerPaint1 = Paint()
        ..color = Colors.white.withOpacity(0.55 * streamOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final shimmerPaint2 = Paint()
        ..color = Colors.white.withOpacity(0.3 * streamOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;

      final shimmerPath1 = Path();
      final shimmerPath2 = Path();

      for (double y = yTop; y <= yNewSurface; y += 4.0) {
        final double sway = math.sin((y * 0.1) - (waveValue * 4 * math.pi)) * 1.5;
        if (y == yTop) {
          shimmerPath1.moveTo(xCenter + sway - 1.2, y);
          shimmerPath2.moveTo(xCenter + sway + 1.2, y);
        } else {
          shimmerPath1.lineTo(xCenter + sway - 1.2, y);
          shimmerPath2.lineTo(xCenter + sway + 1.2, y);
        }
      }
      canvas.drawPath(shimmerPath1, shimmerPaint1);
      canvas.drawPath(shimmerPath2, shimmerPaint2);

      // D. Gravity-based Spray Splash Particles at the landing point
      if (streamOpacity > 0.05) {
        final splashPaint = Paint()
          ..color = accentColor.withOpacity(0.65 * streamOpacity)
          ..style = PaintingStyle.fill;

        for (int i = 0; i < 6; i++) {
          // Dynamic loop for particles: spreads outward, sprays upwards/outwards, pulls down by gravity
          final double t = (waveValue * 1.8 + i / 6.0) % 1.0;
          final double angle = -math.pi / 2.0 + (i - 2.5) * (math.pi / 8.0); // spray fan
          final double speed = 25.0 + 15.0 * math.sin(i * 324.5);
          final double distance = t * speed;

          final double splashX = xCenter + math.cos(angle) * distance;
          // y-position includes velocity + acceleration due to gravity (0.5 * g * t^2)
          final double splashY = yNewSurface + math.sin(angle) * distance + (0.5 * 9.8 * t * t * 30.0);
          final double splashRadius = (1.8 + 1.2 * math.sin(i * 123.4)) * (1.0 - t);

          if (splashRadius > 0.1 && splashX >= xLeft && splashX <= xRight && splashY >= yNewSurface) {
            canvas.drawCircle(Offset(splashX, splashY), splashRadius, splashPaint);
          }
        }
      }
    }

    // E. Draw Rising & Swaying Micro-Bubbles inside liquid columns
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
      if (yBubble >= yNewSurface && yBubble <= yMinLiquid) {
        // Dynamic horizontal swaying using sine curve
        final double startX = xLeft + 16 + seedX * (xRight - xLeft - 32);
        final double sway = math.sin(progress * 4 * math.pi + idx) * 4.0;
        final double xBubble = startX + sway;
        final double radius = 1.8 + seedSize * 2.5;

        canvas.drawCircle(Offset(xBubble, yBubble), radius, bubblePaint);
        canvas.drawCircle(Offset(xBubble, yBubble), radius, bubbleStrokePaint);
      }
    }

    // F. Draw Dynamic Localized Text Labels Inside the liquid columns
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
    final double upperHeight = ySplit - yNewSurface;
    if (upperHeight >= 32.0) {
      drawInBottleText(
        xCenter,
        yNewSurface + upperHeight / 2.0,
        toAddLabel,
        "+${formatVolume(r_new * bottleVolumeMl)}",
      );
    } else if (upperHeight >= 14.0) {
      final textSpan = TextSpan(
        text: "$toAddLabel: +${formatVolume(r_new * bottleVolumeMl)}",
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
        Offset(xCenter - textPainter.width / 2, yNewSurface + upperHeight / 2.0 - textPainter.height / 2),
      );
    }

    // Lower region (Existing, baseColor)
    final double lowerHeight = yMinLiquid - ySplit;
    if (lowerHeight >= 32.0) {
      drawInBottleText(
        xCenter,
        ySplit + lowerHeight / 2.0,
        existingLabel,
        formatVolume(r_old * bottleVolumeMl),
      );
    } else if (lowerHeight >= 14.0) {
      final textSpan = TextSpan(
        text: "$existingLabel: ${formatVolume(r_old * bottleVolumeMl)}",
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

    // 4. Draw outer glass container stroke with inner refraction double rim
    final strokePaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.24)
          : Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawPath(bottlePath, strokePaint);

    final innerGlassPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(bottlePath, innerGlassPaint);

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
        oldDelegate.targetRefillPercentage != targetRefillPercentage ||
        oldDelegate.isInteracting != isInteracting ||
        oldDelegate.bottleVolumeMl != bottleVolumeMl ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.existingLabel != existingLabel ||
        oldDelegate.toAddLabel != toAddLabel;
  }
}
