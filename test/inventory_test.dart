import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:ivra_refill/src/features/inventory/femme_de_chambre_screen.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/state/app_state.dart';

void main() {
  Widget createWidgetUnderTest(Widget child, {Locale? locale}) {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(MockIvraRepository()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        home: Scaffold(body: child),
      ),
    );
  }

  group('InventoryScreen Tests', () {
    testWidgets('InventoryScreen renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const InventoryScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryScreen), findsOneWidget);
    });

    testWidgets('InventoryScreen Arabic RTL layout rendering without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const InventoryScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryScreen), findsOneWidget);
    });
  });

  group('FemmeDeChambreScreen Tests', () {
    testWidgets('FemmeDeChambreScreen renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const FemmeDeChambreScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
    });

    testWidgets('FemmeDeChambreScreen Arabic RTL layout rendering without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const FemmeDeChambreScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
    });
  });
}
