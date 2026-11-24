import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/router/app_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';
import 'package:hotel_app/presentation/providers/rooms/room_detail_provider.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_status_badge.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

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
      _ when state.errorMessage != null => Scaffold(
        appBar: AppBar(title: const Text('Detalle de habitación')),
        body: AppErrorState(
          message: state.errorMessage!,
          onRetry: () => ref.read(roomDetailProvider.notifier).retry(),
        ),
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
    final statusColors = AppStatusColors.of(context);
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
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.hotel_rounded,
                          size: 72,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: AppSpacing.screen,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Estado + tipo ──
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm + 2,
                runSpacing: AppSpacing.sm,
                children: [
                  RoomStatusBadge(status: room.status),
                  AppPill(
                    label: room.roomType.label,
                    color: AppColors.primary,
                    icon: Icons.bed_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Precio y capacidad ──
              Row(
                children: [
                  Expanded(
                    child: AppStatCard(
                      icon: Icons.payments_rounded,
                      label: 'Por noche',
                      value: '\$${room.pricePerNight.toStringAsFixed(0)}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppStatCard(
                      icon: Icons.people_rounded,
                      label: 'Capacidad',
                      value: '${room.capacity} pers.',
                      color: statusColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Descripción ──
              const AppSectionTitle(
                title: 'Descripción',
                icon: Icons.description_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Text(
                  room.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Amenities ──
              if (room.amenities.isNotEmpty) ...[
                const AppSectionTitle(
                  title: 'Servicios incluidos',
                  icon: Icons.room_service_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: room.amenities
                      .map(
                        (a) => AppPill(
                          label: a,
                          color: AppColors.primary,
                          icon: Icons.check_rounded,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Botón Ver Reservación Activa ──
              if (room.status == RoomStatus.occupied) ...[
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.reservations),
                    icon: const Icon(Icons.bookmark_rounded),
                    label: const Text('Ver reservación activa'),
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
