import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFFA8601);
  static const Color secondary = Color(0xFF006675);
  static const Color accent = Color(0xFF0093FF);

  // Text
  static const Color textMain = Color(0xFF393938);
  static const Color textHighContrast = Color(0xFF000000);
  static const Color textDisabled = Color(0xFF777675);
  static const Color textPlaceholder = Color(0xFF666666);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF00C814);
  static const Color warning = Color(0xFFFFD569);
  static const Color error = Color(0xFFE10000);

  // Surface / Artboard
  static const Color surfaceDefault = Color(0xFFFFFFFF);
  static const Color surfaceModal = Color(0xFFFBFBFB);
  static const Color surfaceDark = Color(0xFF0D0D0D);

  // Border & Divider
  static const Color borderActive = Color(0xFF006675);
  static const Color borderInactive = Color(0xFFE5E5E5);
  static const Color dividerLight = Color(0xFFD9D9D9);
  static const Color dividerDark = Color(0xFF171717);

  // Input / Form
  static const Color inputFill = Color(0xFFEFEFEF);
  static const Color labelInactive = Color(0xFFD7D5D3);
  static const Color iconDefault = Color(0xFFC4C4C4);
}
