import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildIvraTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;

  // Exact Stitch Project "Solar Infusion" design system color tokens
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

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ),
    // Transparent scaffold to allow global gradient background to show through
    scaffoldBackgroundColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    
    // Glassmorphic / Ambient Shadow Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: isLight ? Colors.white.withValues(alpha: 0.7) : colorScheme.surface.withValues(alpha: 0.8),
      shadowColor: const Color(0xFF92400E).withValues(alpha: 0.08), // Amber tinted shadow
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        // No hard borders, rely on depth and blur
      ),
    ),
    
    // Inputs with softer cream fill and golden orange focus (Stitch specific)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? const Color(0xFFFCF2EB) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
        borderSide: BorderSide(color: Color(0xFFF59E0B), width: 2.0), // Stitch Golden Orange focus outline!
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Pill-like buttons with micro-glow shadows matching Stitch
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF59E0B), // Solid Golden Orange
        foregroundColor: Colors.white, // White text
        shape: const StadiumBorder(),
        elevation: 2,
        shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.4), // Golden Orange glow shadow!
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: const Color(0xFF855300), // Brownish-orange primary
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5), // Golden Orange border
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    
    // Soft Chips
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    
    // Transparent AppBars to let gradient show
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    
    // Navigation
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
    
    // Dialogs with fluid rounded corners
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: isLight ? const Color(0xFFFFF8F5) : null,
    ),
  );
}
