import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isCelebratory = false,
    this.celebratoryBadge,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isCelebratory;
  final String? celebratoryBadge;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final isBotanical = themeExt?.isBotanical ?? false;
    final primary = theme.colorScheme.primary;
    final accentColor = widget.isCelebratory
        ? (themeExt?.success ?? primary)
        : primary;

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with layered luxury gradient ring and soft aura
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (widget.isCelebratory)
                      BoxShadow(
                        color: accentColor.withValues(alpha: isBotanical ? 0.22 : 0.16),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: widget.isCelebratory ? 0.25 : 0.15),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: widget.isCelebratory ? 0.12 : 0.08),
                    shape: BoxShape.circle,
                    border: widget.isCelebratory
                        ? Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 56,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.celebratoryBadge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: themeExt?.successContainer ?? accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(isBotanical ? 6 : 16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: themeExt?.onSuccessContainer ?? accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.celebratoryBadge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: themeExt?.onSuccessContainer ?? accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.actionLabel != null &&
                  widget.onAction != null) ...[
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onAction!();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(widget.actionLabel!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          themeExt?.buttonBorderRadius ?? 14.0),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return content;
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: content,
      ),
    );
  }
}
