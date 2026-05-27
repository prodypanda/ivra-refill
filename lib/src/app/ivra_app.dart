import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shared/premium_loading.dart';
import '../l10n/app_localizations.dart';
import '../routing/app_router.dart';
import '../state/app_state.dart';
import 'theme.dart';

class IvraApp extends ConsumerWidget {
  const IvraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Ivra',
      debugShowCheckedModeBanner: false,
      theme: buildIvraTheme(Brightness.light),
      darkTheme: buildIvraTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _GlobalSplashGate(child: child!);
      },
      routerConfig: router,
    );
  }
}

class _GlobalSplashGate extends ConsumerStatefulWidget {
  final Widget child;
  const _GlobalSplashGate({required this.child});

  @override
  ConsumerState<_GlobalSplashGate> createState() => _GlobalSplashGateState();
}

class _GlobalSplashGateState extends ConsumerState<_GlobalSplashGate> {
  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    if (currentUserAsync.isLoading && !currentUserAsync.hasValue) {
      return const IvraSplashScreen();
    }
    return widget.child;
  }
}

