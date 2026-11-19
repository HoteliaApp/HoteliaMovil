import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/reservation.dart';

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
    final r = widget.reservation;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cancelar reservación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.guestName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.meeting_room, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Habitación ${r.roomNumber}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Motivo de la cancelación *',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('cancel_reservation_reason_field'),
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej. Huésped canceló por problemas de vuelo...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
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
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Volver'),
            ),
            ElevatedButton.icon(
              key: const Key('confirm_cancel_reservation_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirmar cancelación'),
            ),
          ],
        ),
      ],
    );
  }
}
