import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final effectiveRadius = borderRadius ?? themeExt?.cardBorderRadius ?? 16.0;

    final finalColor = color ??
        (isMobile
            ? theme.colorScheme.surface.withValues(alpha: 0.94)
            : (themeExt?.isBotanical ?? false)
                ? (theme.brightness == Brightness.light
                    ? Colors.white.withValues(alpha: 0.88)
                    : theme.colorScheme.surfaceContainer.withValues(alpha: 0.85))
                : Colors.white.withValues(alpha: 0.7));

    final finalBorderColor = borderColor ??
        (themeExt?.cardBorderColor ??
            (isMobile
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.36)
                : Colors.white.withValues(alpha: 0.4)));

    final defaultShadowColor = themeExt?.cardShadowColor ?? const Color(0xFF92400E);
    final finalShadows = boxShadow ??
        [
          BoxShadow(
            color: defaultShadowColor.withValues(
              alpha: isMobile ? 0.12 : 0.08,
            ),
            blurRadius: isMobile ? 20.0 : 12.0,
            offset: Offset(0, isMobile ? 10 : 4),
          ),
        ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: finalShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: finalColor,
              borderRadius: BorderRadius.circular(effectiveRadius),
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
