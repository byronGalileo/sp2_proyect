import 'package:monitoring_app/app/constans/app_constants.dart';
import 'package:flutter/material.dart';

/// Color palette for the application
class AppColors {
  // Primary colors
  static const Color primaryDark = Color(0xFF010e59); // #010e59
  static const Color primaryBase = Color(0xFF1748cd); // #1748cd

  // Primary color variants
  static const Color primaryDarker = Color(0xFF000a3d);
  static const Color primaryLight = Color(0xFF4a6dd9);
  static const Color primaryLighter = Color(0xFF7d93e5);
  static const Color primaryPale = Color(0xFFb0bef1);

  // Accent colors (complementary orange/amber)
  static const Color accentOrange = Color(0xFFff8800);
  static const Color accentAmber = Color(0xFFffa726);
  static const Color accentLight = Color(0xFFffb84d);

  // Semantic colors
  static const Color success = Color(0xFF4caf50);
  static const Color warning = Color(0xFFff9800);
  static const Color error = Color(0xFFf44336);
  static const Color info = Color(0xFF2196f3);

  // Neutral colors rgb(22, 71, 204)
  static const Color background = Color.fromARGB(255, 22, 71, 204);
  static const Color surface = Color(0xFFffffff);
  static const Color surfaceDark = Color(0xFF1e1e1e);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFbdbdbd);
  static const Color textOnPrimary = Color(0xFFffffff);

  // Border and divider colors
  static const Color border = Color(0xFFe0e0e0);
  static const Color divider = Color(0xFFeeeeee);

  // MaterialColor swatch for primarySwatch
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF010e59,
    <int, Color>{
      50: Color(0xFFe0e2ee),
      100: Color(0xFFb3b7d5),
      200: Color(0xFF8088b9),
      300: Color(0xFF4d589d),
      400: Color(0xFF263488),
      500: Color(0xFF010e59), // Base color
      600: Color(0xFF010c50),
      700: Color(0xFF010a45),
      800: Color(0xFF01083b),
      900: Color(0xFF000429),
    },
  );
}

/// all custom application theme
class AppTheme {
  /// default application theme
  static ThemeData get basic => ThemeData(
        fontFamily: Font.nunito,
        canvasColor: AppColors.primaryBase,
        primarySwatch: AppColors.primarySwatch,
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.background,

        // Color scheme
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryDark,
          secondary: AppColors.accentOrange,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.textOnPrimary,
          onSecondary: AppColors.textOnPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textOnPrimary,
        ),

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
        ),

        // Card theme
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Floating action button theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: AppColors.textOnPrimary,
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryBase, width: 2),
          ),
        ),

        // Divider theme
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
      );

  // you can add other custom theme in this class like  light theme, dark theme ,etc.

  // example :
  // static ThemeData get light => ThemeData();
  // static ThemeData get dark => ThemeData();
}
