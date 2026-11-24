import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
//  HOTELIA DESIGN SYSTEM
//  Fuente única de verdad visual. Este archivo se replica (adaptado al
//  dispositivo) en HoteliaMovil, HoteliaSmart (TV) y HoteliaWear (reloj).
//  Si cambias un token aquí, replícalo en las otras dos apps.
// ════════════════════════════════════════════════════════════════════════════

/// Paleta de colores de marca y neutros.
class AppColors {
  AppColors._();

  // ── Marca ──
  /// Naranja principal — color de marca.
  static const Color primary = Color(0xFFFF661A);

  /// Naranja profundo — estados presionados / variantes oscuras de marca.
  static const Color primaryDark = Color(0xFFD4510E);

  /// Durazno/salmón claro — color secundario / acentos suaves.
  static const Color secondary = Color(0xFFEFB49F);

  // ── Neutros modo claro ──
  /// Gris claro — fondo de pantallas en modo claro.
  static const Color backgroundLight = Color(0xFFF0F0F0);

  /// Blanco humo — superficies en modo claro.
  static const Color surface = Color(0xFFF2F2F2);

  /// Blanco — tarjetas en modo claro.
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Neutros modo oscuro ──
  /// Negro suave — fondo de pantallas en modo oscuro.
  static const Color scaffoldDark = Color(0xFF121212);

  /// Superficie oscura — diálogos, hojas inferiores, barra de navegación.
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Gris oscuro — tarjetas en modo oscuro / texto principal en modo claro.
  static const Color backgroundDark = Color(0xFF303030);

  /// Alias semántico de [backgroundDark] para tarjetas en modo oscuro.
  static const Color cardDark = backgroundDark;

  /// Verde — color de éxito (legado, preferir [AppStatusColors.success]).
  static const Color success = Color(0xFF4CAF50);

  // ── Paleta de estados semánticos (modo claro) ──
  static const Color statusSuccessLight = Color(0xFF2E7D32);
  static const Color statusInfoLight = Color(0xFF1565C0);
  static const Color statusWarningLight = Color(0xFFE65100);
  static const Color statusDangerLight = Color(0xFFC62828);
  static const Color statusPurpleLight = Color(0xFF6A1B9A);
  static const Color statusNeutralLight = Color(0xFF616161);

  // ── Paleta de estados semánticos (modo oscuro: luminosos, alto contraste) ──
  static const Color statusSuccessDark = Color(0xFF81C784);
  static const Color statusInfoDark = Color(0xFF64B5F6);
  static const Color statusWarningDark = Color(0xFFFFB74D);
  static const Color statusDangerDark = Color(0xFFE57373);
  static const Color statusPurpleDark = Color(0xFFBA68C8);
  static const Color statusNeutralDark = Color(0xFFB0BEC5);
}

/// Colores semánticos de estado según el brillo del tema activo.
///
/// Uso: `final s = AppStatusColors.of(context); s.success`.
/// Nunca uses `Colors.green`, `Colors.red`, etc. para comunicar estados.
class AppStatusColors {
  final Color success;
  final Color info;
  final Color warning;
  final Color danger;
  final Color purple;
  final Color neutral;

  const AppStatusColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
    required this.purple,
    required this.neutral,
  });

  static AppStatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark ||
        theme.colorScheme.brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  static const light = AppStatusColors(
    success: AppColors.statusSuccessLight,
    info: AppColors.statusInfoLight,
    warning: AppColors.statusWarningLight,
    danger: AppColors.statusDangerLight,
    purple: AppColors.statusPurpleLight,
    neutral: AppColors.statusNeutralLight,
  );

  static const dark = AppStatusColors(
    success: AppColors.statusSuccessDark,
    info: AppColors.statusInfoDark,
    warning: AppColors.statusWarningDark,
    danger: AppColors.statusDangerDark,
    purple: AppColors.statusPurpleDark,
    neutral: AppColors.statusNeutralDark,
  );
}

/// Radios de borde. El estándar de la marca es [md] (16).
class AppRadius {
  AppRadius._();

  /// Elementos diminutos: barras de progreso, indicadores, miniaturas.
  static const double sm = 8;

  /// Estándar: tarjetas, botones, inputs, chips, diálogos.
  static const double md = 16;

  /// Contenedores grandes / hero / paneles de TV.
  static const double lg = 24;

  static final BorderRadius smAll = BorderRadius.circular(sm);
  static final BorderRadius mdAll = BorderRadius.circular(md);
  static final BorderRadius lgAll = BorderRadius.circular(lg);
}

/// Escala de espaciado (múltiplos de 4).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Padding horizontal estándar de pantalla.
  static const EdgeInsets screen = EdgeInsets.all(lg);
}

/// Tamaños de iconos.
class AppIconSize {
  AppIconSize._();

  static const double xs = 14;
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;

  /// Ilustraciones de estados vacíos / error.
  static const double hero = 56;
}

/// Opacidades estándar para tintes de color semántico.
class AppAlpha {
  AppAlpha._();

  /// Fondo de tarjeta tintada.
  static const double tint = 0.08;

