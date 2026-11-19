import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/rooms/create_room_dialog.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_card.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_filter_bar.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';
import 'package:hotel_app/presentation/widgets/subscription/room_limit_reached_dialog.dart';
import 'package:hotel_app/presentation/widgets/shared/offline_banner.dart';

/// Pantalla principal del módulo de habitaciones
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomsProvider);
    final notifier = ref.read(roomsProvider.notifier);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.loadRooms,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva habitación'),
              onPressed: () {
                final subscription = ref.read(hotelSubscriptionProvider);
                if (subscription.isRoomsLimitReached) {
                  showDialog(
                    context: context,
                    builder: (_) => RoomLimitReachedDialog(
                      currentRooms: subscription.currentRooms,
                      maxRooms: subscription.maxRooms,
                      currentPlan: subscription.planLabel,
                      onUpgrade: () => showDialog(
                        context: context,
                        builder: (_) => const ChangePlanDialog(),
                      ),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => const CreateRoomDialog(),
                  );
                }
              },
            )
          : null,
      body: Column(
        children: [
          // ── Banner indicador de Modo Fuera de Línea (H-31) ──
          const OfflineBanner(),

          const SizedBox(height: 8),
          // ── Barra de filtros ──
          RoomFilterBar(
            selectedStatus: state.selectedStatus,
            selectedType: state.selectedType,
            selectedCapacity: state.selectedCapacity,
            onStatusChanged: notifier.filterByStatus,
            onTypeChanged: notifier.filterByType,
            onCapacityChanged: notifier.filterByCapacity,
            onClearFilters: notifier.clearFilters,
          ),
          const SizedBox(height: 8),

          // ── Contador de resultados ──
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${state.rooms.length} habitaciones encontradas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),

          // ── Lista ──
          Expanded(child: _buildBody(context, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoomsState state, RoomsNotifier notifier) {
    if (state.isLoading && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.rooms.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: notifier.loadRooms,
      );
    }

    if (state.rooms.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: notifier.loadRooms,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: state.rooms.length,
        itemBuilder: (_, i) => RoomCard(
          room: state.rooms[i],
          showPrice: false,
          onTap: () => context.pushNamed(
            'roomDetail',
            pathParameters: {'roomId': state.rooms[i].id},
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hotel, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            'No hay habitaciones disponibles\ncon los filtros seleccionados.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


