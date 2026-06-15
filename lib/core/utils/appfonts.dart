import 'package:flutter/material.dart';

class AppFonts {
  static const String primaryFont = 'poppins';
  static const String secondaryFont = 'Poppins';
  static const String appbartitleFont = 'PRISTINA';

  // Static black styles (for backward compatibility)
  static const TextStyle headline1 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const TextStyle appbartitleHeadline = TextStyle(
    fontFamily: appbartitleFont,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static const TextStyle newstitleHeadline = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static TextStyle newstitlebody1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.grey.shade600,
  );

  static TextStyle newstitlebody2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.pinkAccent,
  );
}

// Extension methods for theme-aware fonts
extension AppFontsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  TextStyle get headline1 => TextStyle(
        fontFamily: AppFonts.primaryFont,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      );

  TextStyle get bodyText => TextStyle(
        fontFamily: AppFonts.primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDarkMode ? Colors.white : Colors.black,
      );

  TextStyle get headline2 => TextStyle(
        fontFamily: AppFonts.secondaryFont,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      );

  TextStyle get bodyText2 => TextStyle(
        fontFamily: AppFonts.secondaryFont,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDarkMode ? Colors.white : Colors.black,
      );

  TextStyle get appbartitleHeadline => TextStyle(
        fontFamily: AppFonts.appbartitleFont,
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white : Colors.black,
      );

  TextStyle get newstitleHeadline => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDarkMode ? Colors.white : Colors.black,
      );
}
