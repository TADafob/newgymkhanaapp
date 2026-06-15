import 'package:flutter/material.dart';

class AppKolors {
  // ── Website-matched palette ──────────────────────────────
  static const Color primary = Color(0xFF0693e3); // --primary
  static const Color primaryDk = Color(0xFF057ab8); // --primary-dk
  static const Color accent = Color(0xFF07d8c3); // --accent (teal)
  static const Color dark = Color(0xFF1a2e35); // --dark (sidebar/card bg)
  static const Color darkCard = Color(0xFF2c4a5a); // gradient end

  // Light theme
  static const Color background = Color(0xFFF0F4F8); // --bg
  static const Color surface = Color(0xFFFFFFFF); // --card-bg
  static const Color border = Color(0xFFE5E9EF); // --border
  static const Color textPrimary = Color(0xFF2c3e50); // --text
  static const Color textSecondary = Color(0xFF6b7280); // --muted
  static const Color divider = Color(0xFFE5E9EF);

  // Dark theme
  static const Color darkBackground = Color(0xFF0A0E21);
  static const Color darkSurface = Color(0xFF1D1E33);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkDivider = Color(0xFF37474F);

  // Legacy aliases kept for backward compatibility
  static const Color secondary = Color(0xFF2c4a5a);
  static const Color accent2 = Color(0xFF07d8c3);
  static const Color accent3 = Color(0xFFEF5350);
  static const Color containerPrimary = Color(0x83BDB8B8);
  static const Color blackness = Color(0xFF000000);
  static const Color darkPrimary = Color(0xFF0693e3);
  static const Color darkSecondary = Color(0xFF2c4a5a);
  static const Color darkAccent = Color(0xFF07d8c3);
  static const Color darkAccent2 = Color(0xFF81C784);
  static const Color darkAccent3 = Color(0xFFE57373);
  static const Color darkContainerPrimary = Color(0x83424242);
}
