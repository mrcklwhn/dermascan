import 'package:flutter/material.dart';

class AppTheme {
  // ---------- Color Palette ----------
  // Primary: trustworthy medical blue / teal
  static const Color primary = Color(0xFF0B79BF); // strong medical blue
  static const Color primaryVariant = Color(0xFF075A93);
  static const Color secondary = Color(0xFF00A79D); // teal accent
  static const Color secondaryVariant = Color(0xFF008075);

  // Semantic
  static const Color success = Color(0xFF2E8B57); // sea green
  static const Color caution = Color(0xFFFFB238); // amber for warnings
  static const Color danger = Color(0xFFB00020); // medical error red

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF7F9FB);
  static const Color gray100 = Color(0xFFEEF3F7);
  static const Color gray200 = Color(0xFFDEE9EE);
  static const Color gray300 = Color(0xFFBFD6DE);
  static const Color gray500 = Color(0xFF7C98A6);
  static const Color gray700 = Color(0xFF4A636F);

  // ---------- Radii & Spacing ----------
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;

  // Spacing scale (use consistent constants in app)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // ---------- Elevations ----------
  static const double elevationLow = 1.0;
  static const double elevationCard = 4.0;
  static const double elevationDialog = 8.0;

  // ---------- Typography ----------
  // Use system fonts or include Inter/Roboto in assets. Scales follow accessibility.
  static TextTheme _buildTextTheme(Color onBackground) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onBackground,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onBackground,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
    ).apply(
      // Don't force a font family here—let app choose system or bundled font.
      bodyColor: onBackground,
      displayColor: onBackground,
    );
  }

  // ---------- Light Theme ----------
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: white,
      secondary: secondary,
      onSecondary: white,
      error: danger,
      onError: white,
      surface: white,
      onSurface: black,
    ),
    primaryColor: primary,
    scaffoldBackgroundColor: gray50,
    canvasColor: white,
    // Text
    textTheme: _buildTextTheme(black),
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      elevation: elevationLow,
      iconTheme: IconThemeData(color: primary),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      centerTitle: false,
      toolbarHeight: 56,
    ),
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: white,
        backgroundColor: primary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
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
        foregroundColor: primary,
        side: BorderSide(color: primary.withValues(alpha: 0.14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    // Text Button (link-like)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    // Input decorations (forms)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceMd,
        vertical: spaceSm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      labelStyle: const TextStyle(color: gray700),
      hintStyle: const TextStyle(color: gray500),
    ),
    // Cards
    cardTheme: CardThemeData(
      color: white,
      elevation: elevationCard,
      margin: const EdgeInsets.symmetric(
        vertical: spaceSm,
        horizontal: spaceMd,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: white,
      elevation: elevationDialog,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: gray700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primary,
      unselectedItemColor: gray500,
      showUnselectedLabels: true,
      elevation: elevationLow,
    ),
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    // SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: gray700,
      contentTextStyle: const TextStyle(color: white),
      behavior: SnackBarBehavior.floating,
      elevation: elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),
    // Switch / Checkbox / Radio & Icon theme
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return secondary.withValues(alpha: 0.5);
        }
        return gray200;
      }),
      thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return secondary;
        }
        return white;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return gray500;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    iconTheme: const IconThemeData(color: primary),
    // Visual density
    visualDensity: VisualDensity.adaptivePlatformDensity,
    // Default font family left to app (to support localization & accessibility)
  );

  // ---------- Dark Theme ----------
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: black,
      secondary: secondary,
      onSecondary: black,
      error: danger,
      onError: black,
      surface: Color(0xFF071018),
      onSurface: white,
    ),
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFF071018),
    canvasColor: const Color(0xFF071018),
    textTheme: _buildTextTheme(white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF071018),
      elevation: elevationLow,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: black,
        backgroundColor: secondary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B1B24),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceMd,
        vertical: spaceSm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: Color(0xFF12313B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: Color(0xFF12313B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      labelStyle: const TextStyle(color: gray300),
      hintStyle: const TextStyle(color: gray500),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF081620),
      elevation: elevationCard,
      margin: const EdgeInsets.symmetric(
        vertical: spaceSm,
        horizontal: spaceMd,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF071018),
      elevation: elevationDialog,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: gray300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF071018),
      selectedItemColor: secondary,
      unselectedItemColor: gray500,
      showUnselectedLabels: true,
      elevation: elevationLow,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: gray700,
      contentTextStyle: const TextStyle(color: white),
      behavior: SnackBarBehavior.floating,
      elevation: elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return secondary.withValues(alpha: .5);
        }
        return const Color(0xFF12313B);
      }),
      thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return secondary;
        }
        return const Color(0xFF07303A);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return gray500;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    iconTheme: const IconThemeData(color: white),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

// ---------- Helpful Extensions ----------
// Provide convenient access to semantic colors and sizes via context:
extension MedicalThemeExtensions on BuildContext {
  ThemeData get medTheme => Theme.of(this);

  Color get medPrimary => medTheme.colorScheme.primary;

  Color get medSecondary => medTheme.colorScheme.secondary;

  Color get medBackground => medTheme.colorScheme.surface;

  double get medSpaceMd => AppTheme.spaceMd;

  double get medRadius => AppTheme.radiusMedium;
}
