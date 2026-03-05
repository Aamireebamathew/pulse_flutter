import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Brand / Primary (light) ──────────────────────────────────────────────
  static const blue50  = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);

  // ── Brand / Primary (dark) — Deep Purple ────────────────────────────────
  static const purple50  = Color(0xFFF5F3FF);
  static const purple100 = Color(0xFFEDE9FE);
  static const purple300 = Color(0xFFC4B5FD);
  static const purple400 = Color(0xFFA78BFA);
  static const purple500 = Color(0xFF8B5CF6);
  static const purple600 = Color(0xFF7C3AED);
  static const purple700 = Color(0xFF6D28D9);
  static const purple800 = Color(0xFF5B21B6);
  static const purple900 = Color(0xFF4C1D95);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const success    = Color(0xFF22C55E);
  static const successBg  = Color(0xFFF0FDF4);
  static const warning    = Color(0xFFF59E0B);
  static const warningBg  = Color(0xFFFFFBEB);
  static const error      = Color(0xFFEF4444);
  static const errorBg    = Color(0xFFFEF2F2);
  static const info       = Color(0xFF3B82F6);
  static const infoBg     = Color(0xFFEFF6FF);

  // ── Light mode neutrals ──────────────────────────────────────────────────
  static const lightBg       = Color(0xFFF8FAFC);
  static const lightBgAlt    = Color(0xFFEFF6FF);
  static const lightSurface  = Color(0xFFFFFFFF);
  static const lightBorder   = Color(0xFFE2E8F0);
  static const lightBorderAlt= Color(0xFFCBD5E1);
  static const lightText     = Color(0xFF0F172A);
  static const lightTextSub  = Color(0xFF475569);
  static const lightTextMute = Color(0xFF94A3B8);

  // ── Dark mode neutrals ───────────────────────────────────────────────────
  static const darkBg        = Color(0xFF0A0A0F);   // near-black with purple tint
  static const darkBgAlt     = Color(0xFF0F0F1A);
  static const darkSurface   = Color(0xFF14141F);   // card background
  static const darkSurface2  = Color(0xFF1C1C2E);   // elevated surface
  static const darkSurface3  = Color(0xFF252535);   // highest elevation
  static const darkBorder    = Color(0xFF2D2D45);
  static const darkBorderAlt = Color(0xFF3D3D55);
  static const darkText      = Color(0xFFF1F0FF);   // white with purple tint
  static const darkTextSub   = Color(0xFFB8B5D4);
  static const darkTextMute  = Color(0xFF6B6890);
}

class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xl2  = 24;
  static const double xl3  = 32;
  static const double xl4  = 40;
  static const double xl5  = 48;
  static const double xl6  = 64;
}

class AppRadius {
  AppRadius._();
  static const double xs  = 6;
  static const double sm  = 10;
  static const double md  = 14;
  static const double lg  = 18;
  static const double xl  = 24;
  static const double xl2 = 32;
  static const double full = 999;
}

class AppTextStyles {
  AppTextStyles._();

  // Display
  static const TextStyle display = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    letterSpacing: -0.8, height: 1.2,
  );
  static const TextStyle displaySm = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.25,
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.4, height: 1.3,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    letterSpacing: -0.3, height: 1.35,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, height: 1.4,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: -0.1, height: 1.4,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    letterSpacing: 0, height: 1.6,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    letterSpacing: 0, height: 1.55,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    letterSpacing: 0, height: 1.5,
  );

  // Labels & captions
  static const TextStyle label = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 0.2, height: 1.4,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    letterSpacing: 0.3, height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400,
    letterSpacing: 0.2, height: 1.4,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600,
    letterSpacing: 1.2, height: 1.4,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHADOWS & ELEVATIONS
// ═══════════════════════════════════════════════════════════════════════════════

class AppShadows {
  AppShadows._();

