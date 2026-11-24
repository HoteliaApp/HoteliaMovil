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
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:hotel_app/presentation/widgets/shared/offline_banner.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';
import 'package:hotel_app/presentation/widgets/subscription/room_limit_reached_dialog.dart';

/// Pantalla principal del módulo de habitaciones
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomsProvider);
    final notifier = ref.read(roomsProvider.notifier);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.role == UserRole.admin;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.loadRooms,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
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
          const OfflineBanner(),
          const SizedBox(height: AppSpacing.sm),
          RoomFilterBar(
            selectedStatus: state.selectedStatus,
            selectedType: state.selectedType,
            selectedCapacity: state.selectedCapacity,
            onStatusChanged: notifier.filterByStatus,
            onTypeChanged: notifier.filterByType,
            onCapacityChanged: notifier.filterByCapacity,
            onClearFilters: notifier.clearFilters,
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
                    '${state.rooms.length} habitaciones encontradas',
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
    RoomsState state,
    RoomsNotifier notifier,
  ) {
    if (state.isLoading && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.rooms.isEmpty) {
      return AppErrorState(
        icon: Icons.wifi_off_rounded,
        message: state.errorMessage!,
        onRetry: notifier.loadRooms,
      );
    }

    if (state.rooms.isEmpty) {
      return const AppEmptyState(
        icon: Icons.hotel_rounded,
        title: 'No hay habitaciones disponibles\ncon los filtros seleccionados.',
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: notifier.loadRooms,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
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
