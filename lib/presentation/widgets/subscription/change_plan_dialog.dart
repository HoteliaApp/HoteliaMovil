import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';

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
    // Si ya está en básico, sugerir intermedio; si en intermedio, sugerir premium
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
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Solicitud enviada! Tu petición de cambio a plan ${_planLabel(_selectedPlan)} está en proceso.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar cambio: $e'),
          backgroundColor: Colors.red,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rocket_launch, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Solicitar Cambio de Plan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Plan actual: ${subscription.planLabel} (${subscription.maxRooms} habitaciones máx.)',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 24),

              // Opciones de planes
              _buildPlanOption(
                planKey: 'basic',
                title: 'Plan Básico',
                roomsInfo: 'Hasta 20 habitaciones · 5 usuarios',
                priceInfo: 'Ideal para hoteles pequeños o posadas',
                isSelected: _selectedPlan == 'basic',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildPlanOption(
                planKey: 'standard',
                title: 'Plan Intermedio (Estándar)',
                roomsInfo: 'Hasta 50 habitaciones · 15 usuarios',
                priceInfo: 'Multi-piso, tareas para smartwatch y TV',
                isSelected: _selectedPlan == 'standard',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildPlanOption(
                planKey: 'premium',
                title: 'Plan Premium',
                roomsInfo: 'Hasta 150 habitaciones · 50 usuarios',
                priceInfo: 'Soporte prioritario e integraciones completas',
                isSelected: _selectedPlan == 'premium',
                theme: theme,
              ),
              const SizedBox(height: 16),

              // Notas opcionales
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo o comentarios adicionales (opcional)',
                  hintText: 'Ej. Necesitamos dar de alta el piso 3 la próxima semana',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Botones de acción
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                        : const Icon(Icons.send, size: 18),
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
    return InkWell(
      onTap: () => setState(() => _selectedPlan = planKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: planKey,
              groupValue: _selectedPlan,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPlan = val);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    roomsInfo,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  Text(
                    priceInfo,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
