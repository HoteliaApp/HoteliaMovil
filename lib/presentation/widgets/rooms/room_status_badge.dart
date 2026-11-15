import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';

/// Badge que muestra el estado de una habitación con color e icono armonizados al tema
class RoomStatusBadge extends StatelessWidget {
  final RoomStatus status;
  final bool compact;

  const RoomStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color _getColor(BuildContext context) {
    final statusColors = AppStatusColors.of(context);
    return switch (status) {
      RoomStatus.available => statusColors.success,
      RoomStatus.occupied => statusColors.danger,
      RoomStatus.reserved => statusColors.info,
      RoomStatus.pendingCleaning => statusColors.warning,
      RoomStatus.cleaning => statusColors.info,
      RoomStatus.cleaned => statusColors.success,
      RoomStatus.outOfOrder => statusColors.danger,
    };
  }

  IconData get _icon => switch (status) {
        RoomStatus.available => Icons.check_circle_outline,
        RoomStatus.occupied => Icons.person,
        RoomStatus.reserved => Icons.event_available,
        RoomStatus.pendingCleaning => Icons.cleaning_services_outlined,
        RoomStatus.cleaning => Icons.cleaning_services,
        RoomStatus.cleaned => Icons.verified_outlined,
        RoomStatus.outOfOrder => Icons.build_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
