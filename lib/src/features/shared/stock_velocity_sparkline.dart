import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// An interactive, Awwwards-grade predictive stock velocity sparkline.
/// Renders an animated cubic bezier depletion trajectory with interactive
/// scrubbing, glowing particle tracking, and real-time replenishment projection tooltips.
class StockVelocitySparkline extends StatefulWidget {
  const StockVelocitySparkline({
    required this.currentStock,
    this.daysRemaining,
    this.dailyConsumptionRate = 1.0,
    this.height = 54.0,
    this.width,
    this.accentColor,
    this.showScrubber = true,
    this.productLabel,
    super.key,
  });

  final int currentStock;
  final int? daysRemaining;
  final double dailyConsumptionRate;
  final double height;
  final double? width;
  final Color? accentColor;
  final bool showScrubber;
  final String? productLabel;

  @override
  State<StockVelocitySparkline> createState() => _StockVelocitySparklineState();
}

class _StockVelocitySparklineState extends State<StockVelocitySparkline> {
  double? _scrubFraction;

  void _handleScrub(double localX, double totalWidth) {
    if (!widget.showScrubber || totalWidth <= 0) return;
    final fraction = (localX / totalWidth).clamp(0.0, 1.0);
    if ((_scrubFraction ?? -1.0) != fraction) {
      // Light haptic tick when scrubbing
      if ((fraction - 0.45).abs() < 0.05) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _scrubFraction = fraction;
      });
    }
  }

  void _clearScrub() {
    if (_scrubFraction != null) {
      setState(() {
        _scrubFraction = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final isBotanical = themeExt?.isBotanical ?? false;

    final baseColor = widget.accentColor ??
        (isBotanical ? const Color(0xFF10B981) : theme.colorScheme.primary);
    final effectiveDays = widget.daysRemaining;
    final isLowStock = effectiveDays != null && effectiveDays <= 7;
    final strokeColor = isLowStock
        ? (isBotanical ? const Color(0xFFF59E0B) : theme.colorScheme.error)
        : baseColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = widget.width ?? constraints.maxWidth;

        return MouseRegion(
          cursor: widget.showScrubber
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.basic,
          onExit: (_) => _clearScrub(),
          onHover: (e) => _handleScrub(e.localPosition.dx, totalWidth),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (e) =>
                _handleScrub(e.localPosition.dx, totalWidth),
            onHorizontalDragUpdate: (e) =>
                _handleScrub(e.localPosition.dx, totalWidth),
            onHorizontalDragEnd: (_) => _clearScrub(),
            onTapDown: (e) => _handleScrub(e.localPosition.dx, totalWidth),
            onTapUp: (_) => _clearScrub(),
            child: SizedBox(
              width: totalWidth,
              height: widget.height,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) {
                  return CustomPaint(
                    size: Size(totalWidth, widget.height),
                    painter: _SparklinePainter(
                      currentStock: widget.currentStock,
                      daysRemaining: effectiveDays,
                      dailyConsumptionRate: widget.dailyConsumptionRate,
                      strokeColor: strokeColor,
                      isBotanical: isBotanical,
                      scrubFraction: _scrubFraction,
                      progress: progress,
                      theme: theme,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.currentStock,
    required this.daysRemaining,
    required this.dailyConsumptionRate,
    required this.strokeColor,
    required this.isBotanical,
    required this.scrubFraction,
    required this.progress,
    required this.theme,
  });

  final int currentStock;
  final int? daysRemaining;
  final double dailyConsumptionRate;
  final Color strokeColor;
  final bool isBotanical;
  final double? scrubFraction;
  final double progress;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final width = size.width;
    final height = size.height;
    final topPadding = 12.0;
    final bottomPadding = 8.0;
    final usableHeight = height - topPadding - bottomPadding;

    // Generate 7 trajectory points
    // Points 0..3: Past 3 days to Today (index 3 is Today, x = 0.45 * width)
    // Points 4..6: Projected depletion to 0 stock
    final points = <Offset>[];
    final todayX = width * 0.45;
    final maxStock = math.max(
      currentStock + (dailyConsumptionRate * 3.0),
      currentStock * 1.5,
    ).clamp(1.0, 9999.0);

    // Normalize stock value to Y coordinate (higher stock = lower Y)
    double stockToY(double stock) {
      final normalized = (stock / maxStock).clamp(0.0, 1.0);
      return topPadding + (usableHeight * (1.0 - normalized));
    }

    // Past points (Days -3, -2, -1, 0)
    for (int i = 0; i < 4; i++) {
      final pastDays = 3 - i;
      final x = (todayX / 3.0) * i;
      final estimatedStock = currentStock + (dailyConsumptionRate * pastDays);
      points.add(Offset(x, stockToY(estimatedStock)));
    }

    // Future points (Days +1, +2, Runout)
    final days = daysRemaining ?? 30;
    final futureWidth = width - todayX;
    if (days <= 0) {
      points.add(Offset(todayX + (futureWidth * 0.5), stockToY(0)));
      points.add(Offset(width, stockToY(0)));
    } else {
      final midStock = (currentStock * 0.5);
      points.add(Offset(todayX + (futureWidth * 0.5), stockToY(midStock)));
      points.add(Offset(width, stockToY(0)));
    }

    // Build smooth Cubic Bezier Path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Measure path length and trim by progress for entrance animation
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;
    final metric = pathMetrics.first;
    final currentLength = metric.length * progress;
    final animatedPath = metric.extractPath(0.0, currentLength);

    // 1. Draw gradient fill under the curve
    final fillPath = Path.from(animatedPath)
      ..lineTo(animatedPath.getBounds().right.clamp(0.0, width), height)
      ..lineTo(points.first.dx, height)
      ..close();

    final fillGradient = ui.Gradient.linear(
      Offset(0, topPadding),
      Offset(0, height),
      [
        strokeColor.withValues(alpha: isBotanical ? 0.22 : 0.16),
        strokeColor.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw subtle dashed baseline at Y=0 stock level
    final baselineY = stockToY(0);
    final dashedPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double dashX = 0;
    while (dashX < width) {
      canvas.drawLine(
        Offset(dashX, baselineY),
        Offset(math.min(dashX + 4, width), baselineY),
        dashedPaint,
      );
      dashX += 8;
    }

    // 3. Draw ambient glow behind the stroke
    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: isBotanical ? 0.35 : 0.25)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(animatedPath, glowPaint);

    // 4. Draw crisp hairline stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(animatedPath, strokePaint);

    // 5. Draw "Today" marker dot on the curve
    final todayTangent = metric.getTangentForOffset(metric.length * 0.45);
    if (todayTangent != null && progress >= 0.45) {
      final todayPos = todayTangent.position;
      final todayDotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      final todayOuterPaint = Paint()
        ..color = theme.colorScheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(todayPos, 3.5, todayDotPaint);
      canvas.drawCircle(todayPos, 3.5, todayOuterPaint);
    }

    // 6. Interactive Scrubber & Tooltip
    if (scrubFraction != null && progress > 0.1) {
      final scrubOffset = metric.length * scrubFraction!;
      final tangent = metric.getTangentForOffset(scrubOffset);

      if (tangent != null) {
        final pos = tangent.position;

        // Glowing cursor particle
        final particleHaloPaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pos, 8.0, particleHaloPaint);

        final particleCorePaint = Paint()
          ..color = strokeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 4.5, particleCorePaint);

        final particleBorderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(pos, 4.5, particleBorderPaint);

        // Vertical guide line
        final guidePaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(pos.dx, topPadding), Offset(pos.dx, height), guidePaint);

        // Tooltip text calculation
        String tooltipText;
        if (scrubFraction! < 0.40) {
          final pastD = ((0.45 - scrubFraction!) / 0.45 * 3).round();
          tooltipText = '${pastD}d ago';
        } else if (scrubFraction! < 0.50) {
          tooltipText = 'Now: $currentStock';
        } else {
          final remainingRatio = (scrubFraction! - 0.45) / 0.55;
          final futureDays = daysRemaining != null
              ? (daysRemaining! * (1.0 - remainingRatio)).round()
              : (30 * (1.0 - remainingRatio)).round();
          tooltipText = futureDays <= 0 ? 'Stockout' : '${futureDays}d left';
        }

        // Draw micro tooltip badge
        final textSpan = TextSpan(
          text: tooltipText,
          style: TextStyle(
            color: isBotanical ? const Color(0xFFD1FAE5) : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final tooltipWidth = textPainter.width + 12;
        final tooltipHeight = textPainter.height + 6;
        final tooltipX = (pos.dx - (tooltipWidth / 2)).clamp(2.0, width - tooltipWidth - 2.0);
        final tooltipY = math.max(0.0, pos.dy - tooltipHeight - 6);

        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
          const Radius.circular(4),
        );

        final tooltipBgPaint = Paint()
          ..color = isBotanical ? const Color(0xFF064E3B) : const Color(0xFF1E293B)
          ..style = PaintingStyle.fill;
        final tooltipBorderPaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawRRect(tooltipRect, tooltipBgPaint);
        canvas.drawRRect(tooltipRect, tooltipBorderPaint);

        textPainter.paint(
          canvas,
          Offset(tooltipX + 6, tooltipY + 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.scrubFraction != scrubFraction ||
        oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.currentStock != currentStock ||
        oldDelegate.daysRemaining != daysRemaining;
  }
}