  static List<BoxShadow> lightSm = [
    BoxShadow(color: const Color(0xFF64748B).withOpacity(0.06),
        blurRadius: 8, offset: const Offset(0, 2)),
    BoxShadow(color: const Color(0xFF64748B).withOpacity(0.04),
        blurRadius: 2, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> lightMd = [
    BoxShadow(color: const Color(0xFF64748B).withOpacity(0.10),
        blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: const Color(0xFF64748B).withOpacity(0.06),
        blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> lightLg = [
    BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.08),
        blurRadius: 40, offset: const Offset(0, 8)),
    BoxShadow(color: const Color(0xFF64748B).withOpacity(0.12),
        blurRadius: 16, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> darkSm = [
    BoxShadow(color: Colors.black.withOpacity(0.25),
        blurRadius: 8, offset: const Offset(0, 2)),
    BoxShadow(color: AppColors.purple600.withOpacity(0.04),
        blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> darkMd = [
    BoxShadow(color: Colors.black.withOpacity(0.40),
        blurRadius: 24, offset: const Offset(0, 6)),
    BoxShadow(color: AppColors.purple600.withOpacity(0.08),
        blurRadius: 12, offset: const Offset(0, 3)),
  ];

  static List<BoxShadow> darkLg = [
    BoxShadow(color: Colors.black.withOpacity(0.50),
        blurRadius: 48, offset: const Offset(0, 12)),
    BoxShadow(color: AppColors.purple600.withOpacity(0.15),
        blurRadius: 24, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> purpleGlow = [
    BoxShadow(color: AppColors.purple600.withOpacity(0.35),
        blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: AppColors.purple600.withOpacity(0.15),
        blurRadius: 40, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> blueGlow = [
    BoxShadow(color: AppColors.blue500.withOpacity(0.30),
        blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: AppColors.blue500.withOpacity(0.12),
        blurRadius: 32, offset: const Offset(0, 8)),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const primary = AppColors.blue600;
    const onPrimary = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary:          primary,
        onPrimary:        onPrimary,
        primaryContainer: AppColors.blue50,
        onPrimaryContainer: AppColors.blue700,
        secondary:        AppColors.purple500,
        onSecondary:      Colors.white,
        secondaryContainer: AppColors.purple50,
        onSecondaryContainer: AppColors.purple700,
        surface:          AppColors.lightSurface,
        onSurface:        AppColors.lightText,
        surfaceContainerHighest: AppColors.lightBg,
        outline:          AppColors.lightBorder,
        outlineVariant:   AppColors.lightBorderAlt,
        error:            AppColors.error,
        onError:          Colors.white,
        shadow:           Color(0x1A64748B),
      ),

      scaffoldBackgroundColor: AppColors.lightBg,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.lightSurface.withOpacity(0.95),
        foregroundColor: AppColors.lightText,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightTextSub, size: 22,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs, horizontal: 0),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: AppColors.lightBorder,
          disabledForegroundColor: AppColors.lightTextMute,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md + 2),
          textStyle: AppTextStyles.h4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: AppColors.blue500, width: 1.5),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md + 2),
          textStyle: AppTextStyles.h4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          textStyle: AppTextStyles.h4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.lightTextMute),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.lightTextSub),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.lightTextMute,
        suffixIconColor: AppColors.lightTextMute,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.blue50,
        selectedColor: primary,
        iconColor: AppColors.lightTextSub,
        titleTextStyle: AppTextStyles.body.copyWith(color: AppColors.lightText),
        subtitleTextStyle:
            AppTextStyles.bodySm.copyWith(color: AppColors.lightTextSub),
      ),

      // Icon
      iconTheme: const IconThemeData(
          color: AppColors.lightTextSub, size: 22),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBg,
        selectedColor: AppColors.blue50,
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.lightTextSub),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextMute;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.lightBorder;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: AppColors.lightBorder,
        thumbColor: primary,
        overlayColor: AppColors.blue500.withOpacity(0.12),
        trackHeight: 4,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.lightText),
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.lightTextSub),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightText,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.lightTextMute,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.h4,
        unselectedLabelStyle: AppTextStyles.body,
        dividerColor: AppColors.lightBorder,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightText,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),

      // Text
      textTheme: _buildTextTheme(AppColors.lightText, AppColors.lightTextSub),
    );
  }

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const primary = AppColors.purple600;
    const onPrimary = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary:          primary,
        onPrimary:        onPrimary,
        primaryContainer: AppColors.purple900,
        onPrimaryContainer: AppColors.purple300,
        secondary:        AppColors.purple400,
        onSecondary:      Colors.white,
        secondaryContainer: AppColors.purple800,
        onSecondaryContainer: AppColors.purple100,
        surface:          AppColors.darkSurface,
        onSurface:        AppColors.darkText,
        surfaceContainerHighest: AppColors.darkSurface2,
        outline:          AppColors.darkBorder,
        outlineVariant:   AppColors.darkBorderAlt,
        error:            AppColors.error,
        onError:          Colors.white,
        shadow:           Colors.black,
      ),

      scaffoldBackgroundColor: AppColors.darkBg,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface.withOpacity(0.95),
        foregroundColor: AppColors.darkText,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.darkText),
        iconTheme: const IconThemeData(
            color: AppColors.darkTextSub, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs, horizontal: 0),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: AppColors.darkSurface3,
          disabledForegroundColor: AppColors.darkTextMute,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md + 2),
          textStyle: AppTextStyles.h4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple400,
          side: const BorderSide(color: AppColors.purple600, width: 1.5),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md + 2),
          textStyle: AppTextStyles.h4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple400,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          textStyle: AppTextStyles.h4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.darkTextMute),
        labelStyle:
            AppTextStyles.body.copyWith(color: AppColors.darkTextSub),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.darkTextMute,
        suffixIconColor: AppColors.darkTextMute,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.purple900.withOpacity(0.5),
        selectedColor: AppColors.purple400,
        iconColor: AppColors.darkTextSub,
        titleTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.darkText),
        subtitleTextStyle:
            AppTextStyles.bodySm.copyWith(color: AppColors.darkTextSub),
      ),

      // Icon
      iconTheme: const IconThemeData(
          color: AppColors.darkTextSub, size: 22),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface2,
        selectedColor: AppColors.purple900,
        labelStyle:
            AppTextStyles.label.copyWith(color: AppColors.darkTextSub),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.darkTextMute;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.darkSurface3;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: AppColors.darkSurface3,
        thumbColor: AppColors.purple400,
        overlayColor: AppColors.purple600.withOpacity(0.15),
        trackHeight: 4,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.darkText),
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.darkTextSub),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface3,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.darkText),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.purple400,
        unselectedLabelColor: AppColors.darkTextMute,
        indicatorColor: AppColors.purple500,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.h4,
        unselectedLabelStyle: AppTextStyles.body,
        dividerColor: AppColors.darkBorder,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSurface3,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: AppColors.darkBorder),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.darkText),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),

      // Text
      textTheme:
          _buildTextTheme(AppColors.darkText, AppColors.darkTextSub),
    );
  }

  // ── Text theme builder ────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:  AppTextStyles.display.copyWith(color: primary),
      displayMedium: AppTextStyles.displaySm.copyWith(color: primary),
      displaySmall:  AppTextStyles.h1.copyWith(color: primary),
      headlineLarge: AppTextStyles.h1.copyWith(color: primary),
      headlineMedium:AppTextStyles.h2.copyWith(color: primary),
      headlineSmall: AppTextStyles.h3.copyWith(color: primary),
      titleLarge:    AppTextStyles.h2.copyWith(color: primary),
      titleMedium:   AppTextStyles.h3.copyWith(color: primary),
      titleSmall:    AppTextStyles.h4.copyWith(color: primary),
      bodyLarge:     AppTextStyles.bodyLg.copyWith(color: primary),
      bodyMedium:    AppTextStyles.body.copyWith(color: primary),
      bodySmall:     AppTextStyles.bodySm.copyWith(color: secondary),
      labelLarge:    AppTextStyles.label.copyWith(color: primary),
      labelMedium:   AppTextStyles.label.copyWith(color: secondary),
      labelSmall:    AppTextStyles.labelSm.copyWith(color: secondary),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME EXTENSION — access design tokens via Theme.of(context).extension
