import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';

/// Chip de estado para reservaciones con colores y bordes consistentes (16px)
class ReservationStatusChip extends StatelessWidget {
  final ReservationStatus status;

  const ReservationStatusChip({super.key, required this.status});

  Color _getColor(BuildContext context) {
    final statusColors = AppStatusColors.of(context);
    return switch (status) {
      ReservationStatus.newReservation => statusColors.warning,
      ReservationStatus.confirmed => statusColors.info,
      ReservationStatus.checkedIn => statusColors.success,
      ReservationStatus.completed => statusColors.purple,
      ReservationStatus.cancelled => statusColors.neutral,
    };
  }

  IconData get _icon => switch (status) {
        ReservationStatus.newReservation => Icons.hourglass_empty_rounded,
        ReservationStatus.confirmed => Icons.check_circle_rounded,
        ReservationStatus.checkedIn => Icons.login_rounded,
        ReservationStatus.completed => Icons.logout_rounded,
        ReservationStatus.cancelled => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.badge),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: AppIconSize.xs, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
