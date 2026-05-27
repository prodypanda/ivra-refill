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
    final finalColor = color ?? Colors.white.withValues(alpha: 0.7);
    final finalBorderColor = borderColor ?? Colors.white.withValues(alpha: 0.4);
    
    final finalShadows = boxShadow ?? [
      BoxShadow(
        color: const Color(0xFF92400E).withValues(alpha: 0.08),
        blurRadius: 12.0,
        offset: const Offset(0, 4),
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
