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
  static final ColorScheme _lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: white,
    primaryContainer: primary,
    onPrimaryContainer: white,
    secondary: secondary,
    onSecondary: white,
    secondaryContainer: secondary,
    onSecondaryContainer: textDark,
    tertiary: tertiary,
    onTertiary: textDark,
    tertiaryContainer: tertiary,
    onTertiaryContainer: textDark,
    error: danger,
    onError: white,
    surface: scaffoldBg,
    onSurface: textDark,
    onSurfaceVariant: textDark,
    surfaceContainerLowest: white,
    surfaceContainerLow: highlightColor,
    surfaceContainer: highlightColor,
    surfaceContainerHigh: tertiary,
    surfaceContainerHighest: tertiary,
    surfaceTint: Colors.transparent,
    outline: textDark,
    outlineVariant: tertiary,
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,

    scaffoldBackgroundColor: _lightColorScheme.surface,

    // Text
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(),
      bodyMedium: TextStyle(),
      bodySmall: TextStyle(),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontWeight: FontWeight.bold),
      titleSmall: TextStyle(fontWeight: FontWeight.bold),
    ).apply(
      bodyColor: _lightColorScheme.onSurface,
      displayColor: _lightColorScheme.onSurface,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: _lightColorScheme.onSurface),
      actionsPadding: const EdgeInsets.only(right: spaceMedium),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _lightColorScheme.onSurface,
      ),
      centerTitle: true,
      toolbarHeight: 64,
      leadingWidth: 80,
    ),

    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: _lightColorScheme.onPrimary,
        backgroundColor: _lightColorScheme.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _lightColorScheme.onPrimary,
        backgroundColor: _lightColorScheme.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
        foregroundColor: _lightColorScheme.onSurface,
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
        foregroundColor: _lightColorScheme.onSurface,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Input decorations
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightColorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceMedium,
        vertical: spaceSmall,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: _lightColorScheme.surfaceContainerLow),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: _lightColorScheme.surfaceContainerLow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: _lightColorScheme.error, width: 2),
      ),
      labelStyle: TextStyle(color: _lightColorScheme.onSurface),
      hintStyle: TextStyle(color: _lightColorScheme.onSurface),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: _lightColorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
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
      titleTextStyle: TextStyle(
        color: _lightColorScheme.onSurface,
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
      iconColor: _lightColorScheme.primary,
      collapsedIconColor: _lightColorScheme.primary,
    ),

    // Search Bar
    searchBarTheme: SearchBarThemeData(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      ),
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(_lightColorScheme.surfaceContainerLow),
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
      backgroundColor: _lightColorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _lightColorScheme.onSurface,
      ),
      contentTextStyle: TextStyle(fontSize: 14, color: _lightColorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightColorScheme.surfaceContainerLow,
      selectedItemColor: _lightColorScheme.primary,
      showUnselectedLabels: true,
      elevation: 0, // No shadow
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightColorScheme.secondary,
      foregroundColor: _lightColorScheme.onSecondary,
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
      backgroundColor: _lightColorScheme.primary,
      contentTextStyle: TextStyle(color: _lightColorScheme.onPrimary),
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
          return _lightColorScheme.primary;
        }
        return Colors.transparent;
      }),
      side: BorderSide(color: _lightColorScheme.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    iconTheme: IconThemeData(color: _lightColorScheme.onSurface),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _lightColorScheme.onSurface,
        backgroundColor: _lightColorScheme.surfaceContainerLow,
        fixedSize: const Size(radiusLarge * 2, radiusLarge * 2),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
