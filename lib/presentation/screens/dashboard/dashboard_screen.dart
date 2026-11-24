import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/dashboard/dashboard_provider.dart';
import 'package:hotel_app/presentation/widgets/dashboard/send_alert_dialog.dart';
import 'package:hotel_app/presentation/widgets/dashboard/tasks_panel_widget.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final fg = theme.appBarTheme.foregroundColor ?? Colors.white;

    // Saludo dinámico según hora del día
    final hour = DateTime.now().hour;
    final greeting = (hour >= 5 && hour < 12)
        ? '¡Buenos días!'
        : (hour >= 12 && hour < 19)
            ? '¡Buenas tardes!'
            : '¡Buenas noches!';

    final userEmail = authState.email ?? 'Recepción';
    final userName =
        userEmail.contains('@') ? userEmail.split('@').first : userEmail;

    return Scaffold(
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // ── AppBar plano coherente con el tema ──────────────────────
            SliverAppBar(
              pinned: true,
              floating: true,
              toolbarHeight: 68,
              centerTitle: false,
              titleSpacing: AppSpacing.lg,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    'Hola, $userName',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                if (authState.role == UserRole.admin)
                  IconButton(
                    onPressed: () => context.push('/admin/audit'),
                    icon: const Icon(Icons.history_edu_rounded),
                    tooltip: 'Bitácora de Auditoría',
                  ),
                if (authState.role == UserRole.admin ||
                    authState.role == UserRole.receptionist)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SendAlertDialog(),
                      );
                    },
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Enviar Alerta Wearable',
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg, left: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.16),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Text(
                      DateFormat('dd MMM', 'es').format(DateTime.now()),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (state.isLoading &&
                state.roomStats.total == 0 &&
                state.activeTasks.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: AppSpacing.screen,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Estadísticas de habitaciones ───────────────
                    const AppSectionTitle(
                      title: 'Habitaciones',
                      icon: Icons.hotel_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoomStatsGrid(
                      stats: state.roomStats,
                      activeTasksCount: state.activeTasksCount,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Alertas (check-ins/outs próximos) ──────────
                    if (authState.role == UserRole.admin ||
                        authState.role == UserRole.receptionist) ...[
                      AppSectionTitle(
                        title: 'Alertas de actividad',
                        icon: Icons.notifications_active_rounded,
                        subtitle: state.alerts.isEmpty
                            ? null
                            : '${state.alerts.length} pendiente${state.alerts.length != 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (state.alerts.isEmpty)
                        const AppEmptyState(
                          inCard: true,
                          icon: Icons.notifications_none_rounded,
                          title: 'Sin alertas por ahora',
                        )
                      else
                        ...state.alerts.map((alert) => _AlertCard(alert: alert)),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // ── Tareas activas (en tiempo real desde Firebase) ──
                    const TasksPanelWidget(),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Próximas reservaciones ─────────────────────
                    if (authState.role == UserRole.admin ||
                        authState.role == UserRole.receptionist) ...[
                      AppSectionTitle(
                        title: 'Reservaciones próximas',
                        icon: Icons.calendar_month_rounded,
                        subtitle: state.upcomingReservations.isEmpty
                            ? null
                            : '${state.upcomingReservations.length} activa${state.upcomingReservations.length != 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (state.upcomingReservations.isEmpty)
                        const AppEmptyState(
                          inCard: true,
                          icon: Icons.event_available_rounded,
                          title: 'Sin reservaciones próximas',
                        )
                      else
                        ...state.upcomingReservations.map(
                          (r) => _ReservationTile(reservation: r),
                        ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Componentes internos ──────────────────────────────────────────────────────

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
      mainAxisSpacing: AppSpacing.sm + 2,
      crossAxisSpacing: AppSpacing.sm + 2,
      childAspectRatio: 2.2,
      children: [
        AppStatCard(
          label: 'Disponibles',
          value: '${stats.available}',
          icon: Icons.check_circle_rounded,
          color: statusColors.success,
          onTap: () {},
        ),
        AppStatCard(
          label: 'Ocupadas',
          value: '${stats.occupied}',
          icon: Icons.person_rounded,
          color: statusColors.danger,
          onTap: () {},
        ),
        AppStatCard(
          label: 'Pendientes de limpieza',
          value: '${stats.pendingCleaning}',
          icon: Icons.cleaning_services_rounded,
          color: statusColors.warning,
          onTap: () {},
        ),
        AppStatCard(
          label: 'Reservadas',
          value: '${stats.reserved}',
          icon: Icons.bookmark_rounded,
          color: statusColors.info,
          onTap: () {},
        ),
        AppStatCard(
          label: 'Mantenimiento',
          value: '${stats.maintenance}',
          icon: Icons.build_rounded,
          color: statusColors.neutral,
          onTap: () {},
        ),
        AppStatCard(
          label: 'Tareas activas',
          value: '$activeTasksCount',
          icon: Icons.assignment_turned_in_rounded,
          color: statusColors.purple,
          onTap: () {},
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DashboardAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final isCheckIn = alert.type == 'checkIn';
    final color = isCheckIn ? statusColors.success : theme.colorScheme.primary;
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final timeStr = DateFormat('HH:mm').format(alert.scheduledAt);
    final dayStr = alert.isToday ? 'Hoy' : 'Mañana';

    return AppCard(
      accent: color,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {},
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: color),
          const SizedBox(width: AppSpacing.md),
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
                    const SizedBox(width: AppSpacing.xs + 2),
                    AppPill(label: alert.label, color: color, dense: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, size: AppIconSize.sm - 2, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$dayStr $timeStr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
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
        ReservationStatus.confirmed => Icons.check_circle_rounded,
        ReservationStatus.checkedIn => Icons.login_rounded,
        ReservationStatus.completed => Icons.logout_rounded,
        ReservationStatus.cancelled => Icons.cancel_rounded,
      };

  IconData get _leadingIcon => switch (reservation.status) {
        ReservationStatus.checkedIn => Icons.person_rounded,
        ReservationStatus.confirmed => Icons.event_available_rounded,
        ReservationStatus.newReservation => Icons.bookmark_add_rounded,
        _ => Icons.calendar_today_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(context);
    final checkInStr = DateFormat('dd/MM').format(reservation.checkIn);
    final checkOutStr = DateFormat('dd/MM').format(reservation.checkOut);

    return AppCard(
      accent: color,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {},
      child: Row(
        children: [
          AppIconBadge(icon: _leadingIcon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hab. ${reservation.roomNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    AppPill(
                      label: reservation.status.label,
                      color: color,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(_statusIcon, size: AppIconSize.sm - 2, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$checkInStr → $checkOutStr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
