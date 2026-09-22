import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/app_enums.dart';

/// Bespoke theme extension holding brand-specific visual tokens such as
/// ambient background gradients, glow colors, and crystalline card borders.
@immutable
class IvraThemeExtension extends ThemeExtension<IvraThemeExtension> {
  const IvraThemeExtension({
    required this.style,
    required this.backgroundGradient,
    required this.glowColor,
    required this.cardBorderColor,
    required this.badgeBackgroundColor,
    required this.badgeForegroundColor,
    required this.accentGlow,
    required this.cardBorderRadius,
    required this.cardShadowColor,
    required this.buttonBorderRadius,
    required this.buttonLetterSpacing,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final AppThemeStyle style;
  final LinearGradient backgroundGradient;
  final Color glowColor;
  final Color cardBorderColor;
  final Color badgeBackgroundColor;
  final Color badgeForegroundColor;
  final Color accentGlow;
  final double cardBorderRadius;
  final Color cardShadowColor;
  final double buttonBorderRadius;
  final double buttonLetterSpacing;

  // Semantic color roles
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color shimmerBase;
  final Color shimmerHighlight;

  bool get isBotanical => style == AppThemeStyle.botanicalHaute;

  @override
  IvraThemeExtension copyWith({
    AppThemeStyle? style,
    LinearGradient? backgroundGradient,
    Color? glowColor,
    Color? cardBorderColor,
    Color? badgeBackgroundColor,
    Color? badgeForegroundColor,
    Color? accentGlow,
    double? cardBorderRadius,
    Color? cardShadowColor,
    double? buttonBorderRadius,
    double? buttonLetterSpacing,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return IvraThemeExtension(
      style: style ?? this.style,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glowColor: glowColor ?? this.glowColor,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      badgeBackgroundColor: badgeBackgroundColor ?? this.badgeBackgroundColor,
      badgeForegroundColor: badgeForegroundColor ?? this.badgeForegroundColor,
      accentGlow: accentGlow ?? this.accentGlow,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonLetterSpacing: buttonLetterSpacing ?? this.buttonLetterSpacing,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  IvraThemeExtension lerp(ThemeExtension<IvraThemeExtension>? other, double t) {
    if (other is! IvraThemeExtension) return this;
    return IvraThemeExtension(
      style: t < 0.5 ? style : other.style,
      backgroundGradient: LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t) ?? backgroundGradient,
      glowColor: Color.lerp(glowColor, other.glowColor, t) ?? glowColor,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t) ?? cardBorderColor,
      badgeBackgroundColor: Color.lerp(badgeBackgroundColor, other.badgeBackgroundColor, t) ?? badgeBackgroundColor,
      badgeForegroundColor: Color.lerp(badgeForegroundColor, other.badgeForegroundColor, t) ?? badgeForegroundColor,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t) ?? accentGlow,
      cardBorderRadius: lerpDouble(cardBorderRadius, other.cardBorderRadius, t) ?? cardBorderRadius,
      cardShadowColor: Color.lerp(cardShadowColor, other.cardShadowColor, t) ?? cardShadowColor,
      buttonBorderRadius: lerpDouble(buttonBorderRadius, other.buttonBorderRadius, t) ?? buttonBorderRadius,
      buttonLetterSpacing: lerpDouble(buttonLetterSpacing, other.buttonLetterSpacing, t) ?? buttonLetterSpacing,
      success: Color.lerp(success, other.success, t) ?? success,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      successContainer: Color.lerp(successContainer, other.successContainer, t) ?? successContainer,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ?? onSuccessContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? onWarning,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t) ?? warningContainer,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t) ?? onWarningContainer,
      info: Color.lerp(info, other.info, t) ?? info,
      onInfo: Color.lerp(onInfo, other.onInfo, t) ?? onInfo,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t) ?? infoContainer,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t) ?? onInfoContainer,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t) ?? shimmerBase,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t) ?? shimmerHighlight,
    );
  }
}

