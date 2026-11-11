import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

/// Tema mengikuti DESIGN.md: Inter, flat tanpa elevasi/shadow,
/// kontrol radius 4px, kontainer 8px, border solid 1px.
class AppTheme {
  static ThemeData get lightTheme {
    final base = GoogleFonts.interTextTheme();

    final textTheme = base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16, height: 26 / 16, color: AppColors.textBody,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14, height: 22 / 14, color: AppColors.textBody,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13, height: 18 / 13, color: AppColors.textSecondary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, letterSpacing: 0.6,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.55,
      ),
    );

    final controlShape = RoundedRectangleBorder(borderRadius: AppRadius.controlR);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppRadius.controlR,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceTint: Colors.transparent,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.containerR,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: inputBorder(AppColors.borderStrong),
        enabledBorder: inputBorder(AppColors.borderStrong),
        focusedBorder: inputBorder(AppColors.primary, 1.5),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: controlShape,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.borderStrong;
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
              return AppColors.primaryLight;
            }
            return AppColors.primary;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          shape: controlShape,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 40),
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: controlShape,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 40),
          shape: controlShape,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: controlShape),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceVariant,
        side: const BorderSide(color: AppColors.borderStrong),
        shape: controlShape,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.containerR,
          side: const BorderSide(color: AppColors.primary, width: 2),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.container)),
          side: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlR,
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: controlShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.surfaceVariant,
        indicatorShape: controlShape,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.inter(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
            )),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Color(0xFF94A3B8), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
