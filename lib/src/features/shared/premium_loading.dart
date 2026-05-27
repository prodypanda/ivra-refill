import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A premium, fully-animated loading widget with the Ivra brand identity.
///
/// Features:
/// - Animated brand logo with pulsing glow
/// - Orbiting dots around the brand mark
/// - Animated gradient progress bar
/// - Shimmer text effect
/// - Smooth fade-in entrance animation
class PremiumLoadingWidget extends StatefulWidget {
  const PremiumLoadingWidget({
    super.key,
    this.message,
    this.showBrand = true,
    this.compact = false,
  });

  final String? message;
  final bool showBrand;
  final bool compact;

  @override
  State<PremiumLoadingWidget> createState() => _PremiumLoadingWidgetState();
}

class _PremiumLoadingWidgetState extends State<PremiumLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isLight = theme.brightness == Brightness.light;

    if (widget.compact) {
      return _buildCompact(theme, primary);
    }

    return Center(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated brand logo with orbiting dots
            if (widget.showBrand) ...[
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing glow behind the logo
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.15);
                        final opacity = 0.15 + (_pulseController.value * 0.1);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primary.withValues(alpha: opacity),
                                  primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Brand logo mark
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primary,
                            Color.lerp(primary, Colors.orange.shade700, 0.3)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF92400E).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        'I',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    // Orbiting dots
                    AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(120, 120),
                          painter: _OrbitingDotsPainter(
                            progress: _orbitController.value,
                            color: primary,
                            dotCount: 3,
                            radius: 48,
                            isLight: isLight,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Brand text
            if (widget.showBrand) ...[
              Text(
                'Ivra',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'REFILL MANAGEMENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Animated gradient progress bar
            SizedBox(
              width: 180,
              height: 3,
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: CustomPaint(
                      size: const Size(180, 3),
                      painter: _GradientProgressPainter(
                        progress: _orbitController.value,
                        color: primary,
                        isLight: isLight,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Loading message with shimmer
            if (widget.message != null || widget.showBrand)
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  final shimmerOpacity =
                      0.4 + 0.6 * ((math.sin(_shimmerController.value * math.pi * 2) + 1) / 2);
                  return Opacity(
                    opacity: shimmerOpacity,
                    child: Text(
                      widget.message ?? 'Loading...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
    );
  }

  Widget _buildCompact(ThemeData theme, Color primary) {
    return Center(
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _OrbitingDotsPainter(
                      progress: _orbitController.value,
                      color: primary,
                      dotCount: 3,
                      radius: 10,
                      isLight: theme.brightness == Brightness.light,
                    ),
                  );
                },
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(width: 12),
              Text(
                widget.message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
    );
  }
}

/// Custom painter that draws orbiting dots around a center point.
class _OrbitingDotsPainter extends CustomPainter {
  _OrbitingDotsPainter({
    required this.progress,
    required this.color,
    required this.dotCount,
    required this.radius,
    required this.isLight,
  });

  final double progress;
  final Color color;
  final int dotCount;
  final double radius;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < dotCount; i++) {
      final dotProgress = (progress + (i / dotCount)) % 1.0;
      final angle = dotProgress * 2 * math.pi - (math.pi / 2);

      // Varying size and opacity for trailing effect
      final trailFactor = 1.0 - (i / dotCount) * 0.5;
      final dotRadius = 3.5 * trailFactor;
      final opacity = (0.9 * trailFactor).clamp(0.2, 1.0);

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Add glow around each dot
      final glowPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), dotRadius + 2, glowPaint);
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingDotsPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Custom painter for an animated gradient progress bar.
class _GradientProgressPainter extends CustomPainter {
  _GradientProgressPainter({
    required this.progress,
    required this.color,
    required this.isLight,
  });

  final double progress;
  final Color color;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    // Track background
    final bgPaint = Paint()
      ..color = color.withValues(alpha: isLight ? 0.1 : 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Animated sliding highlight
    final barWidth = size.width * 0.4;
    final startX = (progress * (size.width + barWidth)) - barWidth;

    final gradient = LinearGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.0),
      ],
    );

    final rect = Rect.fromLTWH(startX, 0, barWidth, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(2),
    ));
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradientProgressPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Full-screen splash/loading screen shown on app startup.
class IvraSplashScreen extends StatefulWidget {
  const IvraSplashScreen({super.key});

  @override
  State<IvraSplashScreen> createState() => _IvraSplashScreenState();
}

class _IvraSplashScreenState extends State<IvraSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final t = _bgController.value;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [
                        const Color(0xFFFFF8F5),
                        Color.lerp(const Color(0xFFFFF4D9), primary.withValues(alpha: 0.08), t)!,
                        const Color(0xFFFFF8F5),
                      ]
                    : [
                        theme.colorScheme.surface,
                        Color.lerp(
                            theme.colorScheme.surface,
                            primary.withValues(alpha: 0.08),
                            t)!,
                        theme.colorScheme.surface,
                      ],
              ),
            ),
            child: child,
          );
        },
        child: const SafeArea(
          child: Column(
            children: [
              Spacer(flex: 3),
              PremiumLoadingWidget(showBrand: true),
              Spacer(flex: 4),
              _BottomTagline(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTagline extends StatelessWidget {
  const _BottomTagline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).t('splashTagline'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
