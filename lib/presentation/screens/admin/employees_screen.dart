import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  UserStatus? _statusFilter;
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final employeesAsyncValue = ref.watch(employeesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Empleados'),
        actions: [
          PopupMenuButton<UserStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por estado',
            onSelected: (status) => setState(() => _statusFilter = status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos los estados')),
              ...UserStatus.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.label)),
              ),
            ],
          ),
          PopupMenuButton<UserRole?>(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Filtrar por rol',
            onSelected: (role) => setState(() => _roleFilter = role),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos los roles')),
              ...UserRole.values.map(
                (r) => PopupMenuItem(value: r, child: Text(r.label)),
              ),
            ],
          ),
        ],
      ),
      body: employeesAsyncValue.when(
        data: (employees) {
          final filtered = employees.where((e) {
            final matchesStatus = _statusFilter == null || e.status == _statusFilter;
            final matchesRole = _roleFilter == null || e.role == _roleFilter;
            return matchesStatus && matchesRole;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No hay empleados que coincidan con los filtros.'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final emp = filtered[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(context, emp.status),
                    child: Icon(_getRoleIcon(emp.role), color: Colors.white),
                  ),
                  title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${emp.email}\n${emp.role.label} - ${emp.status.label}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/admin/employees/${emp.id}', extra: emp);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, UserStatus status) {
    final statusColors = AppStatusColors.of(context);
    switch (status) {
      case UserStatus.pending:
        return statusColors.warning;
      case UserStatus.active:
        return statusColors.success;
      case UserStatus.rejected:
        return statusColors.danger;
      case UserStatus.inactive:
        return statusColors.neutral;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.manage_accounts;
      case UserRole.receptionist:
        return Icons.person;
      case UserRole.housekeeper:
        return Icons.cleaning_services;
      case UserRole.maintenance:
        return Icons.build;
      case UserRole.unassigned:
        return Icons.help_outline;
    }
  }
}
