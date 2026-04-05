import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF000000); // Pitch black
  static const Color surface = Color(0xFF1C1C1E); // Dark gray for cards
  static const Color element = Color(
    0xFF2C2C2E,
  ); // Lighter gray for small buttons

  // Text & Accents
  static const Color primaryText = Color(0xFFFFFFFF); // White
  static const Color mutedText = Color(0xFF8E8E93); // Gray for subtitles/dates
}
