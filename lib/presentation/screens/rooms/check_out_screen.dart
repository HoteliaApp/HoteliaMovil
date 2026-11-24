import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

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
    final statusColors = AppStatusColors.of(context);

    ref.listen<CheckInOutState>(checkInOutProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: statusColors.success,
          ),
        );
        notifier.clearMessages();
        if (context.mounted) context.pop(true);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: statusColors.danger,
          ),
        );
        notifier.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Check-out')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: AppIconBadge(
                icon: Icons.logout_rounded,
                color: AppColors.primary,
                size: 96,
                iconSize: 44,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            const AppSectionTitle(
              title: 'Resumen de estancia',
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: AppSpacing.md),

            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _SummaryRow(label: 'Huésped', value: guestName),
                  _SummaryRow(label: 'Habitación', value: 'No. $roomNumber'),
                  _SummaryRow(label: 'Noches', value: '$nights noches'),
                  const Divider(height: AppSpacing.xl),
                  _SummaryRow(
                    label: 'Total a cobrar',
                    value: '\$${total.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppInfoBanner(
              icon: Icons.warning_amber_rounded,
              color: statusColors.warning,
              message:
                  'Al confirmar, la habitación quedará disponible y la reservación se marcará como completada.',
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => notifier.performCheckOut(
                          reservationId,
                          roomId,
                          guestName,
                        ),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(
                  state.isLoading ? 'Procesando...' : 'Confirmar Check-out',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlight ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: highlight
                ? theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }
}
