import 'package:flutter/material.dart';

/// Brand orange (aligns with web admin #fa8900).
const Color _primaryOrange = Color(0xFFFA8900);
const Color _primaryOrangeDark = Color(0xFFE67D00);
const Color _surfaceLight = Color(0xFFF8F9FA);
const Color _surfaceCard = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1A1D21);
const Color _textSecondary = Color(0xFF6B7280);
const Color _errorRed = Color(0xFFDC2626);
const Color _successGreen = Color(0xFF059669);

ThemeData get appThemeLight {
  final colorScheme = ColorScheme.light(
    primary: _primaryOrange,
    onPrimary: Colors.white,
    primaryContainer: _primaryOrange.withValues(alpha: 0.15),
    onPrimaryContainer: _primaryOrangeDark,
    errorContainer: _errorRed.withValues(alpha: 0.12),
    onErrorContainer: _errorRed,
    surface: _surfaceLight,
    onSurface: _textPrimary,
    onSurfaceVariant: _textSecondary,
    error: _errorRed,
    onError: Colors.white,
    outline: const Color(0xFFE5E7EB),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: _surfaceLight,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: _surfaceCard,
      foregroundColor: _textPrimary,
      titleTextStyle: const TextStyle(
        color: _textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: _textPrimary, size: 24),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _surfaceCard,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: const TextStyle(color: _textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryOrange,
        side: const BorderSide(color: _primaryOrange),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _primaryOrange),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: _textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

/// Reusable box decoration for sections.
BoxDecoration sectionCardDecoration(BuildContext context) {
  return BoxDecoration(
    color: _surfaceCard,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// Section label style.
TextStyle sectionLabelStyle(BuildContext context) {
  return const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _textSecondary,
    letterSpacing: 0.5,
  );
}

/// Error text style.
TextStyle errorStyle() => const TextStyle(color: _errorRed, fontSize: 14);

/// Success color.
Color get successColor => _successGreen;
