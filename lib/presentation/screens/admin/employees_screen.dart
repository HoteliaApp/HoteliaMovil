import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Empleados'),
        actions: [
          PopupMenuButton<UserStatus?>(
            icon: const Icon(Icons.filter_list_rounded),
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
            icon: const Icon(Icons.badge_rounded),
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
            final matchesStatus =
                _statusFilter == null || e.status == _statusFilter;
            final matchesRole = _roleFilter == null || e.role == _roleFilter;
            return matchesStatus && matchesRole;
          }).toList();

          if (filtered.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No hay empleados que coincidan con los filtros.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final emp = filtered[index];
              final statusColor = _getStatusColor(context, emp.status);
              return AppCard(
                accent: statusColor,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs + 2,
                ),
                onTap: () {
                  context.push('/admin/employees/${emp.id}', extra: emp);
                },
                child: Row(
                  children: [
                    AppIconBadge(
                      icon: _getRoleIcon(emp.role),
                      color: statusColor,
                      size: 44,
                      iconSize: AppIconSize.md,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            emp.email,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          Wrap(
                            spacing: AppSpacing.sm - 2,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppPill(
                                label: emp.role.label,
                                color: AppColors.primary,
                                dense: true,
                              ),
                              AppPill(
                                label: emp.status.label,
                                color: statusColor,
                                dense: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorState(message: 'Error: $e'),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, UserStatus status) {
    final statusColors = AppStatusColors.of(context);
    return switch (status) {
      UserStatus.pending => statusColors.warning,
      UserStatus.active => statusColors.success,
      UserStatus.rejected => statusColors.danger,
      UserStatus.inactive => statusColors.neutral,
    };
  }

  IconData _getRoleIcon(UserRole role) {
    return switch (role) {
      UserRole.admin => Icons.manage_accounts_rounded,
      UserRole.receptionist => Icons.person_rounded,
      UserRole.housekeeper => Icons.cleaning_services_rounded,
      UserRole.maintenance => Icons.build_rounded,
      UserRole.unassigned => Icons.help_outline_rounded,
    };
  }
}
