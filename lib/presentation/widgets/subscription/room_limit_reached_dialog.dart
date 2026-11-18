import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';

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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusWarningLight.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.statusWarningLight,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Límite de habitaciones alcanzado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu hotel cuenta con una suscripción $currentPlan que permite un máximo de $maxRooms habitaciones.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Habitaciones registradas:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$currentRooms de $maxRooms',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusDangerLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Para registrar la habitación número ${currentRooms + 1} o superiores, solicita una mejora de suscripción a un plan con mayor capacidad.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade();
          },
          icon: const Icon(Icons.arrow_upward, size: 18),
          label: const Text('Mejorar suscripción'),
        ),
      ],
    );
  }
}
