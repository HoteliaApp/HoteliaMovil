import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/dashboard/dashboard_provider.dart';
import 'package:hotel_app/presentation/widgets/dashboard/tasks_panel_widget.dart';
import 'package:hotel_app/presentation/widgets/dashboard/send_alert_dialog.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Saludo dinámico según hora del día
    final hour = DateTime.now().hour;
    final greeting = (hour >= 5 && hour < 12)
        ? '¡Buenos días!'
        : (hour >= 12 && hour < 19)
            ? '¡Buenas tardes!'
            : '¡Buenas noches!';
    // Email o nombre para el usuario autenticado
    final userEmail = authState.email ?? 'Recepción';
    final userName = userEmail.contains('@') ? userEmail.split('@').first : userEmail;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 20, right: 20, bottom: 14),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      'Hola, $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, Color(0xFFD4510E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                // Botón Alerta Wearable (Sólo Admin/Recepción)
                if (authState.role == UserRole.admin || authState.role == UserRole.receptionist)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SendAlertDialog(),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    tooltip: 'Enviar Alerta Wearable',
                  ),
                // Badge de usuario autenticado
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Fecha actual
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      DateFormat('dd MMM', 'es').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (state.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Estadísticas de habitaciones ───────────────
                    _SectionTitle(title: 'Habitaciones'),
                    const SizedBox(height: 10),
                    _RoomStatsGrid(stats: state.roomStats),
                    const SizedBox(height: 24),

                    // ── Alertas (check-ins/outs próximos) ──────────
                    if (authState.role == UserRole.admin || authState.role == UserRole.receptionist) ...[
                      _SectionTitle(
                        title: 'Alertas de actividad',
                        subtitle: state.alerts.isEmpty
                            ? null
                            : '${state.alerts.length} pendiente(s)',
                      ),
                      const SizedBox(height: 10),
                      if (state.alerts.isEmpty)
                        _EmptyCard(
                          icon: Icons.notifications_none_rounded,
                          message: 'Sin alertas por ahora',
                        )
                      else
                        ...state.alerts.map(
                          (alert) => _AlertCard(alert: alert),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // ── Tareas activas (en tiempo real desde Firebase) ──
                    const TasksPanelWidget(),
                    const SizedBox(height: 24),

                    // ── Próximas reservaciones ─────────────────────
                    if (authState.role == UserRole.admin || authState.role == UserRole.receptionist) ...[
                      _SectionTitle(
                        title: 'Reservaciones próximas',
                        subtitle: state.upcomingReservations.isEmpty
                            ? null
                            : '${state.upcomingReservations.length} activa(s)',
                      ),
                      const SizedBox(height: 10),
                      if (state.upcomingReservations.isEmpty)
                        _EmptyCard(
                          icon: Icons.event_available_outlined,
                          message: 'Sin reservaciones próximas',
                        )
                      else
                        ...state.upcomingReservations.map(
                          (r) => _ReservationTile(reservation: r),
                        ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Componentes internos ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoomStatsGrid extends StatelessWidget {
  final RoomStats stats;
  const _RoomStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          label: 'Disponibles',
          value: stats.available,
          icon: Icons.check_circle_outline,
          color: const Color(0xFF4CAF50),
        ),
        _StatCard(
          label: 'Ocupadas',
          value: stats.occupied,
          icon: Icons.person_rounded,
          color: isDarkMode ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.primary,
        ),
        _StatCard(
          label: 'Reservadas',
          value: stats.reserved,
          icon: Icons.bookmark_rounded,
          color: isDarkMode ? Colors.blue[200]! : const Color(0xFF5C6BC0),
        ),
        _StatCard(
          label: 'Mantenimiento',
          value: stats.maintenance,
          icon: Icons.build_outlined,
          //color: const Color.fromARGB(255, 36, 36, 36),
          color: isDarkMode ? const Color.fromARGB(255, 211, 211, 211)! : const Color.fromARGB(255, 37, 37, 36),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DashboardAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = alert.type == 'checkIn';
    final color = isCheckIn ? const Color(0xFF4CAF50) : Theme.of(context).colorScheme.primary;
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final timeStr = DateFormat('HH:mm').format(alert.scheduledAt);
    final dayStr = alert.isToday ? 'Hoy' : 'Mañana';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alert.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$dayStr $timeStr',
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.guestName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'Habitación ${alert.roomNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  const _ReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final checkInStr =
        DateFormat('dd/MM').format(reservation.checkIn);
    final checkOutStr =
        DateFormat('dd/MM').format(reservation.checkOut);
    final isCheckedIn = reservation.status == ReservationStatus.checkedIn;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCheckedIn ? Icons.person_rounded : Icons.event_available_rounded,
            color: isCheckedIn ? Theme.of(context).colorScheme.primary : const Color(0xFF5C6BC0),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.guestName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'Hab. ${reservation.roomId}  •  $checkInStr → $checkOutStr',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isCheckedIn ? Theme.of(context).colorScheme.primary : const Color(0xFF5C6BC0))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCheckedIn ? 'Adentro' : 'Confirmada',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCheckedIn
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF5C6BC0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
