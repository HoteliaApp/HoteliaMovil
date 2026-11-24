import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

/// Diálogo modal que se muestra cuando un hotel intenta registrar habitaciones
/// por encima del límite permitido por su suscripción SaaS activa (H-29, Escenario 1 Gherkin).
class RoomLimitReachedDialog extends StatelessWidget {
  final int currentRooms;
  final int maxRooms;
  final String currentPlan;
  final VoidCallback onUpgrade;

  const RoomLimitReachedDialog({
    super.key,
    required this.currentRooms,
    required this.maxRooms,
    required this.currentPlan,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);

    return AlertDialog(
      title: AppDialogTitle(
        icon: Icons.warning_amber_rounded,
        title: 'Límite de habitaciones alcanzado',
        color: statusColors.warning,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu hotel cuenta con una suscripción $currentPlan que permite un máximo de $maxRooms habitaciones.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Habitaciones registradas:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$currentRooms de $maxRooms',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Text(
            'Para registrar la habitación número ${currentRooms + 1} o superiores, solicita una mejora de suscripción a un plan con mayor capacidad.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade();
          },
          icon: const Icon(Icons.arrow_upward_rounded, size: AppIconSize.sm),
          label: const Text('Mejorar suscripción'),
        ),
      ],
    );
  }
}
