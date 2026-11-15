import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/theme/theme_provider.dart';
import 'package:hotel_app/presentation/widgets/reservations/reservation_status_chip.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_status_badge.dart';

void main() {
  group('H-19: Design System & Consistencia Visual Material 3', () {
    testWidgets('AppTheme: Todos los componentes interactivos tienen BorderRadius de 16',
        (tester) async {
      final light = const AppTheme(isDarkMode: false).getTheme();
      final dark = const AppTheme(isDarkMode: true).getTheme();

      for (final theme in [light, dark]) {
        // Tarjetas
        final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(cardShape.borderRadius, BorderRadius.circular(16));

        // Botones elevados
        final elevatedShape =
            theme.elevatedButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder;
        expect(elevatedShape.borderRadius, BorderRadius.circular(16));

        // Botones filled
        final filledShape =
            theme.filledButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder;
        expect(filledShape.borderRadius, BorderRadius.circular(16));

        // Botones outlined
        final outlinedShape =
            theme.outlinedButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder;
        expect(outlinedShape.borderRadius, BorderRadius.circular(16));

        // Chips
        final chipShape = theme.chipTheme.shape as RoundedRectangleBorder;
        expect(chipShape.borderRadius, BorderRadius.circular(16));

        // Diálogos
        final dialogShape = theme.dialogTheme.shape as RoundedRectangleBorder;
        expect(dialogShape.borderRadius, BorderRadius.circular(16));

        // Inputs
        final inputBorder = theme.inputDecorationTheme.border as OutlineInputBorder;
        expect(inputBorder.borderRadius, BorderRadius.circular(16));
      }
    });

    testWidgets('RoomStatusBadge: respeta BorderRadius de 16 y tokens de color en claro y oscuro',
        (tester) async {
      final lightTheme = const AppTheme(isDarkMode: false).getTheme();
      final darkTheme = const AppTheme(isDarkMode: true).getTheme();

      // ── Modo Claro ──
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('light_app'),
          theme: lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                RoomStatusBadge(status: RoomStatus.available),
                RoomStatusBadge(status: RoomStatus.available, compact: true),
              ],
            ),
          ),
        ),
      );

      final containersLight = tester.widgetList<Container>(find.byType(Container)).toList();
      final standardBoxLight = containersLight[0].decoration as BoxDecoration;
      final compactBoxLight = containersLight[1].decoration as BoxDecoration;

      expect(standardBoxLight.borderRadius, BorderRadius.circular(16));
      expect(compactBoxLight.borderRadius, BorderRadius.circular(16));
      expect(
        (standardBoxLight.border as Border).top.color,
        AppColors.statusSuccessLight.withValues(alpha: 0.3),
      );

      // ── Modo Oscuro ──
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark_app'),
          theme: darkTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Column(
              children: [
                RoomStatusBadge(status: RoomStatus.available),
                RoomStatusBadge(status: RoomStatus.available, compact: true),
              ],
            ),
          ),
        ),
      );

      final containersDark = tester.widgetList<Container>(find.byType(Container)).toList();
      final standardBoxDark = containersDark[0].decoration as BoxDecoration;
      expect(standardBoxDark.borderRadius, BorderRadius.circular(16));
      expect(
        (standardBoxDark.border as Border).top.color,
        AppColors.statusSuccessDark.withValues(alpha: 0.3),
      );
    });

    testWidgets('ReservationStatusChip: respeta BorderRadius de 16 y tokens de color en claro y oscuro',
        (tester) async {
      final lightTheme = const AppTheme(isDarkMode: false).getTheme();
      final darkTheme = const AppTheme(isDarkMode: true).getTheme();

      // ── Modo Claro ──
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('light_chip_app'),
          theme: lightTheme,
          home: const Scaffold(
            body: ReservationStatusChip(status: ReservationStatus.checkedIn),
          ),
        ),
      );

      final containerLight = tester.widget<Container>(find.byType(Container));
      final boxLight = containerLight.decoration as BoxDecoration;

      expect(boxLight.borderRadius, BorderRadius.circular(16));
      expect(
        (boxLight.border as Border).top.color,
        AppColors.statusSuccessLight.withValues(alpha: 0.35),
      );

      // ── Modo Oscuro ──
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark_chip_app'),
          theme: darkTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: ReservationStatusChip(status: ReservationStatus.checkedIn),
          ),
        ),
      );

      final containerDark = tester.widget<Container>(find.byType(Container));
      final boxDark = containerDark.decoration as BoxDecoration;

      expect(boxDark.borderRadius, BorderRadius.circular(16));
      expect(
        (boxDark.border as Border).top.color,
        AppColors.statusSuccessDark.withValues(alpha: 0.35),
      );
    });

    test('Homogeneización de colores de estado entre badges y chips', () {
      final lightStatus = AppStatusColors.light;
      final darkStatus = AppStatusColors.dark;

      // Colores de éxito/activo compartidos
      expect(lightStatus.success, AppColors.statusSuccessLight);
      expect(darkStatus.success, AppColors.statusSuccessDark);

      // Colores de advertencia/pendientes compartidos
      expect(lightStatus.warning, AppColors.statusWarningLight);
      expect(darkStatus.warning, AppColors.statusWarningDark);

      // Colores informativos/en curso compartidos
      expect(lightStatus.info, AppColors.statusInfoLight);
      expect(darkStatus.info, AppColors.statusInfoDark);
    });

    test('themeModeProvider: alterna estados correctamente', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
