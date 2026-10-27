import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/widgets/rooms/room_status_badge.dart';
import 'package:hotel_app/presentation/widgets/reservations/create_reservation_dialog.dart';

/// Tarjeta de habitación para la lista principal
class RoomCard extends ConsumerWidget {
  final Room room;
  final VoidCallback onTap;
  /// Si es `true`, muestra el precio por noche. Por defecto `false`
  /// (el precio solo se muestra en el resumen de check-out).
  final bool showPrice;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.showPrice = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final role = ref.watch(authProvider).role ?? UserRole.unassigned;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen o placeholder ──
            _RoomImage(images: room.images),

            // ── Contenido ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Habitación ${room.roomNumber}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      RoomStatusBadge(status: room.status, compact: true),
                      if (role == UserRole.admin || role == UserRole.receptionist || role == UserRole.housekeeper)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            final notifier = ref.read(roomsProvider.notifier);
                            if (value == 'outOfOrder') {
                              notifier.updateRoomStatus(room.id, RoomStatus.outOfOrder);
                            } else if (value == 'available') {
                              notifier.updateRoomStatus(room.id, RoomStatus.available);
                            } else if (value == 'reserve') {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const CreateReservationDialog(),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            if (room.status != RoomStatus.outOfOrder)
                              const PopupMenuItem<String>(
                                value: 'outOfOrder',
                                child: Text('Marcar Fuera de Servicio'),
                              ),
                            if (room.status == RoomStatus.outOfOrder || room.status == RoomStatus.cleaned)
                              const PopupMenuItem<String>(
                                value: 'available',
                                child: Text('Marcar Disponible'),
                              ),
                            if (room.isAvailable && (role == UserRole.admin || role == UserRole.receptionist))
                              const PopupMenuItem<String>(
                                value: 'reserve',
                                child: Text('Crear Reservación'),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.roomType.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── Capacidad ──
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 15, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            '${room.capacity} ${room.capacity == 1 ? 'persona' : 'personas'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      // ── Precio (solo si showPrice == true) ──
                      if (showPrice)
                        Text(
                          '\$${room.pricePerNight.toStringAsFixed(0)}/noche',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  final List<String> images;
  const _RoomImage({required this.images});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (images.isEmpty) {
      return Container(
        height: 150,
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.hotel, size: 48, color: cs.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Image.network(
        images.first,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.broken_image_outlined,
                size: 40, color: cs.onSurfaceVariant),
          ),
        ),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: cs.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
