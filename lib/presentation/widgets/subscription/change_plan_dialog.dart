import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

/// Diálogo modal interactivo para solicitar una mejora o cambio de plan SaaS (H-29).
class ChangePlanDialog extends ConsumerStatefulWidget {
  const ChangePlanDialog({super.key});

  @override
  ConsumerState<ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends ConsumerState<ChangePlanDialog> {
  late String _selectedPlan;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentSubscription = ref.read(hotelSubscriptionProvider);
    _selectedPlan = switch (currentSubscription.plan.toLowerCase()) {
      'basic' => 'standard',
      'standard' => 'premium',
      _ => 'premium',
    };
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitChange() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(subscriptionActionProvider.notifier)
          .requestPlanChange(_selectedPlan, notes: _notesController.text.trim());

      if (!mounted) return;
      final statusColors = AppStatusColors.of(context);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Solicitud enviada! Tu petición de cambio a plan ${_planLabel(_selectedPlan)} está en proceso.',
          ),
          backgroundColor: statusColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final statusColors = AppStatusColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar cambio: $e'),
          backgroundColor: statusColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _planLabel(String key) => switch (key.toLowerCase()) {
        'basic' => 'Básico',
        'premium' => 'Premium',
        _ => 'Intermedio',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = ref.watch(hotelSubscriptionProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppDialogTitle(
                icon: Icons.rocket_launch_rounded,
                title: 'Solicitar Cambio de Plan',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Plan actual: ${subscription.planLabel} (${subscription.maxRooms} habitaciones máx.)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: AppSpacing.xl),

              RadioGroup<String>(
                groupValue: _selectedPlan,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPlan = val);
                },
                child: Column(
                  children: [
                    _buildPlanOption(
                      planKey: 'basic',
                      title: 'Plan Básico',
                      roomsInfo: 'Hasta 20 habitaciones · 5 usuarios',
                      priceInfo: 'Ideal para hoteles pequeños o posadas',
                      isSelected: _selectedPlan == 'basic',
                      theme: theme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPlanOption(
                      planKey: 'standard',
                      title: 'Plan Intermedio (Estándar)',
                      roomsInfo: 'Hasta 50 habitaciones · 15 usuarios',
                      priceInfo: 'Multi-piso, tareas para smartwatch y TV',
                      isSelected: _selectedPlan == 'standard',
                      theme: theme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPlanOption(
                      planKey: 'premium',
                      title: 'Plan Premium',
                      roomsInfo: 'Hasta 150 habitaciones · 50 usuarios',
                      priceInfo: 'Soporte prioritario e integraciones completas',
                      isSelected: _selectedPlan == 'premium',
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo o comentarios adicionales (opcional)',
                  hintText: 'Ej. Necesitamos dar de alta el piso 3 la próxima semana',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 4),

              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitChange,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: AppIconSize.sm,
                          ),
                    label: Text(
                      _isSubmitting ? 'Enviando...' : 'Confirmar solicitud',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption({
    required String planKey,
    required String title,
    required String roomsInfo,
    required String priceInfo,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return AppCard(
      accent: isSelected ? AppColors.primary : null,
      tinted: isSelected,
      onTap: () => setState(() => _selectedPlan = planKey),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Radio<String>(
            value: planKey,
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                Text(
                  roomsInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  priceInfo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
