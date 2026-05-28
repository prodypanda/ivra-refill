import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final finalColor = color ??
        (isMobile
            ? theme.colorScheme.surface.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.7));
    final finalBorderColor = borderColor ??
        (isMobile
            ? theme.colorScheme.outlineVariant.withValues(alpha: 0.36)
            : Colors.white.withValues(alpha: 0.4));

    final finalShadows = boxShadow ??
        [
          BoxShadow(
            color: const Color(0xFF92400E).withValues(
              alpha: isMobile ? 0.12 : 0.08,
            ),
            blurRadius: isMobile ? 20.0 : 12.0,
            offset: Offset(0, isMobile ? 10 : 4),
          ),
        ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: finalShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: finalColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: finalBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
