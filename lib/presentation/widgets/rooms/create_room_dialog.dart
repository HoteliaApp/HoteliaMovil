import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/subscription/change_plan_dialog.dart';
import 'package:hotel_app/presentation/widgets/subscription/room_limit_reached_dialog.dart';

/// Diálogo para registrar una nueva habitación en el hotel con validación de suscripción SaaS (H-29).
class CreateRoomDialog extends ConsumerStatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '75.0');
  final _capacityCtrl = TextEditingController(text: '2');
  final _descCtrl = TextEditingController();

  RoomType _selectedType = RoomType.single;
  final Set<String> _selectedAmenities = {'WiFi', 'TV'};
  bool _isSaving = false;

  static const List<String> availableAmenities = [
    'WiFi',
    'TV',
    'AC',
    'Minibar',
    'Jacuzzi',
    'Caja fuerte',
    'Balcón',
    'Terraza',
  ];

  @override
  void dispose() {
    _numberCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Validar contra el documento de suscripción del hotel antes de permitir altas
    final subscription = ref.read(hotelSubscriptionProvider);
    if (subscription.isRoomsLimitReached) {
      Navigator.of(context).pop();
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
      return;
    }

    setState(() => _isSaving = true);

    try {
      final roomNum = int.parse(_numberCtrl.text.trim());
      final hotelId = ref.read(currentHotelIdProvider);
      final roomId = 'room-$roomNum-$hotelId';

      final room = Room(
        id: roomId,
        roomNumber: roomNum,
        roomType: _selectedType,
        status: RoomStatus.available,
        pricePerNight: double.tryParse(_priceCtrl.text) ?? 75.0,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : 'Habitación ${_selectedType.label}',
        images: [RoomModel.defaultRoomImageUrl(roomNum)],
        capacity: int.tryParse(_capacityCtrl.text) ?? 2,
        amenities: _selectedAmenities.toList(),
        hotelId: hotelId,
      );

      await ref.read(roomsProvider.notifier).createRoom(room);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Habitación $roomNum registrada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear habitación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_home_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Registrar Habitación',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Número de habitación
                TextFormField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de habitación *',
                    hintText: 'Ej. 205',
                    prefixIcon: Icon(Icons.pin),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa el número de habitación';
                    }
                    if (int.tryParse(val.trim()) == null) {
                      return 'Ingresa un número entero válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Tipo de habitación
                DropdownButtonFormField<RoomType>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de habitación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.hotel),
                  ),
                  items: RoomType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (type) {
                    if (type != null) setState(() => _selectedType = type);
                  },
                ),
                const SizedBox(height: 14),

                // Precio y Capacidad
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Precio por noche',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Capacidad personas',
                          prefixIcon: Icon(Icons.people_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null) {
                            return 'Capacidad inválida';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Amenities
                const Text(
                  'Amenities:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: availableAmenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withAlpha(40),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar habitación'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