extension IvraSemanticColors on ThemeData {
  IvraThemeExtension? get ivraExt => extension<IvraThemeExtension>();
  Color get successColor => ivraExt?.success ?? const Color(0xFF10B981);
  Color get warningColor => ivraExt?.warning ?? const Color(0xFFF59E0B);
  Color get infoColor => ivraExt?.info ?? const Color(0xFF0284C7);
}

/// Fallback font list supporting Arabic (Cairo, Noto Sans Arabic) and clean platform fallbacks.
const List<String> kIvraFontFallback = [
  'Cairo',
  'Noto Sans Arabic',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'sans-serif',
];

/// Typographic extensions for tabular numerals and data-dense layouts.
extension IvraTextStyleX on TextStyle? {
  /// Returns a copy of the [TextStyle] with [FontFeature.tabularFigures()] enabled,
  /// ensuring monospaced number alignment in metrics, stock levels, and data tables.
  TextStyle withTabularFigures() {
    final base = this ?? const TextStyle();
    final existingFeatures = base.fontFeatures ?? const <FontFeature>[];
    return base.copyWith(
      fontFeatures: [
        ...existingFeatures.where((f) => f.feature != 'tnum'),
        const FontFeature.tabularFigures(),
      ],
    );
  }
}

ThemeData buildIvraTheme(
  Brightness brightness, {
  AppThemeStyle style = AppThemeStyle.solarInfusion,
}) {
  final isLight = brightness == Brightness.light;

  return switch (style) {
    AppThemeStyle.solarInfusion => _buildSolarInfusionTheme(brightness, isLight),
    AppThemeStyle.botanicalHaute => _buildBotanicalHauteTheme(brightness, isLight),
  };
}

