import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ivra_refill/src/features/alerts/alerts_screen.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/state/app_state.dart';

void main() {
  Widget createWidgetUnderTest({Locale? locale}) {
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
        home: const Scaffold(body: AlertsScreen()),
      ),
    );
  }

  testWidgets('AlertsScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(AlertsScreen), findsOneWidget);
  });

  testWidgets('AlertsScreen Arabic RTL layout rendering without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertsScreen), findsOneWidget);
  });
}
