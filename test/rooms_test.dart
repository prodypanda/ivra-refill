import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/features/rooms/qr_action_screen.dart';
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

  group('RoomsScreen Tests', () {
    testWidgets('RoomsScreen renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const RoomsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RoomsScreen), findsOneWidget);
    });

    testWidgets('RoomsScreen Arabic RTL layout rendering without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const RoomsScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(RoomsScreen), findsOneWidget);
    });
  });

  group('QrActionScreen Tests', () {
    testWidgets('QrActionScreen renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const QrActionScreen(
        hotelSlugOrId: 'hotel-1',
        floor: '1',
        room: '101',
        sku: 'test-sku',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(QrActionScreen), findsOneWidget);
    });

    testWidgets('QrActionScreen Arabic RTL layout rendering without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const QrActionScreen(
        hotelSlugOrId: 'hotel-1',
        floor: '1',
        room: '101',
        sku: 'test-sku',
      ), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(QrActionScreen), findsOneWidget);
    });
  });
}
