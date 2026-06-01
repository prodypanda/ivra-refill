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

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final scale = height < 360 ? 0.72 : 1.0;

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showBrand) ...[
                      Image.asset(
                        'assets/images/logo.png',
                        height: 120 * scale,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 24 * scale),
                    ],
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
                    SizedBox(height: 16 * scale),
                    if (widget.message != null || widget.showBrand)
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          final shimmerOpacity = 0.4 +
                              0.6 *
                                  ((math.sin(
                                            _shimmerController.value *
                                                math.pi *
                                                2,
                                          ) +
                                          1) /
                                      2);
                          return Opacity(
                            opacity: shimmerOpacity,
                            child: Text(
                              widget.message ?? 'Loading...',
                              textAlign: TextAlign.center,
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompact(ThemeData theme, Color primary) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
              Flexible(
                child: Text(
                  widget.message!,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
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
                        Color.lerp(
                          const Color(0xFFFFF4D9),
                          primary.withValues(alpha: 0.08),
                          t,
                        )!,
                        const Color(0xFFFFF8F5),
                      ]
                    : [
                        theme.colorScheme.surface,
                        Color.lerp(
                          theme.colorScheme.surface,
                          primary.withValues(alpha: 0.08),
                          t,
                        )!,
                        theme.colorScheme.surface,
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: const _SplashLoadingCard(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _BottomTagline(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLoadingCard extends StatelessWidget {
  const _SplashLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surface.withValues(alpha: isLight ? 0.78 : 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: PremiumLoadingWidget(showBrand: true),
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
          textAlign: TextAlign.center,
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