// ═══════════════════════════════════════════════════════════════════════════════

class PulseTheme extends ThemeExtension<PulseTheme> {
  final bool isDark;
  final Color primary;
  final Color primarySubtle;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> glowShadow;

  const PulseTheme({
    required this.isDark,
    required this.primary,
    required this.primarySubtle,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.glowShadow,
  });

  static const light = PulseTheme(
    isDark: false,
    primary: AppColors.blue600,
    primarySubtle: AppColors.blue50,
    surface: AppColors.lightSurface,
    surfaceAlt: AppColors.lightBg,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightText,
    textSecondary: AppColors.lightTextSub,
    textMuted: AppColors.lightTextMute,
    shadowSm: [],
    shadowMd: [],
    shadowLg: [],
    glowShadow: [],
  );

  static const dark = PulseTheme(
    isDark: true,
    primary: AppColors.purple600,
    primarySubtle: AppColors.purple900,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurface2,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkText,
    textSecondary: AppColors.darkTextSub,
    textMuted: AppColors.darkTextMute,
    shadowSm: [],
    shadowMd: [],
    shadowLg: [],
    glowShadow: [],
  );

  @override
  PulseTheme copyWith({
    bool? isDark, Color? primary, Color? primarySubtle,
    Color? surface, Color? surfaceAlt, Color? border,
    Color? textPrimary, Color? textSecondary, Color? textMuted,
    List<BoxShadow>? shadowSm, List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg, List<BoxShadow>? glowShadow,
  }) {
    return PulseTheme(
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      glowShadow: glowShadow ?? this.glowShadow,
    );
  }

