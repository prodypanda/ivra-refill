import 'package:flutter/material.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(title),
          actions: actions,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

