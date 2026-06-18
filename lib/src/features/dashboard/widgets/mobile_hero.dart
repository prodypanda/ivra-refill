import 'package:flutter/material.dart';
import '../../../domain/models.dart';
import '../../../l10n/app_localizations.dart';

class MobileHero extends StatefulWidget {
  const MobileHero({required this.data, super.key});

  final DashboardMetrics data;

  @override
  State<MobileHero> createState() => _MobileHeroState();
}

class _MobileHeroState extends State<MobileHero> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withRed(220).withGreen(120),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -20,
              top: -20,
              child: Icon(
                Icons.spa,
                size: 140,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.insights, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                l10n.t('dashboardHeroTitle'),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          icon: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white,
                          ),
                          tooltip: _isExpanded ? l10n.t('collapse') : l10n.t('expand'),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0, width: double.infinity),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          widget.data.bottlesToReplace.toString(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          l10n.t('metricBottlesToReplace'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            HeroPill(
                              label: l10n.t('metricOpenAlerts'),
                              value: widget.data.openAlerts,
                              icon: Icons.notifications_active,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            HeroPill(
                              label: l10n.t('metricPendingApprovals'),
                              value: widget.data.pendingApprovals,
                              icon: Icons.fact_check,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroPill extends StatelessWidget {
  const HeroPill({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    super.key,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = color ?? theme.colorScheme.onSurface;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: foregroundColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$value ${label.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
