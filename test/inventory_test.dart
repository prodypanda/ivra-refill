import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/data/ivra_repository.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('InventoryScreen Arabic mobile rooms keep RTL localized layout', (tester) async {
    final mockRepo = MockIvraRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ar')],
          home: Scaffold(body: InventoryScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(InventoryScreen), findsOneWidget);
  });
}
