import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/widgets/reservations/reservation_status_chip.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Fechas ──
            Row(
              children: [
                _DateInfo(
                  label: 'Check-in',
                  date: reservation.checkIn,
                  icon: Icons.login,
                ),
                const SizedBox(width: 24),
                _DateInfo(
                  label: 'Check-out',
                  date: reservation.checkOut,
                  icon: Icons.logout,
                ),
              ],
            ),

            // ── Acciones ──
            if (_showActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null &&
                      reservation.status == ReservationStatus.confirmed)
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red[700]),
                      child: const Text('Cancelar'),
                    ),
                  if (onCheckIn != null &&
                      reservation.status == ReservationStatus.confirmed) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onCheckIn,
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Check-in'),
                    ),
                  ],
                  if (onCheckOut != null &&
                      reservation.status == ReservationStatus.checkedIn) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onCheckOut,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Check-out'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
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
            Icon(icon, size: 13, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
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
