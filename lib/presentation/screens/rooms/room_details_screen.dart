import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/router/app_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';
import 'package:hotel_app/presentation/providers/rooms/room_detail_provider.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_status_badge.dart';

/// Pantalla de detalle de una habitación
class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomDetailProvider.notifier).loadRoom(widget.roomId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomDetailProvider);

    return switch (true) {
      _ when state.isLoading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _ when state.errorMessage != null => _ErrorBody(
        message: state.errorMessage!,
        onRetry: () => ref
          .read(roomDetailProvider.notifier)
          .retry(),
      ),
      _ when state.room != null => Scaffold(
        body: _RoomDetailBody(room: state.room!),
      ),
      _ => const Scaffold(body: SizedBox.shrink()),
    };
  }
}

class _RoomDetailBody extends StatelessWidget {
  final Room room;

  const _RoomDetailBody({required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawImages = room.images.isNotEmpty
        ? room.images
        : [RoomModel.defaultRoomImageUrl(room.roomNumber)];
    final images = rawImages.map(RoomModel.formatImageUrl).toList();

    return CustomScrollView(
      slivers: [
        // ── AppBar con imagen ──
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Habitación ${room.roomNumber}',
              style: const TextStyle(
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
              ),
            ),
            background: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, child, progress) => Container(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    child: const Icon(
                      Icons.hotel,
                      size: 80,
                      color: AppColors.secondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Estado + tipo ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoomStatusBadge(status: room.status),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(room.roomType.label),
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Precio y capacidad ──
              Row(
                children: [
                  _InfoTile(
                    icon: Icons.attach_money,
                    label: 'Por noche',
                    value: '\$${room.pricePerNight.toStringAsFixed(0)}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _InfoTile(
                    icon: Icons.people_outline,
                    label: 'Capacidad',
                    value: '${room.capacity} pers.',
                    color: AppStatusColors.of(context).info,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Descripción ──
              Text(
                'Descripción',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(room.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Amenities ──
              if (room.amenities.isNotEmpty) ...[
                Text(
                  'Servicios incluidos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: room.amenities
                      .map(
                        (a) => Chip(
                          label: Text(a, style: const TextStyle(fontSize: 12)),
                          avatar: const Icon(Icons.check, size: 14),
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.15,
                          ),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // ── Botón Ver Reservación Activa ──
              if (room.status == RoomStatus.occupied) ...[
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.reservations),
                  icon: const Icon(Icons.bookmark_border_rounded),
                  label: const Text('Ver reservación activa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de habitación')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(message, textAlign: TextAlign.center),
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
