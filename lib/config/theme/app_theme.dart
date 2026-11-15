import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores del proyecto Hotel App
class AppColors {
  AppColors._();

  /// Naranja principal — color de marca
  static const Color primary = Color(0xFFFF661A);

  /// Gris claro — fondo principal en modo claro
  static const Color backgroundLight = Color(0xFFF0F0F0);

  /// Gris oscuro — fondo en modo oscuro / texto principal
  static const Color backgroundDark = Color(0xFF303030);

  /// Durazno/salmón claro — color secundario / acentos
  static const Color secondary = Color(0xFFEFB49F);

  /// Blanco humo — superficies / tarjetas en modo claro
  static const Color surface = Color(0xFFF2F2F2);

  /// Verde — color de éxito
  static const Color success = Color(0xFF4CAF50);

  // ── Paleta de estados semánticos (Modo claro) ──
  static const Color statusSuccessLight = Color(0xFF2E7D32);
  static const Color statusInfoLight = Color(0xFF1565C0);
  static const Color statusWarningLight = Color(0xFFE65100);
  static const Color statusDangerLight = Color(0xFFC62828);
  static const Color statusPurpleLight = Color(0xFF6A1B9A);
  static const Color statusNeutralLight = Color(0xFF616161);

  // ── Paleta de estados semánticos (Modo oscuro - luminosos para alto contraste y descanso visual) ──
  static const Color statusSuccessDark = Color(0xFF81C784);
  static const Color statusInfoDark = Color(0xFF64B5F6);
  static const Color statusWarningDark = Color(0xFFFFB74D);
  static const Color statusDangerDark = Color(0xFFE57373);
  static const Color statusPurpleDark = Color(0xFFBA68C8);
  static const Color statusNeutralDark = Color(0xFFB0BEC5);
}

/// Colores semánticos de estado según el brillo del tema activo (claro u oscuro).
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

/// Clase que gestiona el tema de la aplicación.
/// Soporta modo claro y oscuro con la misma paleta de colores y bordes redondeados consistentes (16px).
class AppTheme {
  final bool isDarkMode;

  const AppTheme({this.isDarkMode = false});

  /// TextTheme base con Poppins para modo claro (texto oscuro sobre fondo claro).
  static final TextTheme _poppinsLight = GoogleFonts.poppinsTextTheme(
    ThemeData(brightness: Brightness.light).textTheme,
  );

  /// TextTheme base con Poppins para modo oscuro (texto claro sobre fondo oscuro).
  static final TextTheme _poppinsDark = GoogleFonts.poppinsTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  /// Configuración de transiciones de página fluidas
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

  // ─────────────────────────────── Tema Claro ──────────────────────────────
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: _poppinsLight,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: _pageTransitionsTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      // Primario
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.secondary,
      onPrimaryContainer: AppColors.backgroundDark,
      // Secundario
      secondary: AppColors.secondary,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: Color(0xFFFFDDD0),
      onSecondaryContainer: AppColors.backgroundDark,
      // Superficie
      surface: AppColors.surface,
      onSurface: AppColors.backgroundDark,
      surfaceContainerHighest: AppColors.backgroundLight,
      onSurfaceVariant: Color(0xFF555555),
      // Error
      error: Color(0xFFB00020),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      // Outline
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      // Misc
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: AppColors.backgroundDark,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.secondary,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardColor: AppColors.surface,
    dividerColor: const Color(0xFFE0E0E0),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.backgroundDark);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold);
        }
        return const TextStyle(color: AppColors.backgroundDark);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );

  // ─────────────────────────────── Tema Oscuro ─────────────────────────────
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _poppinsDark,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: _pageTransitionsTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      // Primario
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF8C3000),
      onPrimaryContainer: AppColors.secondary,
      // Secundario
      secondary: AppColors.secondary,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: Color(0xFF5D3728),
      onSecondaryContainer: AppColors.secondary,
      // Superficie
      surface: Color(0xFF1E1E1E),
      onSurface: AppColors.backgroundLight,
      surfaceContainerHighest: AppColors.backgroundDark,
      onSurfaceVariant: Color(0xFFBDBDBD),
      // Error
      error: Color(0xFFCF6679),
      onError: Colors.black,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      // Outline
      outline: Color(0xFF555555),
      outlineVariant: Color(0xFF404040),
      // Misc
      shadow: Colors.black54,
      scrim: Colors.black87,
      inverseSurface: AppColors.backgroundLight,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: Color(0xFF8C3000),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: AppColors.backgroundDark,
    dividerColor: const Color(0xFF404040),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.backgroundLight,
      elevation: 0,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.primary.withValues(alpha: 0.25),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.backgroundLight);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold);
        }
        return const TextStyle(color: AppColors.backgroundLight);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF555555)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF555555)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}
