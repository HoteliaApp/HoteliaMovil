import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';
import 'package:hotel_app/presentation/providers/tasks/tasks_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

class SendAlertDialog extends ConsumerStatefulWidget {
  const SendAlertDialog({super.key});

  @override
  ConsumerState<SendAlertDialog> createState() => _SendAlertDialogState();
}

class _SendAlertDialogState extends ConsumerState<SendAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _guestController = TextEditingController();

  String? _selectedRoomId;
  String _selectedTaskType = 'cleaning';
  bool _isSubmitting = false;

  final Map<String, String> _taskTypes = {
    'cleaning': 'Limpieza',
    'maintenance': 'Mantenimiento',
    'inspection': 'Inspección',
    'delivery': 'Entrega',
    'guest_request': 'Solicitud de huésped',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  Future<void> _submit(int roomNumber) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una habitación')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final taskRepo = ref.read(taskRepositoryProvider);

      await taskRepo.createManualAlert(
        roomId: _selectedRoomId!,
        roomNumber: roomNumber,
        taskType: _selectedTaskType,
        description: _descriptionController.text.trim(),
        guestName: _guestController.text.trim().isEmpty
            ? 'Recepción'
            : _guestController.text.trim(),
      );

      if (!mounted) return;
      final statusColors = AppStatusColors.of(context);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alerta enviada al wearable con éxito'),
          backgroundColor: statusColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final statusColors = AppStatusColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar alerta: $e'),
          backgroundColor: statusColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomsProvider);
    final rooms = roomsState.rooms;

    return AlertDialog(
      title: const AppDialogTitle(
        icon: Icons.watch_rounded,
        title: 'Enviar Alerta al Wearable',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedRoomId,
                decoration: const InputDecoration(
                  labelText: 'Habitación',
                  prefixIcon: Icon(Icons.meeting_room_rounded),
                ),
                hint: const Text('Seleccionar habitación'),
                items: rooms
                    .map(
                      (room) => DropdownMenuItem(
                        value: room.id,
                        child: Text(
                          'Hab. ${room.roomNumber} - ${room.roomType.label}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRoomId = val);
                },
                validator: (val) => val == null ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedTaskType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Tarea',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                items: _taskTypes.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTaskType = val);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _guestController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Huésped (Opcional)',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Instrucciones',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una descripción de la alerta';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_selectedRoomId != null) {
                    final selectedRoom =
                        rooms.firstWhere((r) => r.id == _selectedRoomId);
                    _submit(selectedRoom.roomNumber);
                  } else {
                    _formKey.currentState!.validate();
                  }
                },
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_isSubmitting ? 'Enviando...' : 'Enviar Alerta'),
        ),
      ],
    );
  }
}
