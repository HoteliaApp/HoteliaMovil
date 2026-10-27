import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';

/// Panel de tareas activas para el Dashboard.
/// Muestra en tiempo real las tareas enviadas al wearable desde Firestore.
class TasksPanelWidget extends ConsumerWidget {
  const TasksPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(activeTasksProvider);

    return tasksAsync.when(
      // Mientras carga → nada visible (el resto del dashboard ya tiene su loader)
      loading: () => const SizedBox.shrink(),

      // Error de Firestore → aviso sutil, no bloqueante
      error: (e, _) => _TasksErrorBanner(message: e.toString()),

      data: (tasks) {
        // Sin tareas activas → no mostrar la sección
        if (tasks.isEmpty) return const SizedBox.shrink();

        // Hasta 4 tareas visibles en el panel
        final visible = tasks.take(4).toList();
        final hiddenCount = tasks.length - visible.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header de sección ──────────────────────────────────────────
            _TasksPanelHeader(totalCount: tasks.length),
            const SizedBox(height: 10),

            // ── Tarjetas de tarea ──────────────────────────────────────────
            ...visible.map((task) => _TaskCard(task: task)),

            // ── "Ver más" si hay más de 4 ──────────────────────────────────
            if (hiddenCount > 0) _MoreTasksBadge(count: hiddenCount),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TasksPanelHeader extends StatelessWidget {
  final int totalCount;
  const _TasksPanelHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cleaning_services_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tareas activas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        // Badge con conteo total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalCount activa${totalCount != 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de tarea ──────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final HotelTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInProgress = task.status == 'inProgress';
    final color = isInProgress ? const Color(0xFF2196F3) : Colors.orange.shade700;
    final statusIcon =
        isInProgress ? Icons.play_circle_outline : Icons.schedule_rounded;

    // Tiempo transcurrido formateado
    final elapsed = task.elapsedTime;
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes} min'
        : '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}min';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
          // ── Ícono de tipo ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _taskTypeIcon(task.taskType),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // ── Información ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Habitación + tipo
                Row(
                  children: [
                    Text(
                      'Hab. ${task.roomNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _TypeChip(label: task.taskTypeLabel, color: color),
                  ],
                ),
                const SizedBox(height: 2),
                // Huésped
                Text(
                  task.guestName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Estado + tiempo ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(statusIcon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(
                elapsedStr,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _taskTypeIcon(String type) => switch (type) {
        'cleaning' => Icons.cleaning_services_rounded,
        'maintenance' => Icons.build_outlined,
        'inspection' => Icons.search_rounded,
        'delivery' => Icons.local_shipping_outlined,
        'guest_request' => Icons.room_service_rounded,
        _ => Icons.task_outlined,
      };
}

// ── Chip de tipo ──────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(8),
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

// ── Más tareas ────────────────────────────────────────────────────────────────

class _MoreTasksBadge extends StatelessWidget {
  final int count;
  const _MoreTasksBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: Text(
          '+ $count tarea${count != 1 ? 's' : ''} más',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Banner de error ───────────────────────────────────────────────────────────

class _TasksErrorBanner extends StatelessWidget {
  final String message;
  const _TasksErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 18, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se pudo cargar tareas activas',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
