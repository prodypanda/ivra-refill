import 'package:flutter/material.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
    this.onRefresh,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final horizontalPadding = width < 420
        ? 16.0
        : width < 720
            ? 20.0
            : 24.0;
    final bottomPadding = isMobile ? 104.0 : 24.0;

    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          toolbarHeight: isMobile ? 84 : kToolbarHeight,
          titleSpacing: horizontalPadding,
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
          ),
          actions: actions,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isMobile ? 8 : 16,
            horizontalPadding,
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
