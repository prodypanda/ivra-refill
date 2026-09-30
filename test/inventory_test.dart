import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/features/inventory/inventory_screen.dart';
import 'package:ivra_refill/src/features/inventory/femme_de_chambre_screen.dart';
import 'package:ivra_refill/src/l10n/app_l10n.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Inventory Screens', () {
    testWidgets('InventoryScreen builds correctly with mock data', (tester) async {
      final mockRepository = MockIvraRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            locale: Locale('ar'), // Verify RTL
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Material(child: InventoryScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(InventoryScreen), findsOneWidget);
    });

    testWidgets('FemmeDeChambreScreen builds correctly with mock data', (tester) async {
      final mockRepository = MockIvraRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            locale: Locale('ar'), // Verify RTL
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Material(child: FemmeDeChambreScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
    });
  });
}
