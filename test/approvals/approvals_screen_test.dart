import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivra_refill/src/features/approvals/approvals_screen.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';

void main() {
  testWidgets('ApprovalsScreen smoke test - Arabic locale', (WidgetTester tester) async {
    final mockRepo = MockIvraRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          home: const Scaffold(body: ApprovalsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ApprovalsScreen), findsOneWidget);
  });
}
