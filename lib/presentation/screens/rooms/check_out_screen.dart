import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';

/// Pantalla de Check-out
class CheckOutScreen extends ConsumerWidget {
  final String reservationId;
  final String guestName;
  final String roomId;
  final int roomNumber;
  final int nights;
  final double total;

  const CheckOutScreen({
    super.key,
    required this.reservationId,
    required this.guestName,
    required this.roomId,
    required this.roomNumber,
    required this.nights,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkInOutProvider);
    final notifier = ref.read(checkInOutProvider.notifier);

    ref.listen<CheckInOutState>(checkInOutProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green[700],
          ),
        );
        notifier.clearMessages();
        if (context.mounted) context.pop(true);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[700],
          ),
        );
        notifier.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Check-out')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ícono ──
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),

            // ── Resumen de estancia ──
            Text('Resumen de estancia',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _SummaryRow(label: 'Huésped', value: guestName),
            _SummaryRow(label: 'Habitación', value: 'No. $roomNumber'),
            _SummaryRow(label: 'Noches', value: '$nights noches'),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Total a cobrar',
              value: '\$${total.toStringAsFixed(2)}',
              highlight: true,
            ),
            const SizedBox(height: 24),

            // ── Aviso ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Al confirmar, la habitación quedará disponible y la reservación se marcará como completada.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ── Botón ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => notifier.performCheckOut(reservationId, roomId, guestName),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.logout),
                label: Text(state.isLoading ? 'Procesando...' : 'Confirmar Check-out'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: highlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
