import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/audit_log.dart';
import 'package:hotel_app/presentation/providers/audit/audit_provider.dart';
import 'package:hotel_app/presentation/widgets/audit/audit_log_card.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:intl/intl.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final state = ref.read(auditNotifierProvider);
    final now = DateTime.now();
    final initialDateRange = state.selectedDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(auditNotifierProvider.notifier).setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final state = ref.watch(auditNotifierProvider);
    final notifier = ref.read(auditNotifierProvider.notifier);
    final filteredLogs = state.filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora de Auditoría'),
        actions: [
          IconButton(
            icon: Icon(
              state.selectedDateRange != null
                  ? Icons.event_available_rounded
                  : Icons.date_range_rounded,
            ),
            tooltip: 'Filtrar por rango de fechas',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => notifier.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Buscar por recepcionista, motivo, ref...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: AppIconSize.md - 2,
                ),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: AppIconSize.sm,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          if (state.selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: AppCard(
                accent: AppColors.primary,
                tinted: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: AppIconSize.xs,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Rango: ${DateFormat('dd/MM/yyyy').format(state.selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(state.selectedDateRange!.end)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => notifier.setDateRange(null),
                      borderRadius: AppRadius.mdAll,
                      child: const Icon(
                        Icons.close_rounded,
                        size: AppIconSize.sm - 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _FilterChipItem(
                  label: 'Todos (${state.logs.length})',
                  isSelected: state.selectedFilter == null,
                  onTap: () => notifier.setFilter(null),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipItem(
                  label: 'Cancelaciones',
                  icon: Icons.cancel_rounded,
                  color: statusColors.danger,
                  isSelected:
                      state.selectedFilter == AuditActionType.cancellation,
                  onTap: () => notifier.setFilter(AuditActionType.cancellation),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipItem(
                  label: 'Check-in',
                  icon: Icons.login_rounded,
                  color: statusColors.success,
                  isSelected: state.selectedFilter == AuditActionType.checkIn,
                  onTap: () => notifier.setFilter(AuditActionType.checkIn),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipItem(
                  label: 'Check-out',
                  icon: Icons.logout_rounded,
                  color: statusColors.info,
                  isSelected: state.selectedFilter == AuditActionType.checkOut,
                  onTap: () => notifier.setFilter(AuditActionType.checkOut),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipItem(
                  label: 'Cambio de Rol',
                  icon: Icons.manage_accounts_rounded,
                  color: statusColors.warning,
                  isSelected:
                      state.selectedFilter == AuditActionType.roleChange,
                  onTap: () => notifier.setFilter(AuditActionType.roleChange),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipItem(
                  label: 'Suscripción',
                  icon: Icons.card_membership_rounded,
                  color: statusColors.purple,
                  isSelected:
                      state.selectedFilter == AuditActionType.subscription,
                  onTap: () => notifier.setFilter(AuditActionType.subscription),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.logs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.errorMessage != null && state.logs.isEmpty) {
                  return AppErrorState(
                    message: state.errorMessage!,
                    onRetry: () => notifier.refresh(),
                  );
                }

                if (filteredLogs.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: state.hasActiveFilters
                        ? 'No hay eventos que coincidan con los filtros'
                        : 'No hay registros de auditoría aún',
                    message: state.hasActiveFilters
                        ? 'Prueba borrando los filtros activos o cambiando el término de búsqueda.'
                        : 'Las operaciones críticas como check-ins, cancelaciones y cambios de rol aparecerán aquí en tiempo real.',
                    action: state.hasActiveFilters
                        ? OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              notifier.clearFilters();
                            },
                            icon: const Icon(Icons.filter_alt_off_rounded),
                            label: const Text('Limpiar filtros'),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => notifier.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xxl,
                    ),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return AuditLogCard(
                        key: ValueKey(log.id),
                        log: log,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppColors.primary;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      label: Text(label),
      avatar: icon != null
          ? Icon(
              icon,
              size: AppIconSize.xs,
              color: isSelected ? Colors.white : effectiveColor,
            )
          : null,
      selectedColor: effectiveColor,
      checkmarkColor: Colors.white,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? effectiveColor
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      visualDensity: VisualDensity.compact,
    );
  }
}
