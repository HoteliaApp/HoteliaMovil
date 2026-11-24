import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/reports/reports_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:intl/intl.dart';

/// Pantalla de Reportes de Productividad y Tiempos de Respuesta para Gerencia (H-28).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Future<void> _selectDateRange() async {
    final currentRange = ref.read(reportsProvider).selectedDateRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
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
      ref.read(reportsProvider.notifier).setDateRange(picked);
    }
  }

  int? _activePresetDays(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final diffDays = end.difference(start).inDays + 1;
    if (diffDays == 7 || diffDays == 14 || diffDays == 30) {
      return diffDays;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final activePreset = _activePresetDays(state.selectedDateRange);

    final rangeText =
        '${DateFormat('dd/MM/yyyy').format(state.selectedDateRange.start)} - '
        '${DateFormat('dd/MM/yyyy').format(state.selectedDateRange.end)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Productividad'),
        actions: [
          IconButton(
            key: const Key('reports_date_range_picker_button'),
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Filtrar por rango de fechas',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: notifier.refresh,
        child: state.isLoading &&
                state.completedTasks.isEmpty &&
                state.rooms.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null &&
                    state.completedTasks.isEmpty &&
                    state.rooms.isEmpty
                ? AppErrorState(
                    message: state.errorMessage!,
                    onRetry: notifier.refresh,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      // ── Indicador de Rango Activo ─────────────────────────
                      AppCard(
                        accent: AppColors.primary,
                        tinted: true,
                        onTap: _selectDateRange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md + 2,
                          vertical: AppSpacing.sm + 2,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: AppIconSize.sm - 2,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Text(
                                rangeText,
                                key: const Key(
                                  'reports_active_date_range_label',
                                ),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              'Cambiar',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),

                      // ── Chips Rápidos de Rango ────────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _PresetChip(
                              key: const Key('reports_preset_7d'),
                              label: 'Últimos 7 días',
                              selected: activePreset == 7,
                              onTap: () => notifier.setPresetDays(7),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PresetChip(
                              key: const Key('reports_preset_14d'),
                              label: 'Últimos 14 días',
                              selected: activePreset == 14,
                              onTap: () => notifier.setPresetDays(14),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PresetChip(
                              key: const Key('reports_preset_30d'),
                              label: 'Últimos 30 días',
                              selected: activePreset == 30,
                              onTap: () => notifier.setPresetDays(30),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Tarjetas de KPIs Resumen ──────────────────────────
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 520;
                          final kpis = [
                            _KpiCard(
                              key: const Key('kpi_avg_cleaning_time'),
                              title: 'Tiempo Medio Limpieza',
                              value:
                                  '${state.averageCleaningMinutes.toStringAsFixed(1)} min',
                              subtitle: 'Check-Out → Habitación Limpia',
                              icon: Icons.cleaning_services_rounded,
                              color: AppColors.primary,
                            ),
                            _KpiCard(
                              key: const Key('kpi_resolved_incidents'),
                              title: 'Incidencias Resueltas',
                              value: '${state.resolvedIncidentsCount}',
                              subtitle: 'Tareas completadas en rango',
                              icon: Icons.task_alt_rounded,
                              color: statusColors.success,
                            ),
                            _KpiCard(
                              key: const Key('kpi_avg_occupancy'),
                              title: 'Ocupación Promedio',
                              value:
                                  '${state.averageOccupancyPercentage.toStringAsFixed(1)}%',
                              subtitle: 'Tasa semanal de habitaciones',
                              icon: Icons.hotel_rounded,
                              color: statusColors.info,
                            ),
                          ];

                          if (isNarrow) {
                            return Column(
                              children: [
                                kpis[0],
                                const SizedBox(height: AppSpacing.sm + 2),
                                Row(
                                  children: [
                                    Expanded(child: kpis[1]),
                                    const SizedBox(width: AppSpacing.sm + 2),
                                    Expanded(child: kpis[2]),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: kpis[0]),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(child: kpis[1]),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(child: kpis[2]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Gráfica 1: Tiempo de Respuesta de Limpieza ────────
                      _ChartSectionCard(
                        key: const Key('cleaning_response_time_chart'),
                        title:
                            'Tiempo Medio entre Check-Out y Habitación Limpia',
                        subtitle:
                            'Minutos promedio por día (${state.filteredCleaningTasks.length} limpiezas)',
                        icon: Icons.timer_rounded,
                        accentColor: AppColors.primary,
                        child: _CleaningResponseLineChart(
                          series: state.cleaningResponseSeries,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Gráfica 2: Incidencias Resueltas por Categoría ────
                      _ChartSectionCard(
                        key: const Key('resolved_incidents_chart'),
                        title: 'Incidencias y Tareas Resueltas',
                        subtitle: 'Distribución por tipo de tarea completada',
                        icon: Icons.checklist_rounded,
                        accentColor: statusColors.success,
                        child: _IncidentsBarChart(
                          categories: state.incidentsByCategory,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Gráfica 3: Tasa de Ocupación Semanal ──────────────
                      _ChartSectionCard(
                        key: const Key('weekly_occupancy_chart'),
                        title: 'Tasa de Ocupación Semanal',
                        subtitle:
                            'Porcentaje diario de habitaciones ocupadas (últimos 7 días)',
                        icon: Icons.trending_up_rounded,
                        accentColor: statusColors.info,
                        child: _WeeklyOccupancyBarChart(
                          series: state.weeklyOccupancySeries,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ───────────────────────────── Widgets Internos ──────────────────────────────

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? Colors.white : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      accent: color,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: color, size: 40, iconSize: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _ChartSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: icon,
                color: accentColor,
                size: 36,
                iconSize: AppIconSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg + 2),
          SizedBox(height: 210, child: child),
        ],
      ),
    );
  }
}

class _CleaningResponseLineChart extends StatelessWidget {
  final List<DailyCleaningPoint> series;

  const _CleaningResponseLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _EmptyChartPlaceholder(
        icon: Icons.cleaning_services_rounded,
        message: 'Sin limpiezas completadas en este rango de fechas.',
      );
    }

    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: labelColor);
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    final maxMinutes = series.fold<double>(
      0.0,
      (prev, item) => math.max(prev, item.averageMinutes),
    );
    final maxY = math.max(10.0, (maxMinutes * 1.25).ceilToDouble());
    final intervalY = math.max(5.0, (maxY / 4).ceilToDouble());

    final spots = List.generate(
      series.length,
      (i) => FlSpot(
        i.toDouble(),
        double.parse(series[i].averageMinutes.toStringAsFixed(1)),
      ),
    );

    final double minX = 0;
    final double maxX =
        series.length == 1 ? 1.0 : (series.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.round().clamp(0, series.length - 1);
                final point = series[idx];
                final dateStr = DateFormat('dd/MM').format(point.date);
                return LineTooltipItem(
                  '$dateStr\n${point.averageMinutes.toStringAsFixed(1)} min (${point.completedCount})',
                  theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}m', style: labelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                final idx = value.toInt();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                final step = series.length > 7 ? (series.length / 5).ceil() : 1;
                if (idx % step != 0 && idx != series.length - 1) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    DateFormat('dd/MM').format(series[idx].date),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: series.length > 2,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentsBarChart extends StatelessWidget {
  final List<IncidentCategoryCount> categories;

  const _IncidentsBarChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, c) => sum + c.count);
    if (total == 0) {
      return const _EmptyChartPlaceholder(
        icon: Icons.task_alt_rounded,
        message: 'Sin incidencias resueltas en este rango de fechas.',
      );
    }

    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: labelColor);
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    final palette = [
      AppColors.primary,
      statusColors.warning,
      statusColors.info,
      statusColors.purple,
      statusColors.success,
    ];

    final maxCount = categories.fold<int>(
      0,
      (prev, item) => math.max(prev, item.count),
    );
    final maxY = math.max(4.0, (maxCount + 1).toDouble());
    final intervalY = math.max(1.0, (maxY / 4).ceilToDouble());

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}', style: labelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= categories.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(categories[idx].label, style: labelStyle),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(categories.length, (i) {
          final item = categories[i];
          final color = palette[i % palette.length];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: item.count.toDouble(),
                color: color,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sm),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _WeeklyOccupancyBarChart extends StatelessWidget {
  final List<DailyOccupancyPoint> series;

  const _WeeklyOccupancyBarChart({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((p) => p.totalRooms == 0)) {
      return const _EmptyChartPlaceholder(
        icon: Icons.hotel_rounded,
        message: 'Sin datos suficientes de habitaciones para calcular ocupación.',
      );
    }

    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: labelColor);
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = series[groupIndex];
              final dateStr = DateFormat('dd/MM').format(point.date);
              return BarTooltipItem(
                '$dateStr\n${point.occupancyPercentage.toStringAsFixed(0)}% (${point.occupiedRooms}/${point.totalRooms})',
                theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}%', style: labelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    DateFormat('dd/MM').format(series[idx].date),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(series.length, (i) {
          final point = series[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: double.parse(point.occupancyPercentage.toStringAsFixed(1)),
                color: statusColors.info,
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sm),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: statusColors.info.withValues(alpha: AppAlpha.tint),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyChartPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
