import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'premium_loading.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.builder,
    this.loadingWidget,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loadingWidget ?? 
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: PremiumLoadingWidget(),
            ),
          ),
      error: (error, stackTrace) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

