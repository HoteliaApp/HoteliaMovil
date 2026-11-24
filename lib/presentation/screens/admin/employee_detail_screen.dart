import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final User employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.employee.role == UserRole.unassigned
        ? null
        : widget.employee.role;
  }

  Future<void> _updateEmployee(UserStatus newStatus) async {
    if (newStatus == UserStatus.active && _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un rol para activar al usuario.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppDialogTitle(
          icon: Icons.manage_accounts_rounded,
          title: 'Confirmar acción',
        ),
        content: Text(
          'Usuario: ${widget.employee.name}\n'
          'Nuevo Rol: ${newStatus == UserStatus.active ? _selectedRole?.label : widget.employee.role.label}\n'
          'Nuevo Estado: ${newStatus.label}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final roleToSet =
          newStatus == UserStatus.active ? _selectedRole! : widget.employee.role;
      await ref.read(employeesProvider.notifier).updateEmployeeRoleAndStatus(
            widget.employee.id,
            roleToSet,
            newStatus,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Empleado actualizado correctamente.'),
            backgroundColor: AppStatusColors.of(context).success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(employeesProvider);
    final statusColors = AppStatusColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Empleado')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionTitle(
                        title: 'Información General',
                        icon: Icons.person_rounded,
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildInfoRow(context, 'Nombre', widget.employee.name),
                      _buildInfoRow(context, 'Correo', widget.employee.email),
                      _buildInfoRow(
                        context,
                        'Fecha Registro',
                        widget.employee.createdAt
                            .toLocal()
                            .toString()
                            .split('.')[0],
                      ),
                      _buildInfoRow(
                        context,
                        'Estado Actual',
                        widget.employee.status.label,
                      ),
                      _buildInfoRow(
                        context,
                        'Rol Actual',
                        widget.employee.role.label,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionTitle(
                        title: 'Asignar Rol',
                        icon: Icons.badge_rounded,
                      ),
                      const Divider(height: AppSpacing.xl),
                      DropdownButtonFormField<UserRole>(
                        initialValue: _selectedRole,
                        hint: const Text('Selecciona un rol'),
                        items: UserRole.values
                            .where((r) => r != UserRole.unassigned)
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (role) {
                          setState(() => _selectedRole = role);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    if (widget.employee.status != UserStatus.rejected)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: statusColors.danger,
                          side: BorderSide(color: statusColors.danger),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rechazar'),
                        onPressed: () => _updateEmployee(UserStatus.rejected),
                      ),
                    if (widget.employee.status == UserStatus.active)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: statusColors.neutral,
                          side: BorderSide(color: statusColors.neutral),
                        ),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('Desactivar'),
                        onPressed: () => _updateEmployee(UserStatus.inactive),
                      ),
                    if (widget.employee.status != UserStatus.active)
                      FilledButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aprobar / Activar'),
                        onPressed: () => _updateEmployee(UserStatus.active),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
