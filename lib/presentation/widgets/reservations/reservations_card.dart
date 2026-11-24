import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/widgets/reservations/reservation_status_chip.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

/// Tarjeta de reservación para la lista de reservaciones
class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final VoidCallback? onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCheckIn,
    this.onCheckOut,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.person_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.guestName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hab. ${reservation.roomNumber} · ${reservation.nights} noches',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ReservationStatusChip(status: reservation.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _DateInfo(
                label: 'Check-in',
                date: reservation.checkIn,
                icon: Icons.login_rounded,
              ),
              const SizedBox(width: AppSpacing.xl),
              _DateInfo(
                label: 'Check-out',
                date: reservation.checkOut,
                icon: Icons.logout_rounded,
              ),
            ],
          ),
          if (_showActions) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancel != null &&
                    reservation.status == ReservationStatus.confirmed)
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: statusColors.danger,
                    ),
                    child: const Text('Cancelar'),
                  ),
                if (onCheckIn != null &&
                    reservation.status == ReservationStatus.confirmed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(
                      Icons.login_rounded,
                      size: AppIconSize.xs + 2,
                    ),
                    label: const Text('Check-in'),
                  ),
                ],
                if (onCheckOut != null &&
                    reservation.status == ReservationStatus.checkedIn) ...[
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: onCheckOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: AppIconSize.xs + 2,
                    ),
                    label: const Text('Check-out'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool get _showActions =>
      onCheckIn != null || onCheckOut != null || onCancel != null;
}

class _DateInfo extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;

  const _DateInfo({
    required this.label,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.xs, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Text(
          '${date.day}/${date.month}/${date.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
