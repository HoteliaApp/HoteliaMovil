import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/rooms/check_in_out_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:intl/intl.dart';

/// Pantalla de Check-in
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
    final statusColors = AppStatusColors.of(context);

    ref.listen<CheckInOutState>(checkInOutProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: statusColors.success,
          ),
        );
        notifier.clearMessages();
        if (context.mounted) context.pop(true);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: statusColors.danger,
          ),
        );
        notifier.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: AppIconBadge(
                  icon: Icons.login_rounded,
                  color: AppColors.primary,
                  size: 88,
                  iconSize: 42,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'Habitación No. ${widget.roomNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Nombre del huésped ──
              Text(
                'Nombre del huésped',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              TextFormField(
                controller: _guestNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej. Juan Pérez',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el nombre del huésped';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Número de acompañantes ──
              Text(
                'Número de acompañantes',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              TextFormField(
                controller: _companionsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.group_rounded),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Valor inválido';
                  return null;
                },
                onChanged: (v) {
                  if (v.isEmpty) _companionsCtrl.text = '0';
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Fecha estimada de salida ──
              Text(
                'Fecha estimada de salida',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              AppCard(
                onTap: _pickCheckOutDate,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: AppIconSize.md,
                    ),
                    const SizedBox(width: AppSpacing.md),
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Aviso ──
              AppInfoBanner(
                icon: Icons.info_rounded,
                color: statusColors.info,
                message:
                    'Al confirmar, la habitación quedará marcada como ocupada y la reservación pasará a estado "En curso".',
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Botón ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: state.isLoading ? null : _confirm,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    state.isLoading ? 'Procesando...' : 'Confirmar Check-in',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
