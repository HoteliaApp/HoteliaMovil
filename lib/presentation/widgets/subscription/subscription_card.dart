import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';

/// Tarjeta que visualiza la suscripción SaaS activa, uso de recursos y límites
/// para el administrador del hotel (H-29).
class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(hotelSubscriptionProvider);
    final theme = Theme.of(context);

    final planColor = switch (subscription.plan.toLowerCase()) {
      'basic' => Colors.blue.shade700,
      'premium' => Colors.amber.shade800,
      _ => AppColors.primary,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con Plan y Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: planColor.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.workspace_premium, color: planColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suscripción SaaS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Plan ${subscription.planLabel}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: planColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: planColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: planColor.withAlpha(80)),
                  ),
                  child: Text(
                    subscription.planLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: planColor,
                    ),
                  ),
                ),
              ],
            ),

            if (subscription.hasPendingPlanChange) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusInfoLight.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusInfoLight.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions, size: 18, color: AppColors.statusInfoLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solicitud en proceso para actualizar a Plan ${subscription.requestedPlanLabel}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 28),

            // Barra de Habitaciones
            _buildUsageProgress(
              title: 'Habitaciones contratadas',
              current: subscription.currentRooms,
              max: subscription.maxRooms,
              percentage: subscription.roomsUsagePercentage,
              isLimitReached: subscription.isRoomsLimitReached,
              icon: Icons.meeting_room_outlined,
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Barra de Usuarios
            _buildUsageProgress(
              title: 'Usuarios contratados',
              current: subscription.currentUsers,
              max: subscription.maxUsers,
              percentage: subscription.usersUsagePercentage,
              isLimitReached: subscription.isUsersLimitReached,
              icon: Icons.people_outline,
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Botón Solicitar cambio de plan
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ChangePlanDialog(),
                  );
                },
                icon: const Icon(Icons.upgrade, color: AppColors.primary),
                label: const Text(
                  'Solicitar cambio de plan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
  }) {
    final progressColor = isLimitReached
        ? AppColors.statusDangerLight
        : (percentage >= 0.8
            ? AppColors.statusWarningLight
            : AppColors.statusSuccessLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              '$current de $max (${(percentage * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        if (isLimitReached)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Has alcanzado el límite máximo permitido por tu suscripción.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.statusDangerLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