/// 1. Solar Infusion Theme (Warm Mediterranean Amber & Golden Cream)
ThemeData _buildSolarInfusionTheme(Brightness brightness, bool isLight) {
  final colorScheme = isLight
      ? const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF855300),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFF59E0B),
          onPrimaryContainer: Color(0xFF613B00),
          secondary: Color(0xFF665F3D),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFEAE0B5),
          onSecondaryContainer: Color(0xFF6A6341),
          tertiary: Color(0xFF605F53),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFB4B1A3),
          onTertiaryContainer: Color(0xFF454439),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          surface: Color(0xFFFFF8F5),
          onSurface: Color(0xFF1F1B17),
          surfaceContainerLow: Color(0xFFFCF2EB),
          surfaceContainer: Color(0xFFF6ECE6),
          surfaceContainerHigh: Color(0xFFF0E6E0),
          surfaceContainerHighest: Color(0xFFEAE1DA),
          onSurfaceVariant: Color(0xFF534434),
          outline: Color(0xFF867461),
          outlineVariant: Color(0xFFD8C3AD),
        )
      : const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFFB95F),
          onPrimary: Color(0xFF472A00),
          primaryContainer: Color(0xFF653E00),
          onPrimaryContainer: Color(0xFFFFDDB8),
          secondary: Color(0xFFD1C79D),
          onSecondary: Color(0xFF363013),
          secondaryContainer: Color(0xFF4D4727),
          onSecondaryContainer: Color(0xFFEDE3B8),
          tertiary: Color(0xFFCAC7B8),
          onTertiary: Color(0xFF323127),
          tertiaryContainer: Color(0xFF48473C),
          onTertiaryContainer: Color(0xFFE6E3D3),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF1F1B17),
          onSurface: Color(0xFFEAE1DA),
          onSurfaceVariant: Color(0xFFD8C3AD),
          outline: Color(0xFF9F8E7D),
          outlineVariant: Color(0xFF534434),
        );

  final customExt = IvraThemeExtension(
    style: AppThemeStyle.solarInfusion,
    backgroundGradient: isLight
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F5),
              Color(0xFFFFF4D9),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1B17),
              Color(0xFF2A231D),
            ],
          ),
    glowColor: const Color(0xFFF59E0B),
    cardBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
    badgeBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
    badgeForegroundColor: const Color(0xFF855300),
    accentGlow: const Color(0xFFF59E0B).withValues(alpha: 0.4),
    cardBorderRadius: 16.0,
    cardShadowColor: const Color(0xFF92400E),
    buttonBorderRadius: 999.0,
    buttonLetterSpacing: 0.0,
    success: isLight ? const Color(0xFF2E6B34) : const Color(0xFF81C784),
    onSuccess: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F3814),
    successContainer: isLight ? const Color(0xFFD5ECD5) : const Color(0xFF1B4321),
    onSuccessContainer: isLight ? const Color(0xFF0F3814) : const Color(0xFFB2E2B5),
    warning: isLight ? const Color(0xFFB45309) : const Color(0xFFFFB74D),
    onWarning: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF422200),
    warningContainer: isLight ? const Color(0xFFFEF3C7) : const Color(0xFF5D3500),
    onWarningContainer: isLight ? const Color(0xFF451A03) : const Color(0xFFFFDDB8),
    info: isLight ? const Color(0xFF1D5A85) : const Color(0xFF82B6E6),
    onInfo: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF00324E),
    infoContainer: isLight ? const Color(0xFFD6EEFF) : const Color(0xFF004971),
    onInfoContainer: isLight ? const Color(0xFF00344F) : const Color(0xFFC7E7FF),
    shimmerBase: isLight ? const Color(0xFFF2E7DC) : const Color(0xFF2B241D),
    shimmerHighlight: isLight ? const Color(0xFFFFF8F3) : const Color(0xFF3B3229),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [customExt],
    textTheme: _buildSolarInfusionTextTheme(brightness, colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      dataTextStyle: TextStyle(
        color: colorScheme.onSurface,
      ),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      elevation: 0,
      color: isLight
          ? Colors.white.withValues(alpha: 0.7)
          : colorScheme.surface.withValues(alpha: 0.8),
      shadowColor: const Color(0xFF92400E).withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight
          ? const Color(0xFFFCF2EB)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: colorScheme.primary),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFF59E0B), width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 2,
        shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: const Color(0xFF855300),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.24),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: selected ? 26 : 24,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isLight ? const Color(0xFFFFF8F5) : colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isLight ? const Color(0xFFFFF8F5).withValues(alpha: 0.5) : null,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        fontSize: 12,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: isLight ? const Color(0xFFFFF8F5) : null,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFFF59E0B),
      selectionColor: const Color(0xFFF59E0B).withValues(alpha: 0.28),
      selectionHandleColor: const Color(0xFFF59E0B),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return const Color(0xFFF59E0B).withValues(alpha: 0.6);
        }
        return const Color(0xFFF59E0B).withValues(alpha: 0.25);
      }),
      trackColor: const WidgetStatePropertyAll(Colors.transparent),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered) ? 8.0 : 5.0,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontSize: 13),
    ),
    focusColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
  );
}

