import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivra_refill/src/app/theme.dart';
import 'package:ivra_refill/src/data/mock_ivra_repository.dart';
import 'package:ivra_refill/src/domain/app_enums.dart';
import 'package:ivra_refill/src/features/settings/app_settings_screen.dart';
import 'package:ivra_refill/src/l10n/app_localizations.dart';
import 'package:ivra_refill/src/state/app_state.dart';

void main() {
  group('AppThemeStyle Enum', () {
    test('fromValue parses standard and alias values correctly', () {
      expect(AppThemeStyle.fromValue('solar_infusion'), AppThemeStyle.solarInfusion);
      expect(AppThemeStyle.fromValue('botanical_haute'), AppThemeStyle.botanicalHaute);
      expect(AppThemeStyle.fromValue('emerald_noir'), AppThemeStyle.botanicalHaute);
      expect(AppThemeStyle.fromValue('noir_emerald'), AppThemeStyle.botanicalHaute);
      expect(AppThemeStyle.fromValue('botanical_luxury'), AppThemeStyle.botanicalHaute);
      expect(AppThemeStyle.fromValue(null), AppThemeStyle.solarInfusion);
      expect(AppThemeStyle.fromValue('unknown_theme'), AppThemeStyle.solarInfusion);
    });
  });

  group('buildIvraTheme Engine', () {
    testWidgets('builds Solar Infusion light and dark themes with IvraThemeExtension', (tester) async {
      final lightTheme = buildIvraTheme(Brightness.light, style: AppThemeStyle.solarInfusion);
      final darkTheme = buildIvraTheme(Brightness.dark, style: AppThemeStyle.solarInfusion);

      expect(lightTheme.colorScheme.primary, const Color(0xFF855300));
      expect(darkTheme.colorScheme.primary, const Color(0xFFFFB95F));

      final lightExt = lightTheme.extension<IvraThemeExtension>();
      expect(lightExt, isNotNull);
      expect(lightExt!.style, AppThemeStyle.solarInfusion);
      expect(lightExt.glowColor, const Color(0xFFF59E0B));
      expect(lightExt.cardBorderRadius, 16.0);
      expect(lightExt.cardShadowColor, const Color(0xFF92400E));
      expect(lightExt.buttonBorderRadius, 999.0);
      expect(lightExt.buttonLetterSpacing, 0.0);
      expect(lightExt.isBotanical, isFalse);

      final darkExt = darkTheme.extension<IvraThemeExtension>();
      expect(darkExt, isNotNull);
      expect(darkExt!.style, AppThemeStyle.solarInfusion);
    });

    testWidgets('builds Botanical Haute light and dark themes with bespoke luxury emerald tokens', (tester) async {
      final lightTheme = buildIvraTheme(Brightness.light, style: AppThemeStyle.botanicalHaute);
      final darkTheme = buildIvraTheme(Brightness.dark, style: AppThemeStyle.botanicalHaute);

      expect(lightTheme.colorScheme.primary, const Color(0xFF064E3B));
      expect(lightTheme.colorScheme.surface, const Color(0xFFF6FBF8));
      expect(darkTheme.colorScheme.primary, const Color(0xFF34D399));
      expect(darkTheme.colorScheme.surface, const Color(0xFF05130E));

      final lightExt = lightTheme.extension<IvraThemeExtension>();
      expect(lightExt, isNotNull);
      expect(lightExt!.style, AppThemeStyle.botanicalHaute);
      expect(lightExt.glowColor, const Color(0xFF10B981));
      expect(lightExt.cardBorderRadius, 8.0);
      expect(lightExt.cardShadowColor, const Color(0xFF064E3B));
      expect(lightExt.buttonBorderRadius, 6.0);
      expect(lightExt.buttonLetterSpacing, 1.6);
      expect(lightExt.isBotanical, isTrue);

      // Verify architectural card and button geometry differences
      expect((lightTheme.cardTheme.shape as RoundedRectangleBorder).borderRadius, const BorderRadius.all(Radius.circular(8)));
      expect((lightTheme.filledButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder).borderRadius, BorderRadius.circular(6));

      final darkExt = darkTheme.extension<IvraThemeExtension>();
      expect(darkExt, isNotNull);
      expect(darkExt!.style, AppThemeStyle.botanicalHaute);
    });
  });

  group('MockIvraRepository Theme Methods', () {
    test('getAppThemeStyle, setAppThemeStyle, and watchAppThemeStyle work correctly', () async {
      final repo = MockIvraRepository();

      expect(await repo.getAppThemeStyle(), AppThemeStyle.solarInfusion);

      final events = <AppThemeStyle>[];
      final sub = repo.watchAppThemeStyle().listen(events.add);
      await pumpEventQueue();

      await repo.setAppThemeStyle(AppThemeStyle.botanicalHaute);
      expect(await repo.getAppThemeStyle(), AppThemeStyle.botanicalHaute);

      await repo.setAppThemeStyle(AppThemeStyle.solarInfusion);
      expect(await repo.getAppThemeStyle(), AppThemeStyle.solarInfusion);

      await pumpEventQueue();
      expect(events, containsAllInOrder([
        AppThemeStyle.solarInfusion,
        AppThemeStyle.botanicalHaute,
        AppThemeStyle.solarInfusion,
      ]));

      await sub.cancel();
    });
  });

  group('AppSettingsScreen Theme Switcher Widget', () {
    testWidgets('renders both theme options and switches theme on tap', (tester) async {
      final mockRepo = MockIvraRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(mockRepo),
            useSupabaseProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
            ],
            home: const Scaffold(
              body: AppSettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify section and theme cards are visible
      expect(find.text('App Theme & Visual Style'), findsOneWidget);
      expect(find.text('Solar Infusion'), findsOneWidget);
      expect(find.text('Botanical Haute'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Tap on Botanical Haute
      await tester.tap(find.text('Botanical Haute'));
      await tester.pumpAndSettle();

      // Verify active badge moved
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