  /// Fondo de ícono circular / chip.
  static const double badge = 0.12;

  /// Borde de tarjeta tintada (modo claro).
  static const double border = 0.25;

  /// Borde de tarjeta tintada (modo oscuro).
  static const double borderDark = 0.35;
}

/// Sombras estándar.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Clase que gestiona el tema de la aplicación.
/// Soporta modo claro y oscuro con la misma paleta y bordes de 16px.
class AppTheme {
  final bool isDarkMode;

  const AppTheme({this.isDarkMode = false});

  /// Ajusta pesos tipográficos de la escala Poppins para jerarquía consistente.
  static TextTheme _withWeights(TextTheme t) => t.copyWith(
        headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      );

  /// TextTheme base con Poppins para modo claro.
  static final TextTheme _poppinsLight = _withWeights(
    GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.light).textTheme),
  );

  /// TextTheme base con Poppins para modo oscuro.
  static final TextTheme _poppinsDark = _withWeights(
    GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
  );

  /// Configuración de transiciones de página fluidas.
  static const PageTransitionsTheme _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    },
  );

  ThemeData getTheme() => isDarkMode ? _darkTheme : _lightTheme;

  static final RoundedRectangleBorder _shape =
      RoundedRectangleBorder(borderRadius: AppRadius.mdAll);

  // ─────────────────────────────── Tema Claro ──────────────────────────────
  static final ThemeData _lightTheme = _build(
    brightness: Brightness.light,
    textTheme: _poppinsLight,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.secondary,
      onPrimaryContainer: AppColors.backgroundDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: Color(0xFFFFDDD0),
      onSecondaryContainer: AppColors.backgroundDark,
      surface: AppColors.surface,
      onSurface: AppColors.backgroundDark,
      surfaceContainerLowest: AppColors.cardLight,
      surfaceContainerLow: Color(0xFFFAFAFA),
      surfaceContainer: Color(0xFFF5F5F5),
      surfaceContainerHigh: Color(0xFFEEEEEE),
      surfaceContainerHighest: Color(0xFFE8E8E8),
      onSurfaceVariant: Color(0xFF555555),
      error: Color(0xFFB00020),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: AppColors.backgroundDark,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.secondary,
    ),
    scaffold: AppColors.backgroundLight,
    card: AppColors.cardLight,
    divider: const Color(0xFFE0E0E0),
    appBarBg: AppColors.primary,
    appBarFg: Colors.white,
    navUnselected: AppColors.backgroundDark,
    inputFill: AppColors.cardLight,
    inputBorder: const Color(0xFFE0E0E0),
  );

  // ─────────────────────────────── Tema Oscuro ─────────────────────────────
  static final ThemeData _darkTheme = _build(
    brightness: Brightness.dark,
    textTheme: _poppinsDark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF8C3000),
      onPrimaryContainer: AppColors.secondary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: Color(0xFF5D3728),
      onSecondaryContainer: AppColors.secondary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.backgroundLight,
      surfaceContainerLowest: Color(0xFF0F0F0F),
      surfaceContainerLow: Color(0xFF1A1A1A),
      surfaceContainer: AppColors.surfaceDark,
      surfaceContainerHigh: Color(0xFF262626),
      surfaceContainerHighest: AppColors.backgroundDark,
      onSurfaceVariant: Color(0xFFBDBDBD),
      error: Color(0xFFCF6679),
      onError: Colors.black,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      outline: Color(0xFF555555),
      outlineVariant: Color(0xFF404040),
      shadow: Colors.black54,
      scrim: Colors.black87,
      inverseSurface: AppColors.backgroundLight,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: Color(0xFF8C3000),
    ),
    scaffold: AppColors.scaffoldDark,
    card: AppColors.cardDark,
    divider: const Color(0xFF404040),
    appBarBg: AppColors.backgroundDark,
    appBarFg: AppColors.backgroundLight,
    navUnselected: AppColors.backgroundLight,
    inputFill: AppColors.backgroundDark,
    inputBorder: const Color(0xFF555555),
  );

  static ThemeData _build({
    required Brightness brightness,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color card,
    required Color divider,
    required Color appBarBg,
    required Color appBarFg,
    required Color navUnselected,
    required Color inputFill,
    required Color inputBorder,
  }) {
    final isDark = brightness == Brightness.dark;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: appBarFg),
        iconTheme: IconThemeData(color: appBarFg),
        actionsIconTheme: IconThemeData(color: appBarFg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: navUnselected);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium ?? const TextStyle();
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold);
          }
          return base.copyWith(color: navUnselected, fontWeight: FontWeight.w500);
        }),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: _shape,
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        shape: _shape,
        iconColor: colorScheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
        subtitleTextStyle:
            textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: _shape,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: _shape,
      ),
      chipTheme: ChipThemeData(
        shape: _shape,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: _shape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          shape: _shape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          shape: _shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: textTheme.labelLarge,
          shape: _shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
          shape: _shape,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
          selectedForegroundColor: AppColors.primary,
          shape: _shape,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: border(inputBorder),
        enabledBorder: border(inputBorder),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(colorScheme.error, 2),
      ),
    );
  }
}
