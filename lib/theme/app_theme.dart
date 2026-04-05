import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static const String headingFontFamily = 'Nunito';
  static const String bodyFontFamily = 'Nunito';

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: bodyFontFamily,

      // The main background of your app
      scaffoldBackgroundColor: AppColors.background,

      // The core color palette
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryText, // White acts as your primary accent
        surface: AppColors.surface, // Dark gray for cards/dialogs
        onSurface: AppColors.primaryText, // White text on top of cards
        onSurfaceVariant: AppColors.mutedText, // Muted text on top of cards
      ),
    );

    final mappedTextTheme = _mapTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: mappedTextTheme,
      primaryTextTheme: _mapTextTheme(baseTheme.primaryTextTheme),
    );
  }

  // Headings use headingFontFamily; body/labels use bodyFontFamily.
  static TextTheme _mapTextTheme(TextTheme base) {
    TextStyle applyHeading(TextStyle? style) {
      return style?.copyWith(fontFamily: headingFontFamily) ??
          TextStyle(fontFamily: headingFontFamily);
    }

    TextStyle applyBody(TextStyle? style) {
      return style?.copyWith(fontFamily: bodyFontFamily) ??
          TextStyle(fontFamily: bodyFontFamily);
    }

    return base.copyWith(
      displayLarge: applyHeading(base.displayLarge),
      displayMedium: applyHeading(base.displayMedium),
      displaySmall: applyHeading(base.displaySmall),
      headlineLarge: applyHeading(base.headlineLarge),
      headlineMedium: applyHeading(base.headlineMedium),
      headlineSmall: applyHeading(base.headlineSmall),
      titleLarge: applyHeading(base.titleLarge),
      titleMedium: applyHeading(base.titleMedium),
      titleSmall: applyHeading(base.titleSmall),
      bodyLarge: applyBody(base.bodyLarge),
      bodyMedium: applyBody(base.bodyMedium),
      bodySmall: applyBody(base.bodySmall),
      labelLarge: applyBody(base.labelLarge),
      labelMedium: applyBody(base.labelMedium),
      labelSmall: applyBody(base.labelSmall),
    );
  }
}
