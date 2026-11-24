import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/reservation.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

class CancelReservationDialog extends StatefulWidget {
  final Reservation reservation;

  const CancelReservationDialog({
    super.key,
    required this.reservation,
  });

  static Future<String?> show(
    BuildContext context, {
    required Reservation reservation,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelReservationDialog(reservation: reservation),
    );
  }

  @override
  State<CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<CancelReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_reasonController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final r = widget.reservation;

    return AlertDialog(
      title: AppDialogTitle(
        icon: Icons.cancel_rounded,
        title: 'Cancelar reservación',
        color: statusColors.danger,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta acción liberará la habitación y quedará registrada en la bitácora de auditoría del hotel.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: AppIconSize.sm - 2,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm - 2),
                        Expanded(
                          child: Text(
                            r.guestName,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room_rounded,
                          size: AppIconSize.sm - 2,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm - 2),
                        Text(
                          'Habitación ${r.roomNumber}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 4),
              Text(
                'Motivo de la cancelación *',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('cancel_reservation_reason_field'),
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej. Huésped canceló por problemas de vuelo...',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(color: statusColors.danger, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El motivo de cancelación es obligatorio';
                  }
                  if (val.trim().length < 5) {
                    return 'Ingresa un motivo descriptivo (mín. 5 caracteres)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Volver'),
        ),
        FilledButton.icon(
          key: const Key('confirm_cancel_reservation_button'),
          style: FilledButton.styleFrom(
            backgroundColor: statusColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded, size: AppIconSize.sm),
          label: const Text('Confirmar cancelación'),
        ),
      ],
    );
  }
}
