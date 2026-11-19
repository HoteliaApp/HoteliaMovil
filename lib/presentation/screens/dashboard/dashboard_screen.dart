import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/dashboard/dashboard_provider.dart';
import 'package:hotel_app/presentation/widgets/dashboard/tasks_panel_widget.dart';
import 'package:hotel_app/presentation/widgets/dashboard/send_alert_dialog.dart';
import 'package:go_router/go_router.dart';
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
    final userName = userEmail.contains('@')
        ? userEmail.split('@').first
        : userEmail;

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
                titlePadding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 14,
                ),
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
                // Botón Auditoría (Sólo Admin)
                if (authState.role == UserRole.admin)
                  IconButton(
                    onPressed: () => context.push('/admin/audit'),
                    icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
                    tooltip: 'Bitácora de Auditoría',
                  ),
                // Botón Alerta Wearable (Sólo Admin/Recepción)
                if (authState.role == UserRole.admin ||
                    authState.role == UserRole.receptionist)
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.white,
                        ),
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

            if (state.isLoading &&
                state.roomStats.total == 0 &&
                state.activeTasks.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
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
                    _RoomStatsGrid(
                      stats: state.roomStats,
                      activeTasksCount: state.activeTasksCount,
                    ),
                    const SizedBox(height: 24),

                    // ── Alertas (check-ins/outs próximos) ──────────
                    if (authState.role == UserRole.admin ||
                        authState.role == UserRole.receptionist) ...[
                      _SectionTitle(
                        title: 'Alertas de actividad',
                        icon: Icons.notifications_active_outlined,
                        subtitle: state.alerts.isEmpty
                            ? null
                            : '${state.alerts.length} pendiente${state.alerts.length != 1 ? 's' : ''}',
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
                    if (authState.role == UserRole.admin ||
                        authState.role == UserRole.receptionist) ...[
                      _SectionTitle(
                        title: 'Reservaciones próximas',
                        icon: Icons.calendar_month_rounded,
                        subtitle: state.upcomingReservations.isEmpty
                            ? null
                            : '${state.upcomingReservations.length} activa${state.upcomingReservations.length != 1 ? 's' : ''}',
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
  final IconData? icon;

  const _SectionTitle({required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: subtitle != null
              ? Container(
                  key: ValueKey<String>(subtitle!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey<String>('empty-subtitle')),
        ),
      ],
    );
  }
}

class _RoomStatsGrid extends StatelessWidget {
  final RoomStats stats;
  final int activeTasksCount;

  const _RoomStatsGrid({
    required this.stats,
    required this.activeTasksCount,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = AppStatusColors.of(context);

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
          color: statusColors.success,
        ),
        _StatCard(
          label: 'Ocupadas',
          value: stats.occupied,
          icon: Icons.person_rounded,
          color: statusColors.danger,
        ),
        _StatCard(
          label: 'Pendientes de limpieza',
          value: stats.pendingCleaning,
          icon: Icons.cleaning_services_outlined,
          color: statusColors.warning,
        ),
        _StatCard(
          label: 'Reservadas',
          value: stats.reserved,
          icon: Icons.bookmark_rounded,
          color: statusColors.info,
        ),
        _StatCard(
          label: 'Mantenimiento',
          value: stats.maintenance,
          icon: Icons.build_outlined,
          color: statusColors.neutral,
        ),
        _StatCard(
          label: 'Tareas activas',
          value: activeTasksCount,
          icon: Icons.assignment_turned_in_outlined,
          color: statusColors.purple,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Text(
                        '$value',
                        key: ValueKey<int>(value),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DashboardAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColors = AppStatusColors.of(context);
    final isCheckIn = alert.type == 'checkIn';
    final color = isCheckIn
        ? statusColors.success
        : Theme.of(context).colorScheme.primary;
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final timeStr = DateFormat('HH:mm').format(alert.scheduledAt);
    final dayStr = alert.isToday ? 'Hoy' : 'Mañana';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Ícono circular con fondo ──
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),

                // ── Información ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hab. ${alert.roomNumber}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TypeChip(label: alert.label, color: color),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.guestName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Tiempo / Fecha ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(height: 2),
                    Text(
                      '$dayStr $timeStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  const _ReservationTile({required this.reservation});

  Color _getColor(BuildContext context) {
    final statusColors = AppStatusColors.of(context);
    return switch (reservation.status) {
      ReservationStatus.newReservation => statusColors.warning,
      ReservationStatus.confirmed => statusColors.info,
      ReservationStatus.checkedIn => statusColors.success,
      ReservationStatus.completed => statusColors.purple,
      ReservationStatus.cancelled => statusColors.neutral,
    };
  }

  IconData get _statusIcon => switch (reservation.status) {
    ReservationStatus.newReservation => Icons.hourglass_empty_rounded,
    ReservationStatus.confirmed => Icons.check_circle_outline_rounded,
    ReservationStatus.checkedIn => Icons.login_rounded,
    ReservationStatus.completed => Icons.logout_rounded,
    ReservationStatus.cancelled => Icons.cancel_outlined,
  };

  IconData get _leadingIcon => switch (reservation.status) {
    ReservationStatus.checkedIn => Icons.person_rounded,
    ReservationStatus.confirmed => Icons.event_available_rounded,
    ReservationStatus.newReservation => Icons.bookmark_add_outlined,
    _ => Icons.calendar_today_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getColor(context);
    final checkInStr = DateFormat('dd/MM').format(reservation.checkIn);
    final checkOutStr = DateFormat('dd/MM').format(reservation.checkOut);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Ícono circular con fondo ──
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_leadingIcon, color: color, size: 18),
                ),
                const SizedBox(width: 12),

                // ── Información ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Habitación + Chip
                      Row(
                        children: [
                          Text(
                            'Hab. ${reservation.roomNumber}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TypeChip(
                            label: reservation.status.label,
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Huésped
                      Text(
                        reservation.guestName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Estado + fechas ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(_statusIcon, size: 16, color: color),
                    const SizedBox(height: 2),
                    Text(
                      '$checkInStr → $checkOutStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
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
      ),
    );
  }
}
