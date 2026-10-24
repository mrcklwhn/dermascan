import 'package:flutter/material.dart';


/// Color Scheme Roles & Usage Reference:
///
/// - primary / onPrimary:
///   Main actions: filled buttons, active/selected states; 'onPrimary' is the text/icon foreground.
///
/// - primaryContainer / onPrimaryContainer:
///   Prominent, softer background surfaces and highlighted cards.
///
/// - secondary, tertiary (+ respective containers):
///   Secondary accents and balancing tonal highlights.
///
/// - surface / onSurface:
///   Page and card backgrounds; 'onSurface' is the primary foreground text.
///
/// - onSurfaceVariant:
///   Secondary text, captions, and descriptions.
///
/// - surfaceContainerLow ... surfaceContainerHighest:
///   Layer-by-layer increasing surface tones for visual elevation.
///
/// - outline, outlineVariant:
///   Borders, structural outlines, and subtle dividers.
///
/// - error / onError:
///   Error states, validation alerts, and foreground elements on error backgrounds.
///


class AppTheme {
  // ---------- Color Palette ----------
  static const Color primary = Color.fromRGBO(48, 71, 94, 1);
  static const Color secondary = Color.fromRGBO(193, 165, 123, 1);
  static const Color tertiary = Color.fromRGBO(236, 236, 236, 1);

  // Neutral / Background Colors
  static const Color textDark = Color(0xFF393E41);
  static const Color scaffoldBg = Color.fromRGBO(241, 242, 246, 1);
  static const Color highlightColor = Color.fromRGBO(254, 255, 254, 1);
  static const Color white = Colors.white;

  // Error Color
  static const Color danger = Color(0xFFD32F2F);

  // ---------- Radii & Spacing ----------
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 32.0;

  static EdgeInsets scaffoldPadding = const EdgeInsets.all(
    AppTheme.spaceMedium,
  );

  // ---------- Light Theme  ----------
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: white,
      secondary: secondary,
      onSecondary: textDark,
      error: danger,
      onError: white,
      surface: highlightColor, // Chip Background -> Layer 1
      onSurface: textDark,
    ),
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldBg, // Scaffold Background -> Layer 0

    // Text
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: textDark),
      bodyMedium: TextStyle(color: textDark),
      bodySmall: TextStyle(color: textDark),
      titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: textDark, fontWeight: FontWeight.bold),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: scaffoldBg,
      elevation: 0,
      // No shadow
      scrolledUnderElevation: 0,

      // Prevents Material 3 tinting on scroll
      iconTheme: IconThemeData(color: textDark),
      actionsPadding: EdgeInsets.only(right: spaceMedium),

      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      centerTitle: true,
      toolbarHeight: 64,
      leadingWidth: 80,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: white,
        backgroundColor: primary,
        elevation: 0,
        // No shadow
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceSmall,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Input decorations
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: highlightColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceMedium,
        vertical: spaceSmall,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: highlightColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: highlightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      labelStyle: const TextStyle(color: textDark),
      hintStyle: const TextStyle(color: textDark),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: highlightColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),

    // List Tiles
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      titleTextStyle: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    ),

    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      tilePadding: const EdgeInsets.all(spaceSmall),
      childrenPadding: const EdgeInsets.all(spaceSmall),
      iconColor: AppTheme.primary,
      collapsedIconColor: AppTheme.primary,
    ),

    // Search Bar
    searchBarTheme: SearchBarThemeData(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      ),
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(highlightColor),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: highlightColor,
      elevation: 0,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: textDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: highlightColor,
      selectedItemColor: primary,
      showUnselectedLabels: true,
      elevation: 0, // No shadow
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: textDark,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),

    // SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: const TextStyle(color: white),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: textDark, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    iconTheme: const IconThemeData(color: textDark),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textDark,
        backgroundColor: highlightColor,
        fixedSize: const Size(
          AppTheme.radiusLarge * 2,
          AppTheme.radiusLarge * 2,
        ),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
