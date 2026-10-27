import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/widgets/reservations/reservations_card.dart';
import 'package:hotel_app/presentation/widgets/reservations/create_reservation_dialog.dart';

/// Pantalla del listado de reservaciones
class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservationsProvider);
    final notifier = ref.read(reservationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.loadReservations,
          ),
        ],
      ),
      floatingActionButton: (ref.watch(authProvider).role == UserRole.admin || 
                             ref.watch(authProvider).role == UserRole.receptionist)
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const CreateReservationDialog(),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ── Filtros de estado ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatusFilter(
                  label: 'Todas',
                  isSelected: state.selectedStatus == null,
                  onTap: () => notifier.filterByStatus(null),
                ),
                ...ReservationStatus.values.map((s) => _StatusFilter(
                      label: s.label,
                      isSelected: state.selectedStatus == s,
                      onTap: () => notifier.filterByStatus(
                          state.selectedStatus == s ? null : s),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Lista ──
          Expanded(child: _buildBody(context, state, notifier, ref)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReservationsState state,
      ReservationsNotifier notifier, WidgetRef ref) {
    if (state.isLoading && state.reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(state.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: notifier.loadReservations,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.secondary),
            SizedBox(height: 16),
            Text('No hay reservaciones\ncon los filtros seleccionados.',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: state.reservations.length,
        itemBuilder: (_, i) {
          final r = state.reservations[i];
          return ReservationCard(
            reservation: r,
            onCheckIn: r.status == ReservationStatus.confirmed
                ? () => context.pushNamed(
                      'checkIn',
                      pathParameters: {'roomId': r.roomId},
                      queryParameters: {
                        'reservationId': r.id,
                        'guestName': r.guestName,
                        'roomNumber': r.roomId,
                      },
                    )
                : null,
            onCheckOut: r.status == ReservationStatus.checkedIn
                ? () => context.pushNamed(
                      'checkOut',
                      pathParameters: {'roomId': r.roomId},
                      extra: {
                        'reservationId': r.id,
                        'guestName': r.guestName,
                        'roomNumber': r.roomId,
                        'nights': r.nights,
                        'total': r.total,
                      },
                    )
                : null,
            onCancel: r.status == ReservationStatus.confirmed
                ? () => _confirmCancel(context, r, notifier)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, Reservation r, ReservationsNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar reservación'),
        content: Text(
            '¿Estás seguro de cancelar la reservación de ${r.guestName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.cancelReservation(r.id);
    }
  }
}

class _StatusFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilter(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
