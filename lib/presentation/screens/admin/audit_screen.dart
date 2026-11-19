import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/audit_log.dart';
import 'package:hotel_app/presentation/providers/audit/audit_provider.dart';
import 'package:hotel_app/presentation/widgets/audit/audit_log_card.dart';
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
    final state = ref.watch(auditNotifierProvider);
    final notifier = ref.read(auditNotifierProvider.notifier);
    final filteredLogs = state.filteredLogs;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Bitácora de Auditoría',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.selectedDateRange != null
                  ? Icons.date_range
                  : Icons.date_range_outlined,
              color: state.selectedDateRange != null
                  ? AppColors.primary
                  : null,
            ),
            tooltip: 'Filtrar por rango de fechas',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de Búsqueda ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => notifier.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Buscar por recepcionista, motivo, ref...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),

          // ── Indicador de Rango de Fechas Activo ───────────────────────────
          if (state.selectedDateRange != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rango: ${DateFormat('dd/MM/yyyy').format(state.selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(state.selectedDateRange!.end)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => notifier.setDateRange(null),
                      child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Chips de Filtrado por Acción ──────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChipItem(
                  label: 'Todos (${state.logs.length})',
                  isSelected: state.selectedFilter == null,
                  onTap: () => notifier.setFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Cancelaciones',
                  icon: Icons.cancel_outlined,
                  color: Colors.red[700]!,
                  isSelected: state.selectedFilter == AuditActionType.cancellation,
                  onTap: () => notifier.setFilter(AuditActionType.cancellation),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Check-in',
                  icon: Icons.login_rounded,
                  color: const Color(0xFF10B981),
                  isSelected: state.selectedFilter == AuditActionType.checkIn,
                  onTap: () => notifier.setFilter(AuditActionType.checkIn),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Check-out',
                  icon: Icons.logout_rounded,
                  color: const Color(0xFF2563EB),
                  isSelected: state.selectedFilter == AuditActionType.checkOut,
                  onTap: () => notifier.setFilter(AuditActionType.checkOut),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Cambio de Rol',
                  icon: Icons.manage_accounts_outlined,
                  color: const Color(0xFFF59E0B),
                  isSelected: state.selectedFilter == AuditActionType.roleChange,
                  onTap: () => notifier.setFilter(AuditActionType.roleChange),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Suscripción',
                  icon: Icons.card_membership_outlined,
                  color: const Color(0xFF8B5CF6),
                  isSelected: state.selectedFilter == AuditActionType.subscription,
                  onTap: () => notifier.setFilter(AuditActionType.subscription),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Lista de Auditoría ─────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.logs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.errorMessage != null && state.logs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => notifier.refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.hasActiveFilters
                                ? 'No hay eventos que coincidan con los filtros'
                                : 'No hay registros de auditoría aún',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.hasActiveFilters
                                ? 'Prueba borrando los filtros activos o cambiando el término de búsqueda.'
                                : 'Las operaciones críticas como check-ins, cancelaciones y cambios de rol aparecerán aquí en tiempo real.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (state.hasActiveFilters) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                notifier.clearFilters();
                              },
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Limpiar filtros'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => notifier.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
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
              size: 14,
              color: isSelected ? Colors.white : effectiveColor,
            )
          : null,
      selectedColor: effectiveColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? effectiveColor
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      visualDensity: VisualDensity.compact,
    );
  }
}
