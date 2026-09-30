import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/features/rooms/qr_action_screen.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';

void main() {
  group('RoomsScreen Tests', () {
    testWidgets('Builds cleanly in mock ProviderScope', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RoomsScreen()),
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

      expect(find.byType(RoomsScreen), findsOneWidget);
    });

    testWidgets('RTL rendering does not throw overflow exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: Scaffold(body: RoomsScreen()),
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

      expect(find.byType(RoomsScreen), findsOneWidget);
    });
  });

  group('QrActionScreen Tests', () {
    testWidgets('Builds cleanly in mock ProviderScope', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: QrActionScreen(hotelSlugOrId: 'h1', floor: '1', room: '101', sku: 'SHAMPOO-01')),
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

      expect(find.byType(QrActionScreen), findsOneWidget);
    });

    testWidgets('RTL rendering does not throw overflow exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(MockIvraRepository()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: Scaffold(body: QrActionScreen(hotelSlugOrId: 'h1', floor: '1', room: '101', sku: 'SHAMPOO-01')),
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

      expect(find.byType(QrActionScreen), findsOneWidget);
    });
  });
}
