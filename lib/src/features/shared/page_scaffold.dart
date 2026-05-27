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
    final horizontalPadding = width < 420
        ? 12.0
        : width < 720
            ? 16.0
            : 24.0;

    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(title, overflow: TextOverflow.ellipsis),
          actions: actions,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
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
