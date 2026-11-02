import 'package:flutter/material.dart';

/// Single seed colour → complete Material 3 light & dark themes.
/// All screens pull colours exclusively from the ColorScheme / ThemeData in
/// here — no screen-level hardcoded colours.
library;

class AppTheme {
  AppTheme._();

  /// Official primary seed colour.
  static const Color seedColor = Color(0xFF2563EB);

  /// Light background configured per the design spec.
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Success / error colours mapped through theme extensions where possible.
  static const Color successSeed = Color(0xFF16A34A);
  static const Color errorSeed = Color(0xFFDC2626);

  static const double radiusLarge = 20;
  static const double radiusMedium = 14;
  static const double radiusSmall = 10;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(
      // Match the requested palette while keeping seed-derived accents.
      surface: isLight ? lightSurface : const Color(0xFF0F172A),
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      error: errorSeed,
      scrim: Colors.black54,
    );

    final ColorScheme effective = isLight
        ? scheme.copyWith(
            secondary: const Color(0xFF0F766E),
            primaryContainer: scheme.primary.withOpacity(0.12),
            onPrimaryContainer: scheme.primary,
          )
        : scheme.copyWith(
            secondary: const Color(0xFF2DD4BF),
          );

    final ColorScheme colors = effective;

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: isLight ? lightBackground : colors.surface,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: colors.onSurface.withOpacity(0.8)),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: isLight == false ? true : false,
        backgroundColor:
            isLight ? lightBackground : colors.surface,
        foregroundColor: colors.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
          letterSpacing: 0.1,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(
            color: colors.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: colors.outlineVariant.withOpacity(0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        errorStyle: TextStyle(color: colors.error, fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.6)),
        selectedColor: colors.primaryContainer,
        showCheckmark: false,
        labelStyle: TextStyle(fontSize: 13, color: colors.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(
            color: colors.onInverseSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight:
                  states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: colors.onSurface,
            )),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surfaceContainerLow,
        headerForegroundColor: colors.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: colors.onSurface.withOpacity(0.85),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );

    // Global typography: same family, tuned weights.
    final TextTheme text = base.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.35),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
