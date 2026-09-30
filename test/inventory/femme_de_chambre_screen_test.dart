import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/features/inventory/femme_de_chambre_screen.dart';
import 'package:ivra_refill/src/state/app_state.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';

void main() {
  Widget createWidget({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(MockIvraRepository()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(body: FemmeDeChambreScreen()),
      ),
    );
  }

  group('FemmeDeChambreScreen Tests', () {
    testWidgets('renders cleanly', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
    });

    testWidgets('renders RTL (ar) cleanly without overflow', (tester) async {
      await tester.pumpWidget(createWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.byType(FemmeDeChambreScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
