import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised theme builder.
///
/// Both themes are generated from [AppBrand.seedColor] so the app stays visually
/// consistent as new screens are added, and every widget reads component styles
/// from here instead of hard-coding values.
class AppTheme {
  const AppTheme._();

  /// Light theme for [brand] (defaults to [AppBrand.current]).
  static ThemeData light([AppBrand brand = AppBrand.current]) =>
      build(brand: brand, brightness: Brightness.light);

  /// Dark theme for [brand] (defaults to [AppBrand.current]).
  static ThemeData dark([AppBrand brand = AppBrand.current]) =>
      build(brand: brand, brightness: Brightness.dark);

  /// Builds a [ThemeData] for a given [brand] and [brightness].
  static ThemeData build({
    required AppBrand brand,
    required Brightness brightness,
  }) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brand.seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light,
      ],
      appBarTheme: AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(BorderSide.none),
        enabledBorder: _inputBorder(BorderSide.none),
        focusedBorder: _inputBorder(
          BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: _inputBorder(BorderSide(color: scheme.error, width: 1.5)),
        focusedErrorBorder: _inputBorder(
          BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.5),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }

  static OutlineInputBorder _inputBorder(BorderSide side) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: side,
    );
  }
}
