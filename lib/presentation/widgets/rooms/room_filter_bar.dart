import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';

/// Barra de filtros para la pantalla de habitaciones
class RoomFilterBar extends StatefulWidget {
  final RoomStatus? selectedStatus;
  final RoomType? selectedType;
  final int? selectedCapacity;
  final ValueChanged<RoomStatus?> onStatusChanged;
  final ValueChanged<RoomType?> onTypeChanged;
  final ValueChanged<int?> onCapacityChanged;
  final VoidCallback onClearFilters;

  const RoomFilterBar({
    super.key,
    this.selectedStatus,
    this.selectedType,
    this.selectedCapacity,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onCapacityChanged,
    required this.onClearFilters,
  });

  @override
  State<RoomFilterBar> createState() => _RoomFilterBarState();
}

class _RoomFilterBarState extends State<RoomFilterBar> {
  late final TextEditingController _capacityCtrl;

  @override
  void initState() {
    super.initState();
    _capacityCtrl = TextEditingController(
      text: widget.selectedCapacity?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(RoomFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCapacity == null && _capacityCtrl.text.isNotEmpty) {
      _capacityCtrl.clear();
    }
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      widget.selectedStatus != null ||
      widget.selectedType != null ||
      widget.selectedCapacity != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _FilterChip(
                label: 'Todos',
                isSelected: widget.selectedStatus == null,
                onTap: () => widget.onStatusChanged(null),
              ),
              ...RoomStatus.values.map(
                (s) => _FilterChip(
                  label: s.label,
                  isSelected: widget.selectedStatus == s,
                  onTap: () => widget.onStatusChanged(
                    widget.selectedStatus == s ? null : s,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RoomType.values
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: _FilterChip(
                              label: t.label,
                              isSelected: widget.selectedType == t,
                              onTap: () => widget.onTypeChanged(
                                widget.selectedType == t ? null : t,
                              ),
                              outlined: true,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _capacityCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 10,
                    ),
                    labelText: 'Personas',
                    labelStyle: theme.textTheme.labelSmall,
                    prefixIcon: const Icon(
                      Icons.people_rounded,
                      size: AppIconSize.xs + 2,
                    ),
                    suffixIcon: widget.selectedCapacity != null
                        ? GestureDetector(
                            onTap: () {
                              _capacityCtrl.clear();
                              widget.onCapacityChanged(null);
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: AppIconSize.xs,
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: (v) {
                    final n = int.tryParse(v);
                    widget.onCapacityChanged(n == 0 ? null : n);
                  },
                  onChanged: (v) {
                    if (v.isEmpty) widget.onCapacityChanged(null);
                  },
                ),
              ),
              if (_hasFilters)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: ActionChip(
                    label: const Text('Limpiar'),
                    avatar: const Icon(
                      Icons.close_rounded,
                      size: AppIconSize.xs + 2,
                    ),
                    onPressed: () {
                      _capacityCtrl.clear();
                      widget.onClearFilters();
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool outlined;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        checkmarkColor: AppColors.primary,
        side: outlined
            ? BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
              )
            : null,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
