import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFFA8601);
  static const Color primary80 = Color(0xFFFB9E34);
  static const Color primary60 = Color(0xFFFCB667);
  static const Color primary40 = Color(0xFFFDCF99);
  static const Color primary20 = Color(0xFFFEE7CC);

  static const Color secondary = Color(0xFF006675);
  static const Color secondary80 = Color(0xFF338591);
  static const Color secondary60 = Color(0xFF66A3AD);
  static const Color secondary40 = Color(0xFF99C2C8);
  static const Color secondary20 = Color(0xFFCCE0E3);

  static const Color accent = Color(0xFF0093FF);

  static const Color secondaryOrange = Color(0xFFFF7644);
  static const Color secondaryOrange20 = Color(0xFFFFE4DA);

  static const Color accentRed = Color(0xFFFF4179);
  static const Color accentRed20 = Color(0xFFFFD9E4);

  static const Color error20 = Color(0xFFFBD0CE);

  // Text
  static const Color textMain = Color(0xFF393938);
  static const Color textHighContrast = Color(0xFF000000);
  static const Color textSubtle = Color(0xFF9A9A9A);
  static const Color textDisabled = Color(0xFF777675);
  static const Color textPlaceholder = Color(0xFF666666);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF2D9D78);
  static const Color success20 = Color(0xFFD9F0E7);
  static const Color warning = Color(0xFFFFD569);
  static const Color error = Color(0xFFDD3636);

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
