import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get hero => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: AppColors.textMain,
      );

  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textMain,
      );

  // Screen titles
  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textMain,
      );

  // Page headers
  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textMain,
      );

  // Section titles, card headers
  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textMain,
      );

  // Body copy, list items
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textMain,
      );

  // Timestamps, helper text
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textMain,
      );

  // Tags — uppercase, tight tracking
  static TextStyle get tag => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0.5,
        color: AppColors.textMain,
      );
}
