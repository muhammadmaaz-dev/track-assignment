import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

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
  }
}
