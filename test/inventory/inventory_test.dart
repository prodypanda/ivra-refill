import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:ivra_refill/src/features/inventory/femme_de_chambre_screen.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';

void main() {
  group('InventoryScreen Tests', () {
    testWidgets('Builds cleanly in mock ProviderScope', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InventoryScreen()),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('ar'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(InventoryScreen), findsOneWidget);
    });

    testWidgets('RTL rendering does not throw overflow exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: Scaffold(body: InventoryScreen()),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('ar'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(InventoryScreen), findsOneWidget);
    });
  });

  group('FemmeDeChambreScreen Tests', () {
    testWidgets('Builds cleanly in mock ProviderScope', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: FemmeDeChambreScreen()),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('ar'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
    });

    testWidgets('RTL rendering does not throw overflow exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: Scaffold(body: FemmeDeChambreScreen()),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('ar'),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
    });
  });
}
