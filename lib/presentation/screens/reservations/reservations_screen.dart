import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/widgets/reservations/cancel_reservation_dialog.dart';
import 'package:hotel_app/presentation/widgets/reservations/create_reservation_dialog.dart';
import 'package:hotel_app/presentation/widgets/reservations/reservations_card.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:hotel_app/presentation/widgets/shared/offline_banner.dart';

/// Pantalla del listado de reservaciones
class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservationsProvider);
    final notifier = ref.read(reservationsProvider.notifier);
    final role = ref.watch(authProvider).role;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: notifier.loadReservations,
          ),
        ],
      ),
      floatingActionButton:
          (role == UserRole.admin || role == UserRole.receptionist)
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva reservación'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const CreateReservationDialog(),
                    );
                  },
                )
              : null,
      body: Column(
        children: [
          const OfflineBanner(),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _StatusFilter(
                  label: 'Todas',
                  isSelected: state.selectedStatus == null,
                  onTap: () => notifier.filterByStatus(null),
                ),
                ...ReservationStatus.values.map(
                  (s) => _StatusFilter(
                    label: s.label,
                    isSelected: state.selectedStatus == s,
                    onTap: () => notifier.filterByStatus(
                      state.selectedStatus == s ? null : s,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    '${state.reservations.length} reservaciones encontradas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody(context, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReservationsState state,
    ReservationsNotifier notifier,
  ) {
    if (state.isLoading && state.reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.reservations.isEmpty) {
      return AppErrorState(
        icon: Icons.wifi_off_rounded,
        message: state.errorMessage!,
        onRetry: notifier.loadReservations,
      );
    }

    if (state.reservations.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No hay reservaciones\ncon los filtros seleccionados.',
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: notifier.loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
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
                        'roomNumber': r.roomNumber.toString(),
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
                        'roomNumber': r.roomNumber,
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
    BuildContext context,
    Reservation r,
    ReservationsNotifier notifier,
  ) async {
    final reason = await CancelReservationDialog.show(context, reservation: r);
    if (reason != null && reason.trim().isNotEmpty) {
      await notifier.cancelReservation(r.id, reason: reason.trim());
    }
  }
}

class _StatusFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilter({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        checkmarkColor: AppColors.primary,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
