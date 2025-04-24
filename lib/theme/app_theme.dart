import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

class AppTheme {
  // Material You seed colors
  static const Color primaryColor = Color(0xFF0057D0); // Primary seed color
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color tertiaryColor = Color(0xFF7D5260);

  // Fallback colors (used when dynamic colors are not available)
  static const Color lightBackgroundColor = Color(0xFFF8F6FF);
  static const Color lightSurfaceColor = Color(0xFFFFFBFF);
  static const Color darkBackgroundColor = Color(0xFF1C1B1F);
  static const Color darkSurfaceColor = Color(0xFF2D2C31);
  static const Color errorColor = Color(0xFFB3261E);

  // Text colors
  static const Color lightTextPrimaryColor = Color(0xFF1C1B1F);
  static const Color lightTextSecondaryColor = Color(0xFF49454F);
  static const Color lightTextTertiaryColor = Color(0xFF79747E);
  static const Color darkTextPrimaryColor = Color(0xFFF4EFF4);
  static const Color darkTextSecondaryColor = Color(0xFFCAC4D0);
  static const Color darkTextTertiaryColor = Color(0xFF938F99);

  // Other UI colors
  static const Color lightDividerColor = Color(0xFFE7E0EC);
  static const Color darkDividerColor = Color(0xFF49454F);

  // Shimmer effect colors
  static Color get shimmerBaseColor =>
      getColorScheme().brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!;
  static Color get shimmerHighlightColor =>
      getColorScheme().brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[500]!;
  static Color get shadowColor =>
      getColorScheme().brightness == Brightness.light ? Colors.black.withAlpha(25) : Colors.black.withAlpha(50);

  // Compatibility properties for existing code
  static Color get accentColor => getColorScheme().primary;
  static Color get cardColor => getColorScheme().surfaceContainerHighest;

  // Dynamic getters that return appropriate colors based on current theme
  static Color get backgroundColor =>
      getColorScheme().brightness == Brightness.light ? lightBackgroundColor : darkBackgroundColor;
  static Color get textPrimaryColor =>
      getColorScheme().brightness == Brightness.light ? lightTextPrimaryColor : darkTextPrimaryColor;
  static Color get textSecondaryColor =>
      getColorScheme().brightness == Brightness.light ? lightTextSecondaryColor : darkTextSecondaryColor;
  static Color get textTertiaryColor =>
      getColorScheme().brightness == Brightness.light ? lightTextTertiaryColor : darkTextTertiaryColor;
  static Color get dividerColor =>
      getColorScheme().brightness == Brightness.light ? lightDividerColor : darkDividerColor;

  // Legacy text styles for backward compatibility
  static TextStyle get headingLarge => displaySmall;
  static TextStyle get headingMedium => headlineLarge;
  static TextStyle get headingSmall => headlineSmall;
  static TextStyle get buttonText => labelLarge.copyWith(color: Colors.white);

  // Enhanced spacing values for Material You
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Text Styles with Material You typography
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Get dynamic color scheme based on device wallpaper (Android 12+)
  static ColorScheme? _dynamicColorScheme;

  // Set dynamic color scheme
  static void setDynamicColorScheme(ColorScheme? colorScheme) {
    // Ensure we're not setting a null color scheme
    if (colorScheme == null) {
      _dynamicColorScheme = null;
      return;
    }

    // Make sure the brightness is consistent with our theme mode
    _dynamicColorScheme = colorScheme;
  }

  // Get current color scheme (dynamic or fallback) for light theme
  static ColorScheme getColorScheme() {
    if (_dynamicColorScheme != null) {
      // Always ensure light theme has light brightness
      return _dynamicColorScheme!.copyWith(brightness: Brightness.light);
    }
    return _getFallbackColorScheme();
  }

  // Get current color scheme (dynamic or fallback) for dark theme
  static ColorScheme getDarkColorScheme() {
    if (_dynamicColorScheme != null) {
      // Always ensure dark theme has dark brightness
      return _dynamicColorScheme!.copyWith(
        brightness: Brightness.dark,
        // Ensure proper contrast for dark mode
        surface: darkSurfaceColor,
        surfaceContainerLow: darkBackgroundColor,
        onSurface: darkTextPrimaryColor,
        onSurfaceVariant: darkTextSecondaryColor,
        surfaceContainerHighest: Color(0xFF3A3A3F),
        outline: darkDividerColor,
      );
    }
    return _getFallbackDarkColorScheme();
  }

