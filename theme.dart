import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF0B2545);
  static const navyLight = Color(0xFF13315C);
  static const green = Color(0xFF1DB173);
  static const blue = Color(0xFF2E7DD1);
  static const background = Color(0xFFF6F8FB);
  static const white = Colors.white;
  static const textMuted = Color(0xFF6B7A90);
  static const border = Color(0xFFE3E9F1);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.green,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.green.withOpacity(0.18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
