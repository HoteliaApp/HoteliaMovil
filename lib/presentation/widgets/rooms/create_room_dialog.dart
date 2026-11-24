import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/models/rooms/room_model.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/subscription/subscription_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
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
      final statusColors = AppStatusColors.of(context);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Habitación $roomNum registrada con éxito!'),
          backgroundColor: statusColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final statusColors = AppStatusColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear habitación: $e'),
          backgroundColor: statusColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppDialogTitle(
                  icon: Icons.add_home_rounded,
                  title: 'Registrar Habitación',
                ),
                const Divider(height: AppSpacing.xl),

                TextFormField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de habitación *',
                    hintText: 'Ej. 205',
                    prefixIcon: Icon(Icons.pin_rounded),
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
                const SizedBox(height: AppSpacing.md + 2),

                DropdownButtonFormField<RoomType>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de habitación',
                    prefixIcon: Icon(Icons.hotel_rounded),
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
                const SizedBox(height: AppSpacing.md + 2),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio por noche',
                          prefixText: '\$ ',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Capacidad personas',
                          prefixIcon: Icon(Icons.people_rounded),
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
                const SizedBox(height: AppSpacing.md + 2),

                Text(
                  'Amenities:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm - 2),
                Wrap(
                  spacing: AppSpacing.sm - 2,
                  runSpacing: AppSpacing.xs,
                  children: availableAmenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity, style: theme.textTheme.labelMedium),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.18),
                      checkmarkColor: AppColors.primary,
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
                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
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
                          : const Icon(
                              Icons.check_rounded,
                              size: AppIconSize.sm,
                            ),
                      label:
                          Text(_isSaving ? 'Guardando...' : 'Guardar habitación'),
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
