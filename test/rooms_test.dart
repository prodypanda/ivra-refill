import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/features/rooms/rooms_screen.dart';
import 'package:ivra_refill/src/features/rooms/qr_action_screen.dart';
import 'package:ivra_refill/src/l10n/app_l10n.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Rooms Screens', () {
    testWidgets('RoomsScreen builds correctly with mock data', (tester) async {
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
            home: Material(child: RoomsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RoomsScreen), findsOneWidget);
    });

    testWidgets('QrActionScreen builds correctly with mock data', (tester) async {
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
            home: Material(child: QrActionScreen(
              hotelSlugOrId: 'hotel-seaside',
              floor: '1',
              room: '101',
              sku: 'sku-shampoo',
            )),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(QrActionScreen), findsOneWidget);
    });
  });
}
