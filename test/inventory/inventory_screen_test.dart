import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';

void main() {
  Widget createWidget({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(MockIvraRepository()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(body: InventoryScreen()),
      ),
    );
  }

  group('InventoryScreen Tests', () {
    testWidgets('renders cleanly', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      expect(find.byType(InventoryScreen), findsOneWidget);
    });

    testWidgets('renders RTL (ar) cleanly without overflow', (tester) async {
      await tester.pumpWidget(createWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.byType(InventoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