/// 2. Botanical Haute Theme (Awwwards-Level Luxury Midnight Emerald & Radiant Mint)
ThemeData _buildBotanicalHauteTheme(Brightness brightness, bool isLight) {
  final colorScheme = isLight
      ? const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF064E3B), // Deep Imperial Emerald
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFF10B981), // Luminous Mint Jade
          onPrimaryContainer: Color(0xFF022C22),
          secondary: Color(0xFF2D4F44), // Forest Slate
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFD1FAE5), // Pale Mint Glass
          onSecondaryContainer: Color(0xFF063E30),
          tertiary: Color(0xFFB45309), // Warm Champagne Bronze
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFFEF3C7),
          onTertiaryContainer: Color(0xFF451A03),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          surface: Color(0xFFF6FBF8), // Porcelain Alabaster with soft mint mist
          onSurface: Color(0xFF051C15), // Deep Forest Obsidian
          surfaceContainerLow: Color(0xFFEFF7F3),
          surfaceContainer: Color(0xFFE8F5EF),
          surfaceContainerHigh: Color(0xFFE0EFE8),
          surfaceContainerHighest: Color(0xFFD5E8DF),
          onSurfaceVariant: Color(0xFF354E44),
          outline: Color(0xFF5C7C70),
          outlineVariant: Color(0xFFA7D7C5),
        )
      : const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF34D399), // Radiant Mint Emerald
          onPrimary: Color(0xFF022C22),
          primaryContainer: Color(0xFF064E3B), // Deep Forest Pine
          onPrimaryContainer: Color(0xFFA7F3D0),
          secondary: Color(0xFF81C9B0), // Soft Mint Sage
          onSecondary: Color(0xFF07271F),
          secondaryContainer: Color(0xFF13382D),
          onSecondaryContainer: Color(0xFFC7EFE2),
          tertiary: Color(0xFFFCD34D), // Champagne Gold
          onTertiary: Color(0xFF451A03),
          tertiaryContainer: Color(0xFF78350F),
          onTertiaryContainer: Color(0xFFFEF3C7),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF0B1411), // Calm Deep Obsidian Jade (softened from harsh 0xFF05130E)
          onSurface: Color(0xFFECFDF5), // Crisp Mint White
          surfaceContainerLow: Color(0xFF0E1A16),
          surfaceContainer: Color(0xFF12221D),
          surfaceContainerHigh: Color(0xFF172B25),
          surfaceContainerHighest: Color(0xFF1D352E),
          onSurfaceVariant: Color(0xFF94B8AA),
          outline: Color(0xFF3F6E5D),
          outlineVariant: Color(0xFF1C4134),
        );

  final customExt = IvraThemeExtension(
    style: AppThemeStyle.botanicalHaute,
    backgroundGradient: isLight
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6FBF8),
              Color(0xFFE5F5ED),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1411),
              Color(0xFF0F1B17),
            ],
          ),
    glowColor: const Color(0xFF10B981).withValues(alpha: 0.08),
    cardBorderColor: isLight
        ? const Color(0xFF10B981).withValues(alpha: 0.14)
        : const Color(0xFF34D399).withValues(alpha: 0.12),
    badgeBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.10),
    badgeForegroundColor:
        isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
    accentGlow: const Color(0xFF10B981).withValues(alpha: 0.08),
    cardBorderRadius: 8.0,
    cardShadowColor: const Color(0xFF021B14).withValues(alpha: 0.06),
    buttonBorderRadius: 6.0,
    buttonLetterSpacing: 1.2,
    success: isLight ? const Color(0xFF065F46) : const Color(0xFF34D399),
    onSuccess: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF022C22),
    successContainer: isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B),
    onSuccessContainer: isLight ? const Color(0xFF022C22) : const Color(0xFFA7F3D0),
    warning: isLight ? const Color(0xFFB45309) : const Color(0xFFFCD34D),
    onWarning: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF451A03),
    warningContainer: isLight ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
    onWarningContainer: isLight ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
    info: isLight ? const Color(0xFF0F5B68) : const Color(0xFF5EEAD4),
    onInfo: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF00373E),
    infoContainer: isLight ? const Color(0xFFCCF2F4) : const Color(0xFF0F4E56),
    onInfoContainer: isLight ? const Color(0xFF02363E) : const Color(0xFFA5F3FC),
    shimmerBase: isLight ? const Color(0xFFE3EFE8) : const Color(0xFF14241E),
    shimmerHighlight: isLight ? const Color(0xFFF2FBF6) : const Color(0xFF1D352C),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [customExt],
    textTheme: _buildBotanicalHauteTextTheme(brightness, colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor:
          isLight ? const Color(0xFFE5F5ED) : const Color(0xFF122820),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: BorderSide(
        color: isLight
            ? const Color(0xFF10B981).withValues(alpha: 0.20)
            : const Color(0xFF34D399).withValues(alpha: 0.18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isLight ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
        letterSpacing: 0.6,
        fontSize: 11.5,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.primary,
      textColor: colorScheme.onSurface,
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.2,
      ),
      dataTextStyle: TextStyle(
        color: colorScheme.onSurface,
      ),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    // Architectural Crystalline Luxury Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: isLight
          ? Colors.white.withValues(alpha: 0.90)
          : colorScheme.surfaceContainer.withValues(alpha: 0.85),
      shadowColor: const Color(0xFF021B14).withValues(alpha: 0.04),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        side: BorderSide(
          color: isLight
              ? const Color(0xFF10B981).withValues(alpha: 0.14)
              : const Color(0xFF34D399).withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight
          ? const Color(0xFFEFF8F4)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(
        color: isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      hintStyle:
          TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.20)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(
          color: isLight
              ? const Color(0xFF10B981).withValues(alpha: 0.18)
              : const Color(0xFF34D399).withValues(alpha: 0.16),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(
          color: const Color(0xFF10B981).withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    // Architectural Luxury Buttons with tracked lettering
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor:
            isLight ? const Color(0xFF064E3B) : const Color(0xFF10B981),
        foregroundColor:
            isLight ? const Color(0xFFECFDF5) : const Color(0xFF022C22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.0,
          letterSpacing: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        foregroundColor:
            isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
        side: BorderSide(
          color: isLight
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFF34D399).withValues(alpha: 0.4),
          width: 1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.0,
          letterSpacing: 1.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
            isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.0,
          letterSpacing: 0.8,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: 0.4,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: selected ? 25 : 24,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isLight ? const Color(0xFFF6FBF8) : colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor:
          isLight ? const Color(0xFFF6FBF8).withValues(alpha: 0.7) : null,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.12),
      selectedIconTheme: IconThemeData(
        color: isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.6,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        fontSize: 11.5,
        letterSpacing: 0.3,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isLight
              ? const Color(0xFF10B981).withValues(alpha: 0.14)
              : const Color(0xFF34D399).withValues(alpha: 0.12),
        ),
      ),
      backgroundColor:
          isLight ? const Color(0xFFF6FBF8) : colorScheme.surfaceContainer,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: isLight ? const Color(0xFF064E3B) : const Color(0xFF10B981),
      selectionColor: (isLight ? const Color(0xFF10B981) : const Color(0xFF34D399))
          .withValues(alpha: 0.24),
      selectionHandleColor:
          isLight ? const Color(0xFF064E3B) : const Color(0xFF10B981),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        final color = isLight ? const Color(0xFF064E3B) : const Color(0xFF10B981);
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return color.withValues(alpha: 0.6);
        }
        return color.withValues(alpha: 0.25);
      }),
      trackColor: const WidgetStatePropertyAll(Colors.transparent),
      radius: const Radius.circular(3),
      thickness: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered) ? 7.0 : 4.0,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
      labelColor: isLight ? const Color(0xFF064E3B) : const Color(0xFF34D399),
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.6,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.3,
      ),
    ),
    focusColor: const Color(0xFF10B981).withValues(alpha: 0.15),
  );
}

