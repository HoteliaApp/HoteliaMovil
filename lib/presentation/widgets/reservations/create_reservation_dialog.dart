import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

class CreateReservationDialog extends ConsumerStatefulWidget {
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final String? initialRoomId;

  const CreateReservationDialog({
    super.key,
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialRoomId,
  });

  @override
  ConsumerState<CreateReservationDialog> createState() =>
      _CreateReservationDialogState();
}

class _CreateReservationDialogState
    extends ConsumerState<CreateReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _guestName;
  String? _roomId;
  DateTime? _checkIn;
  DateTime? _checkOut;
  String _notes = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.initialCheckIn;
    _checkOut = widget.initialCheckOut;
    _roomId = widget.initialRoomId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final notifier = ref.read(reservationsProvider.notifier);
    ref.watch(reservationsProvider);
    final roomsState = ref.watch(roomsProvider);

    final selectableRooms = roomsState.rooms
        .where((r) => r.status != RoomStatus.outOfOrder)
        .toList();
    final rooms =
        selectableRooms.isNotEmpty ? selectableRooms : roomsState.rooms;

    final selectedRoom = rooms.where((r) => r.id == _roomId).firstOrNull;

    final hasValidDateRange = _checkIn != null &&
        _checkOut != null &&
        _checkOut!.isAfter(_checkIn!);
    final isInvalidDateOrder = _checkIn != null &&
        _checkOut != null &&
        !_checkOut!.isAfter(_checkIn!);

    final nights =
        hasValidDateRange ? _checkOut!.difference(_checkIn!).inDays : 0;

    final totalEstimated = (selectedRoom != null && nights > 0)
        ? nights * selectedRoom.pricePerNight
        : 0.0;

    Reservation? overlappingReservation;
    if (_roomId != null && hasValidDateRange) {
      overlappingReservation = notifier.findOverlappingReservation(
        roomId: _roomId!,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
      );
    }
    final conflict = overlappingReservation;
    final hasOverlap = conflict != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: AppSpacing.lg + 4,
        left: AppSpacing.lg + 4,
        right: AppSpacing.lg + 4,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nueva Reservación',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg + 4),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre del Huésped',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
                onSaved: (val) => _guestName = val?.trim(),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Habitación',
                  prefixIcon: Icon(Icons.meeting_room_rounded),
                ),
                initialValue: rooms.any((r) => r.id == _roomId) ? _roomId : null,
                isExpanded: true,
                items: rooms
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          'Habitación ${r.roomNumber} - ${r.roomType.label} (\$${r.pricePerNight.toStringAsFixed(0)}/noche)',
                        ),
                      ),
                    )
                    .toList(),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Selecciona una habitación' : null,
                onChanged: (val) => setState(() => _roomId = val),
                onSaved: (val) => _roomId = val,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        size: AppIconSize.sm,
                      ),
                      label: Text(
                        _checkIn == null
                            ? 'Check-In'
                            : '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}',
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _checkIn ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: now.add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setState(() {
                            _checkIn = date;
                            if (_checkOut != null &&
                                !_checkOut!.isAfter(_checkIn!)) {
                              _checkOut = null;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.event_rounded,
                        size: AppIconSize.sm,
                      ),
                      label: Text(
                        _checkOut == null
                            ? 'Check-Out'
                            : '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}',
                      ),
                      onPressed: () async {
                        final baseDate = _checkIn ?? DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _checkOut != null &&
                                  _checkOut!.isAfter(baseDate)
                              ? _checkOut!
                              : baseDate.add(const Duration(days: 1)),
                          firstDate: baseDate,
                          lastDate: baseDate.add(const Duration(days: 730)),
                        );
                        if (date != null) {
                          setState(() => _checkOut = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (isInvalidDateOrder)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        size: AppIconSize.xs + 2,
                        color: cs.error,
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Expanded(
                        child: Text(
                          'La fecha de check-out debe ser posterior a la de check-in.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Advertencia de fechas empalmadas ──
              if (conflict != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md + 2),
                  child: AppCard(
                    accent: statusColors.danger,
                    tinted: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md + 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIconBadge(
                          icon: Icons.event_busy_rounded,
                          color: statusColors.danger,
                          size: 36,
                          iconSize: AppIconSize.sm,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advertencia: Fechas empalmadas',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: statusColors.danger,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'La habitación ya está reservada del ${conflict.checkIn.day}/${conflict.checkIn.month} al ${conflict.checkOut.day}/${conflict.checkOut.month}. Elige otras fechas u otra habitación.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Cálculo dinámico de costo estimado ──
              if (selectedRoom != null && hasValidDateRange && !hasOverlap)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md + 2),
                  child: AppCard(
                    accent: AppColors.primary,
                    tinted: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md + 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$nights ${nights == 1 ? "noche" : "noches"} x \$${selectedRoom.pricePerNight.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Cálculo estimado',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Total estimado: \$${totalEstimated.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note_rounded),
                ),
                onSaved: (val) => _notes = val ?? '',
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: hasOverlap
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate() &&
                                hasValidDateRange) {
                              if (hasOverlap) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'No se puede guardar: las fechas seleccionadas se empalman con una reservación existente.',
                                    ),
                                    backgroundColor: statusColors.danger,
                                  ),
                                );
                                return;
                              }

                              _formKey.currentState!.save();
                              setState(() => _isLoading = true);

                              try {
                                final success =
                                    await notifier.createReservation(
                                  CreateReservationParams(
                                    roomId: _roomId!,
                                    roomNumber: selectedRoom?.roomNumber ?? 0,
                                    guestId:
                                        'guest-${DateTime.now().millisecondsSinceEpoch}',
                                    guestName: _guestName!,
                                    checkIn: _checkIn!,
                                    checkOut: _checkOut!,
                                    total: totalEstimated,
                                    notes: _notes,
                                    hotelId: ref.read(currentHotelIdProvider),
                                  ),
                                );

                                if (success) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Reservación creada exitosamente',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                  if (context.mounted) {
                                    final errorMsg = ref
                                            .read(reservationsProvider)
                                            .errorMessage ??
                                        'Error al crear la reservación';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMsg),
                                        backgroundColor: statusColors.danger,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: statusColors.danger,
                                    ),
                                  );
                                }
                              }
                            } else if (!hasValidDateRange) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Selecciona fechas válidas de check-in y check-out',
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(
                      hasOverlap
                          ? 'Guardado bloqueado (Fechas empalmadas)'
                          : 'Crear Reservación',
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
