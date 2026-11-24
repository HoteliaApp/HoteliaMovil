import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
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
    final statusColors = AppStatusColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Suscripción y Facturación')),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SubscriptionCard(),
                const SizedBox(height: AppSpacing.xl),

                const AppSectionTitle(
                  title: 'Planes SaaS Disponibles en Hotelia',
                  icon: Icons.workspace_premium_rounded,
                ),
                const SizedBox(height: AppSpacing.md),

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
                  statusColors: statusColors,
                ),
                const SizedBox(height: AppSpacing.md),

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
                  statusColors: statusColors,
                ),
                const SizedBox(height: AppSpacing.md),

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
                  statusColors: statusColors,
                ),
                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ChangePlanDialog(),
                      );
                    },
                    icon: const Icon(Icons.upgrade_rounded),
                    label: const Text('Solicitar cambio de suscripción'),
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
    required AppStatusColors statusColors,
  }) {
    return AppCard(
      accent: isCurrent ? AppColors.primary : null,
      tinted: isCurrent,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? AppColors.primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                const AppPill(
                  label: 'PLAN ACTIVO',
                  color: AppColors.primary,
                  outlined: true,
                  dense: true,
                ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.meeting_room_rounded,
                    size: AppIconSize.sm - 2,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    roomsLimit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_rounded,
                    size: AppIconSize.sm - 2,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    usersLimit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: AppIconSize.xs,
                    color: statusColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(f, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