/// Factory building calibrated typography for Solar Infusion (Plus Jakarta Sans).
TextTheme _buildSolarInfusionTextTheme(Brightness brightness, ColorScheme colorScheme) {
  final base = GoogleFonts.plusJakartaSansTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.12,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.15,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.18,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.20,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      height: 1.22,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.25,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      height: 1.30,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
      height: 1.35,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.35,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.50,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.05,
      height: 1.45,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.40,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      height: 1.20,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
      height: 1.20,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      height: 1.20,
    ),
  ).apply(
    fontFamilyFallback: kIvraFontFallback,
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
}

/// Factory building calibrated typography for Botanical Haute (Cormorant Garamond + Outfit).
TextTheme _buildBotanicalHauteTextTheme(Brightness brightness, ColorScheme colorScheme) {
  final baseTextTheme = GoogleFonts.outfitTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  return baseTextTheme.copyWith(
    displayLarge: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.10,
      ),
    ),
    displayMedium: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.displayMedium?.copyWith(
        fontSize: 38,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.14,
      ),
    ),
    displaySmall: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.displaySmall?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.18,
      ),
    ),
    headlineLarge: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.20,
      ),
    ),
    headlineMedium: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.22,
      ),
    ),
    headlineSmall: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.25,
      ),
    ),
    titleLarge: GoogleFonts.cormorantGaramond(
      textStyle: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.28,
      ),
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.35,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.35,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.10,
      height: 1.45,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.20,
      height: 1.40,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      height: 1.20,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      height: 1.20,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      height: 1.20,
    ),
  ).apply(
    fontFamilyFallback: kIvraFontFallback,
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
}
