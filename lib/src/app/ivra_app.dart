import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../features/shared/premium_loading.dart';
import '../l10n/app_localizations.dart';
import '../routing/app_router.dart';
import '../state/app_state.dart';
import 'deep_link_listener.dart';
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
        return DeepLinkListener(
          child: _GlobalSplashGate(child: child!),
        );
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
    // Auto-scope hotel-bound users (staff/manager whose UserProfile.hotelId is
    // set) to their own hotel as soon as their profile resolves, and re-scope
    // whenever the signed-in user changes. App-wide users (admin, manager
    // without a hotelId) keep the cross-hotel view (selectedHotelId stays
    // null) so each screen can show aggregate data.
    ref.listen<AsyncValue<UserProfile>>(currentUserProvider, (prev, next) {
      final nextUser = next.valueOrNull;
      final prevUserId = prev?.valueOrNull?.id;
      final userChanged = prevUserId != null && prevUserId != nextUser?.id;
      final selected = ref.read(selectedHotelIdProvider);
      final hotelId = nextUser?.hotelId;
      if (hotelId != null && (selected == null || userChanged)) {
        ref.read(selectedHotelIdProvider.notifier).state = hotelId;
      } else if (userChanged && hotelId == null) {
        ref.read(selectedHotelIdProvider.notifier).state = null;
      }
      // When the signed-in user changes (sign in as a different account, or
      // sign out), drop the previous account's cached data so the new account
      // sees fresh results without needing a manual pull-to-refresh.
      if (userChanged) {
        invalidateAccountScopedData(ref);
      }
    });

    final currentUserAsync = ref.watch(currentUserProvider);

    if (currentUserAsync.isLoading && !currentUserAsync.hasValue) {
      return const IvraSplashScreen();
    }
    return widget.child;
  }
}
