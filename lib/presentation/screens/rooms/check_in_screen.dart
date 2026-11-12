import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:intl/intl.dart';

/// Pantalla de Check-in
///
/// Presenta un formulario para capturar el nombre del huésped,
/// número de acompañantes y fecha estimada de salida, antes de
/// confirmar el check-in de la reservación.
class CheckInScreen extends ConsumerStatefulWidget {
  final String reservationId;
  final String guestName;
  final String roomId;
  final String roomNumber;

  const CheckInScreen({
    super.key,
    required this.reservationId,
    required this.guestName,
    required this.roomId,
    required this.roomNumber,
  });

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _guestNameCtrl;
  final _companionsCtrl = TextEditingController(text: '0');
  DateTime? _expectedCheckOut;

  @override
  void initState() {
    super.initState();
    _guestNameCtrl = TextEditingController(text: widget.guestName);
    // Sugiere mañana como checkout por defecto
    _expectedCheckOut = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    _companionsCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _pickCheckOutDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedCheckOut ?? now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Fecha estimada de salida',
      confirmText: 'Seleccionar',
      cancelText: 'Cancelar',
    );
    if (picked != null) setState(() => _expectedCheckOut = picked);
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expectedCheckOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de salida estimada')),
      );
      return;
    }

    final notifier = ref.read(checkInOutProvider.notifier);
    final companions = int.tryParse(_companionsCtrl.text) ?? 0;
    
    await notifier.performCheckIn(
      widget.reservationId,
      widget.roomId,
      guestName: _guestNameCtrl.text.trim(),
      companions: companions,
      expectedCheckOut: _expectedCheckOut!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkInOutProvider);
    final notifier = ref.read(checkInOutProvider.notifier);
    final theme = Theme.of(context);

    // Listener para navegar al éxito
    ref.listen<CheckInOutState>(checkInOutProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green[700],
          ),
        );
        notifier.clearMessages();
        if (context.mounted) context.pop(true);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[700],
          ),
        );
        notifier.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ícono ──
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.login, size: 44, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Habitación No. ${widget.roomNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Nombre del huésped ──
              Text('Nombre del huésped',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _guestNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej. Juan Pérez',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el nombre del huésped';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Número de acompañantes ──
              Text('Número de acompañantes',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _companionsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Valor inválido';
                  return null;
                },
                // Si está vacío, defaultea a 0
                onChanged: (v) {
                  if (v.isEmpty) _companionsCtrl.text = '0';
                },
              ),
              const SizedBox(height: 18),

              // ── Fecha estimada de salida ──
              Text('Fecha estimada de salida',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickCheckOutDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _expectedCheckOut != null
                            ? _formatDate(_expectedCheckOut!)
                            : 'Seleccionar fecha',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _expectedCheckOut != null
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: AppColors.secondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Aviso ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Al confirmar, la habitación quedará marcada como ocupada y la reservación pasará a estado "En curso".',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Botón ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _confirm,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                      state.isLoading ? 'Procesando...' : 'Confirmar Check-in'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
