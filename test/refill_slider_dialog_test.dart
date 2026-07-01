import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/domain/models.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';
import 'package:ivra_refill/src/features/shared/refill_percentage_dialog.dart';
import 'package:ivra_refill/src/features/shared/animated_bottle_refill_indicator.dart';

void main() {
  final testProduct = RoomProduct(
    id: 'test-id',
    hotelId: 'hotel-1',
    roomId: 'room-1',
    roomNumber: '101',
    floorNumber: 1,
    product: const Product(
      id: 'prod-shampoo',
      sku: 'SHAM-01',
      nameEn: 'Shampoo',
      nameFr: 'Shampooing',
      nameAr: 'شامبو',
      nameIt: 'Shampoo',
      bottleVolumeMl: 1000,
      bidonVolumeMl: 5000,
      maxRefillCount: 5,
      maxBottleAgeDays: 365,
      lowBottleThreshold: 20,
      lowBidonThreshold: 10,
    ),
    refillCount: 2,
    lastRefillAt: null,
    bottleStartedAt: DateTime(2026, 6, 1),
    status: BottleStatus.needsRefill,
  );

  Future<void> _pumpDialog(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  testWidgets('RefillPercentageDialog basic rendering and cancellation', (tester) async {
    RefillResult? returnedResult;
    bool dialogOpened = false;

    await _pumpDialog(
      tester,
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              dialogOpened = true;
              returnedResult = await RefillPercentageDialog.show(context, testProduct);
            },
            child: const Text('Open Dialog'),
          );
        },
      ),
    );

    // Click to open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(dialogOpened, isTrue);
    expect(find.byType(RefillPercentageDialog), findsOneWidget);
    expect(find.byType(AnimatedBottleRefillIndicator), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Initial slider value is usually 1.0 (or 100%)
    final Slider slider = tester.widget(find.byType(Slider));
    expect(slider.value, equals(1.0));

    // Drag or tap slider to 50%
    await tester.tap(find.byType(Slider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find cancel button and tap it
    final l10n = AppLocalizations(const Locale('en'));
    final cancelText = l10n.t('btnCancel') ?? 'Cancel';
    expect(find.text(cancelText), findsOneWidget);

    await tester.tap(find.text(cancelText));
    await tester.pump();
    // Allow pop animation to complete fully (500ms)
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog should be closed, result should be null
    expect(find.byType(RefillPercentageDialog), findsNothing);
    expect(returnedResult, isNull);
  });

  testWidgets('RefillPercentageDialog confirmation with custom percentage and notes', (tester) async {
    RefillResult? returnedResult;

    await _pumpDialog(
      tester,
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              returnedResult = await RefillPercentageDialog.show(context, testProduct);
            },
            child: const Text('Open Dialog'),
          );
        },
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Enter notes text
    final notesField = find.byType(TextField);
    expect(notesField, findsOneWidget);
    await tester.enterText(notesField, 'Refilled under supervision');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Confirm refill
    final l10n = AppLocalizations(const Locale('en'));
    final confirmText = l10n.t('dialogRefillConfirm') ?? 'Confirm Refill';
    expect(find.text(confirmText), findsOneWidget);

    await tester.tap(find.text(confirmText));
    await tester.pump();
    // Allow pop animation to complete fully (500ms)
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog should be closed
    expect(find.byType(RefillPercentageDialog), findsNothing);
    expect(returnedResult, isNotNull);
    expect(returnedResult!.refillPercentage, equals(100));
    expect(returnedResult!.notes, equals('Refilled under supervision'));
  });
}
