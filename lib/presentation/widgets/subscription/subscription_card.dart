import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';

/// Tarjeta que visualiza la suscripción SaaS activa, uso de recursos y límites
/// para el administrador del hotel (H-29).
class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(hotelSubscriptionProvider);
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);

    final planColor = switch (subscription.plan.toLowerCase()) {
      'basic' => statusColors.info,
      'premium' => statusColors.warning,
      _ => AppColors.primary,
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AppIconBadge(
                    icon: Icons.workspace_premium_rounded,
                    color: planColor,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suscripción SaaS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Plan ${subscription.planLabel}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: planColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppPill(
                label: subscription.planLabel.toUpperCase(),
                color: planColor,
                outlined: true,
                dense: true,
              ),
            ],
          ),

          if (subscription.hasPendingPlanChange) ...[
            const SizedBox(height: AppSpacing.md),
            AppInfoBanner(
              icon: Icons.pending_actions_rounded,
              color: statusColors.info,
              message:
                  'Solicitud en proceso para actualizar a Plan ${subscription.requestedPlanLabel}',
            ),
          ],

          const Divider(height: AppSpacing.xl + 4),

          _buildUsageProgress(
            title: 'Habitaciones contratadas',
            current: subscription.currentRooms,
            max: subscription.maxRooms,
            percentage: subscription.roomsUsagePercentage,
            isLimitReached: subscription.isRoomsLimitReached,
            icon: Icons.meeting_room_rounded,
            theme: theme,
            statusColors: statusColors,
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildUsageProgress(
            title: 'Usuarios contratados',
            current: subscription.currentUsers,
            max: subscription.maxUsers,
            percentage: subscription.usersUsagePercentage,
            isLimitReached: subscription.isUsersLimitReached,
            icon: Icons.people_rounded,
            theme: theme,
            statusColors: statusColors,
          ),

          const SizedBox(height: AppSpacing.lg + 4),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ChangePlanDialog(),
                );
              },
              icon: const Icon(Icons.upgrade_rounded),
              label: const Text('Solicitar cambio de plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageProgress({
    required String title,
    required int current,
    required int max,
    required double percentage,
    required bool isLimitReached,
    required IconData icon,
    required ThemeData theme,
    required AppStatusColors statusColors,
  }) {
    final progressColor = isLimitReached
        ? statusColors.danger
        : (percentage >= 0.8 ? statusColors.warning : statusColors.success);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: AppIconSize.sm - 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$current de $max (${(percentage * 100).toInt()}%)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        ClipRRect(
          borderRadius: AppRadius.smAll,
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        if (isLimitReached)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Has alcanzado el límite máximo permitido por tu suscripción.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
