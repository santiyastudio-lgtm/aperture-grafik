import 'package:flutter/material.dart';

import '../../domain/models.dart';

/// Original Material 3 colour systems. They intentionally use no Portal or
/// Aperture Laboratories marks, illustrations, or protected visual assets.
class AppTheme {
  const AppTheme._();

  static ThemeData forMode(AppThemeMode mode) {
    final palette = switch (mode) {
      AppThemeMode.standard => _Palette(
        seed: const Color(0xFF1565D8),
        surface: const Color(0xFFF8FAFF),
        brightness: Brightness.light,
      ),
      AppThemeMode.laboratory => _Palette(
        seed: const Color(0xFF2D6D8C),
        surface: const Color(0xFFF4F8F7),
        brightness: Brightness.light,
      ),
      AppThemeMode.aperture => _Palette(
        seed: const Color(0xFFE66C16),
        surface: const Color(0xFFFFF8F3),
        brightness: Brightness.light,
      ),
      AppThemeMode.chamber => _Palette(
        seed: const Color(0xFF23C7A3),
        surface: const Color(0xFF101515),
        brightness: Brightness.dark,
      ),
    };
    final generated = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: palette.brightness,
    );
    final scheme = generated.copyWith(surface: palette.surface);
    final isDark = palette.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.surface,
      dividerColor: scheme.outlineVariant.withValues(alpha: .55),
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: .14),
        color: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minVerticalPadding: 10,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: isDark ? scheme.surfaceContainer : palette.surface,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        indicatorColor: scheme.secondaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.seed,
    required this.surface,
    required this.brightness,
  });

  final Color seed;
  final Color surface;
  final Brightness brightness;
}
