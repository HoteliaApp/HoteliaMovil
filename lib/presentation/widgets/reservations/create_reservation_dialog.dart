import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/reservations/reservations_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';

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
    final notifier = ref.read(reservationsProvider.notifier);
    // Escuchar cambios en reservaciones para reactividad ante nuevas cargas o filtros
    ref.watch(reservationsProvider);
    final roomsState = ref.watch(roomsProvider);

    final selectableRooms = roomsState.rooms
        .where((r) => r.status != RoomStatus.outOfOrder)
        .toList();
    final rooms = selectableRooms.isNotEmpty
        ? selectableRooms
        : roomsState.rooms;

    final selectedRoom =
        rooms.where((r) => r.id == _roomId).firstOrNull;

    // Validación de fechas y cálculo de noches
    final hasValidDateRange = _checkIn != null &&
        _checkOut != null &&
        _checkOut!.isAfter(_checkIn!);
    final isInvalidDateOrder = _checkIn != null &&
        _checkOut != null &&
        !_checkOut!.isAfter(_checkIn!);

    final nights = hasValidDateRange
        ? _checkOut!.difference(_checkIn!).inDays
        : 0;

    // Cálculo dinámico de costo (Escenario 2)
    final totalEstimated = (selectedRoom != null && nights > 0)
        ? nights * selectedRoom.pricePerNight
        : 0.0;

    // Validación reactiva de fechas empalmadas (Escenario 1)
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
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nueva Reservación',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre del Huésped',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
                onSaved: (val) => _guestName = val?.trim(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Habitación',
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                value: rooms.any((r) => r.id == _roomId) ? _roomId : null,
                items: rooms.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(
                    'Habitación ${r.roomNumber} - ${r.roomType.label} (\$${r.pricePerNight.toStringAsFixed(0)}/noche)',
                  ),
                )).toList(),
                validator: (val) => val == null || val.isEmpty
                    ? 'Selecciona una habitación'
                    : null,
                onChanged: (val) => setState(() => _roomId = val),
                onSaved: (val) => _roomId = val,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
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

              // Alerta de rango de fechas inválido
              if (isInvalidDateOrder)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: cs.error),
                      const SizedBox(width: 6),
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

              // ── Escenario 1: Advertencia de fechas empalmadas (Diseño adaptativo al tema) ──
              if (conflict != null)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.error.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          color: cs.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advertencia: Fechas empalmadas',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.error,
                              ),
                            ),
                            const SizedBox(height: 4),
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

              // ── Escenario 2: Cálculo dinámico de costo estimado ──
              if (selectedRoom != null && hasValidDateRange && !hasOverlap)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
                onSaved: (val) => _notes = val ?? '',
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasOverlap
                        ? (theme.brightness == Brightness.dark
                            ? const Color(0xFF383838)
                            : Colors.grey.shade400)
                        : cs.primary,
                    foregroundColor: hasOverlap
                        ? (theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.white)
                        : cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // Bloquea el guardado si hay empalme de fechas o fechas inválidas
                  onPressed: hasOverlap
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate() &&
                              hasValidDateRange) {
                            // Doble verificación de bloqueo
                            if (hasOverlap) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se puede guardar: las fechas seleccionadas se empalman con una reservación existente.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            _formKey.currentState!.save();
                            setState(() => _isLoading = true);

                            try {
                              final success = await notifier.createReservation(
                                CreateReservationParams(
                                  roomId: _roomId!,
                                  guestId:
                                      'guest-${DateTime.now().millisecondsSinceEpoch}',
                                  guestName: _guestName!,
                                  checkIn: _checkIn!,
                                  checkOut: _checkOut!,
                                  total: totalEstimated,
                                  notes: _notes,
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
                                      backgroundColor: Colors.red.shade700,
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
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          } else if (!hasValidDateRange) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selecciona fechas válidas de check-in y check-out'),
                              ),
                            );
                          }
                        },
                  child: Text(
                    hasOverlap
                        ? 'Guardado bloqueado (Fechas empalmadas)'
                        : 'Crear Reservación',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