  @override
  PulseTheme lerp(PulseTheme? other, double t) {
    if (other == null) return this;
    return PulseTheme(
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySubtle: Color.lerp(primarySubtle, other.primarySubtle, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      shadowSm: t < 0.5 ? shadowSm : other.shadowSm,
      shadowMd: t < 0.5 ? shadowMd : other.shadowMd,
      shadowLg: t < 0.5 ? shadowLg : other.shadowLg,
      glowShadow: t < 0.5 ? glowShadow : other.glowShadow,
    );
  }
}

// ── Helper extension for easy access ─────────────────────────────────────────
extension ThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs   => Theme.of(this).colorScheme;
  bool get isDark      => Theme.of(this).brightness == Brightness.dark;
  Color get primary    => isDark ? AppColors.purple600 : AppColors.blue600;
  Color get primarySoft=> isDark ? AppColors.purple900 : AppColors.blue50;
  Color get surface    => isDark ? AppColors.darkSurface  : AppColors.lightSurface;
  Color get surfaceAlt => isDark ? AppColors.darkSurface2 : AppColors.lightBg;
  Color get border     => isDark ? AppColors.darkBorder   : AppColors.lightBorder;
  Color get textPrimary   => isDark ? AppColors.darkText     : AppColors.lightText;
  Color get textSecondary => isDark ? AppColors.darkTextSub  : AppColors.lightTextSub;
  Color get textMuted     => isDark ? AppColors.darkTextMute : AppColors.lightTextMute;
  List<BoxShadow> get shadowSm  => isDark ? AppShadows.darkSm  : AppShadows.lightSm;
  List<BoxShadow> get shadowMd  => isDark ? AppShadows.darkMd  : AppShadows.lightMd;
  List<BoxShadow> get shadowLg  => isDark ? AppShadows.darkLg  : AppShadows.lightLg;
  List<BoxShadow> get glowShadow=> isDark ? AppShadows.purpleGlow : AppShadows.blueGlow;
}