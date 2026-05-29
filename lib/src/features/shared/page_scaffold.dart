import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_state.dart';
import '../account/account_screen.dart';

class PageScaffold extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    String initials = '';
    if (user != null) {
      final parts = user.fullName.trim().split(RegExp(r'\s+'));
      initials = parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : (parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '');
    }

    final accountButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => context.go(AccountScreen.route),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: user != null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
        ),
      ),
    );
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
          actions: [...actions, accountButton],
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
