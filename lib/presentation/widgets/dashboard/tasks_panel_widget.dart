import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

/// Panel de tareas activas para el Dashboard.
/// Muestra en tiempo real las tareas enviadas al wearable desde Firestore.
class TasksPanelWidget extends ConsumerWidget {
  const TasksPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(activeTasksProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: tasksAsync.when(
        loading: () => const SizedBox.shrink(key: ValueKey('tasks-loading')),
        error: (e, _) => _TasksErrorBanner(
          key: const ValueKey('tasks-error'),
          message: e.toString(),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const SizedBox.shrink(key: ValueKey('tasks-empty'));
          }

          final visible = tasks.take(4).toList();
          final hiddenCount = tasks.length - visible.length;
          final listKey = ValueKey<String>(
            visible.map((t) => '${t.id}:${t.status}').join('|'),
          );

          return Column(
            key: const ValueKey('tasks-panel'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionTitle(
                title: 'Tareas activas',
                icon: Icons.cleaning_services_rounded,
                subtitle: '${tasks.length} activa${tasks.length != 1 ? 's' : ''}',
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: listKey,
                  children: [
                    ...visible.map(
                      (task) => _TaskCard(
                        key: ValueKey<String>(task.id),
                        task: task,
                      ),
                    ),
                    if (hiddenCount > 0) _MoreTasksBadge(count: hiddenCount),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final HotelTask task;
  const _TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final isInProgress = task.status == 'inProgress';
    final color = isInProgress ? statusColors.info : statusColors.warning;
    final statusIcon =
        isInProgress ? Icons.play_circle_rounded : Icons.schedule_rounded;

    final elapsed = task.elapsedTime;
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes} min'
        : '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}min';

    return AppCard(
      accent: color,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {},
      child: Row(
        children: [
          AppIconBadge(icon: _taskTypeIcon(task.taskType), color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hab. ${task.roomNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    AppPill(
                      label: task.taskTypeLabel,
                      color: color,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(statusIcon, size: AppIconSize.sm - 2, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                elapsedStr,
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

  IconData _taskTypeIcon(String type) => switch (type) {
        'cleaning' => Icons.cleaning_services_rounded,
        'maintenance' => Icons.build_rounded,
        'inspection' => Icons.search_rounded,
        'delivery' => Icons.local_shipping_rounded,
        'guest_request' => Icons.room_service_rounded,
        _ => Icons.task_rounded,
      };
}

class _MoreTasksBadge extends StatelessWidget {
  final int count;
  const _MoreTasksBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Center(
        child: Text(
          '+ $count tarea${count != 1 ? 's' : ''} más',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _TasksErrorBanner extends StatelessWidget {
  final String message;
  const _TasksErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      icon: Icons.warning_amber_rounded,
      color: AppStatusColors.of(context).danger,
      message: 'No se pudo cargar tareas activas',
    );
  }
}