  // Fallback color scheme with Material You harmonized colors
  static ColorScheme _getFallbackColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: errorColor,
      surface: lightSurfaceColor,
      brightness: Brightness.light,
    );
  }

  // Create dark scheme for dark mode
  static ColorScheme _getFallbackDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: errorColor,
      surface: darkSurfaceColor,
      brightness: Brightness.dark,
    ).copyWith(
      // Ensure proper contrast for dark mode
      surface: darkSurfaceColor,
      surfaceContainerLow: darkBackgroundColor, // Instead of deprecated background
      onSurface: darkTextPrimaryColor,
      onSurfaceVariant: darkTextSecondaryColor,
      surfaceContainerHighest: Color(0xFF3A3A3F), // Darker card color for better contrast
      outline: darkDividerColor,
    );
  }

  // Theme Data for light mode
  static ThemeData lightTheme() {
    final colorScheme = getColorScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Enhanced Typography
      textTheme: TextTheme(
        displayLarge: displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: displayMedium.copyWith(color: colorScheme.onSurface),
        displaySmall: displaySmall.copyWith(color: colorScheme.onSurface),
        headlineLarge: headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: bodySmall.copyWith(color: colorScheme.onSurface),
        labelLarge: labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: labelSmall.copyWith(color: colorScheme.onSurface),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: titleLarge.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        scrolledUnderElevation: 4,
      ),

      // Card Theme with Material You styling
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(spacingS),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        highlightElevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: spacingL),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: spacingS, horizontal: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      // Input Decoration Theme - Material You style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        labelStyle: bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: bodyMedium.copyWith(color: colorScheme.onSurfaceVariant.withAlpha(179)),
        floatingLabelStyle: bodySmall.copyWith(color: colorScheme.primary),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
        padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: colorScheme.outline, width: 0.5),
        elevation: 0,
        selectedColor: colorScheme.secondaryContainer,
        selectedShadowColor: Colors.transparent,
        showCheckmark: true,
        checkmarkColor: colorScheme.onSecondaryContainer,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 2,
        modalElevation: 4,
      ),

      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 24),
        selectedLabelTextStyle: labelMedium.copyWith(color: colorScheme.primary),
        unselectedLabelTextStyle: labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
        elevation: 0,
        useIndicator: true,
        indicatorColor: colorScheme.secondaryContainer,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: Colors.transparent,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        selectedTileColor: colorScheme.secondaryContainer,
        selectedColor: colorScheme.onSecondaryContainer,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: bodyMedium.copyWith(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: labelLarge,
        unselectedLabelStyle: labelLarge,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  // Dark theme implementation
  static ThemeData darkTheme() {
    final colorScheme = getDarkColorScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Enhanced Typography with proper dark mode colors
      textTheme: TextTheme(
        displayLarge: displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: displayMedium.copyWith(color: colorScheme.onSurface),
        displaySmall: displaySmall.copyWith(color: colorScheme.onSurface),
        headlineLarge: headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: bodySmall.copyWith(color: colorScheme.onSurface),
        labelLarge: labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: labelSmall.copyWith(color: colorScheme.onSurface),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: titleLarge.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        scrolledUnderElevation: 4,
      ),

      // Card Theme with Material You styling
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(spacingS),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        highlightElevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: spacingL),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: spacingS, horizontal: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingL),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),

      // Input Decoration Theme - Material You style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(77),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        labelStyle: bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: bodyMedium.copyWith(color: colorScheme.onSurfaceVariant.withAlpha(179)),
        floatingLabelStyle: bodySmall.copyWith(color: colorScheme.primary),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 2,
        modalElevation: 4,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: Colors.transparent,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        selectedTileColor: colorScheme.secondaryContainer,
        selectedColor: colorScheme.onSecondaryContainer,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: labelLarge,
        unselectedLabelStyle: labelLarge,
      ),
    );
  }
}