import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_state.dart';
import '../account/account_screen.dart';
import '../../app/theme.dart';

class PageScaffold extends ConsumerWidget {
  const PageScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
    this.onRefresh,
    this.maxContentWidth = 1280.0,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final isBotanical = themeExt?.isBotanical ?? false;
    final user = ref.watch(currentUserProvider.select((s) => s.valueOrNull));
    String initials = '';
    if (user != null) {
      final parts = user.fullName.trim().split(RegExp(r'\s+'));
      initials = parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : (parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '');
    }

    final accountButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(AccountScreen.route),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(isBotanical ? 6.0 : 999.0),
              border: isBotanical
                  ? Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1.0,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: user != null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: isBotanical ? 0.5 : 0.0,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 18,
                    color: theme.colorScheme.onPrimary,
                  ),
          ),
        ),
      ),
    );
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final basePadding = width < 420
        ? 16.0
        : width < 720
            ? 20.0
            : 24.0;
    final effectiveHorizontalPadding =
        width > (maxContentWidth + (basePadding * 2))
            ? ((width - maxContentWidth) / 2)
            : basePadding;
    final bottomPadding = isMobile
        ? (104.0 + MediaQuery.paddingOf(context).bottom)
        : 24.0;

    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          toolbarHeight: isMobile ? 84 : kToolbarHeight,
          titleSpacing: effectiveHorizontalPadding,
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: isBotanical ? FontWeight.w600 : FontWeight.w900,
                  letterSpacing: isBotanical ? 0.0 : -0.7,
                ),
          ),
          actions: [
            ...actions,
            accountButton,
            if (effectiveHorizontalPadding > basePadding)
              SizedBox(width: effectiveHorizontalPadding - basePadding),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            effectiveHorizontalPadding,
            isMobile ? 8 : 16,
            effectiveHorizontalPadding,
            bottomPadding,
          ),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );

    if (onRefresh == null) {
      return scrollView;
    }

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh!,
      child: scrollView,
    );
  }
}
