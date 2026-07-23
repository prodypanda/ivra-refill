import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/features/approvals/approvals_screen.dart';
import 'package:ivra_refill/src/l10n/app_l10n.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ApprovalsScreen builds correctly with mock data', (tester) async {
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
          home: Material(child: ApprovalsScreen()),
        ),
      ),
    );

    // Give the async data a frame to load.
    await tester.pumpAndSettle();

    // Verify it built without overflowing
    expect(find.byType(ApprovalsScreen), findsOneWidget);
  });
}
