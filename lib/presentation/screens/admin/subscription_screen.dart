import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';
import 'package:hotel_app/presentation/widgets/subscription/subscription_card.dart';

/// Pantalla para que el administrador gestione y consulte los detalles de su
/// suscripción SaaS activa, límites y opciones de mejora (H-29).
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(hotelSubscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción y Facturación'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de estado de suscripción y uso
                const SubscriptionCard(),
                const SizedBox(height: 24),

                // Sección Comparativa de Planes
                Text(
                  'Planes SaaS Disponibles en Hotelia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildPlanDetailCard(
                  title: 'Plan Básico',
                  subtitle: 'Ideal para posadas y hoteles pequeños',
                  roomsLimit: 'Hasta 20 habitaciones',
                  usersLimit: 'Hasta 5 usuarios operativos',
                  features: const [
                    'Gestión de habitaciones y check-in/out',
                    'Módulo de reservaciones esenciales',
                    'Soporte estándar por correo',
                  ],
                  isCurrent: subscription.plan.toLowerCase() == 'basic',
                  theme: theme,
                ),
                const SizedBox(height: 12),

                _buildPlanDetailCard(
                  title: 'Plan Intermedio (Estándar)',
                  subtitle: 'Para hoteles en crecimiento con varios turnos',
                  roomsLimit: 'Hasta 50 habitaciones',
                  usersLimit: 'Hasta 15 usuarios operativos',
                  features: const [
                    'Todo lo del plan Básico',
                    'Integración completa con Smartwatch (Wear OS)',
                    'Tablero en Smart TV y sincronización reactiva',
                    'Soporte multi-piso y alertas operativas',
                  ],
                  isCurrent: subscription.plan.toLowerCase() == 'standard',
                  theme: theme,
                ),
                const SizedBox(height: 12),

                _buildPlanDetailCard(
                  title: 'Plan Premium',
                  subtitle: 'Para grandes complejos y cadenas hoteleras',
                  roomsLimit: 'Hasta 150 habitaciones',
                  usersLimit: 'Hasta 50 usuarios operativos',
                  features: const [
                    'Capacidad máxima y usuarios extendidos',
                    'Auditoría estricta y analítica avanzada',
                    'Soporte prioritario 24/7',
                    'Acceso a todas las integraciones de IoT',
                  ],
                  isCurrent: subscription.plan.toLowerCase() == 'premium',
                  theme: theme,
                ),
                const SizedBox(height: 24),

                // Botón para solicitar cambio
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ChangePlanDialog(),
                    );
                  },
                  icon: const Icon(Icons.upgrade),
                  label: const Text(
                    'Solicitar cambio de suscripción',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDetailCard({
    required String title,
    required String subtitle,
    required String roomsLimit,
    required String usersLimit,
    required List<String> features,
    required bool isCurrent,
    required ThemeData theme,
  }) {
    return Card(
      elevation: isCurrent ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? AppColors.primary : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? AppColors.primary : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  const Chip(
                    label: Text(
                      'PLAN ACTIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.meeting_room, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  roomsLimit,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  usersLimit,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final f in features) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
