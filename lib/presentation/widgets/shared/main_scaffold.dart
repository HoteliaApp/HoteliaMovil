import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';

/// Scaffold principal que contiene la BottomNavigationBar y un menú lateral.
class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).role ?? UserRole.unassigned;

    // Mantiene vivo el cierre automático del ciclo tarea-habitación mientras
    // haya sesión activa.
    ref.watch(taskRoomSyncServiceProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // Bloquear navegacion a reservaciones (index 2) para mucamas y mantenimiento
          if (index == 2 && (role == UserRole.housekeeper || role == UserRole.maintenance)) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No tienes permisos para ver las reservaciones.'))
             );
             return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}


class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.bed_outlined),
          selectedIcon: Icon(Icons.bed_rounded),
          label: 'Cuartos',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note_rounded),
          label: 'Reservas',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}
