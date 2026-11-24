import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/router/app_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/onboarding/hotel_onboarding_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

/// Pantalla del Asistente Guiado de Onboarding (H-25).
class HotelOnboardingWizardScreen extends ConsumerStatefulWidget {
  const HotelOnboardingWizardScreen({super.key});

  @override
  ConsumerState<HotelOnboardingWizardScreen> createState() =>
      _HotelOnboardingWizardScreenState();
}

class _HotelOnboardingWizardScreenState
    extends ConsumerState<HotelOnboardingWizardScreen> {
  final _hotelNameCtrl = TextEditingController();
  final _hotelAddressCtrl = TextEditingController();
  final _hotelIdCtrl = TextEditingController();

  final _staffNameCtrl = TextEditingController();
  final _staffEmailCtrl = TextEditingController();
  UserRole _selectedStaffRole = UserRole.receptionist;

  static const List<String> availableAmenities = [
    'WiFi',
    'TV',
    'AC',
    'Minibar',
    'Jacuzzi',
    'Caja fuerte',
    'Balcón',
    'Terraza',
    'Cafetera',
    'Vista panorámica',
  ];

  @override
  void dispose() {
    _hotelNameCtrl.dispose();
    _hotelAddressCtrl.dispose();
    _hotelIdCtrl.dispose();
    _staffNameCtrl.dispose();
    _staffEmailCtrl.dispose();
    super.dispose();
  }

  void _addStaffMember() {
    final name = _staffNameCtrl.text.trim();
    final email = _staffEmailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ingresa un nombre y correo válido para el empleado.',
          ),
          backgroundColor: AppStatusColors.of(context).danger,
        ),
      );
      return;
    }
    ref.read(hotelOnboardingProvider.notifier).addStaff(
          InitialStaffUser(
            name: name,
            email: email,
            role: _selectedStaffRole,
          ),
        );
    _staffNameCtrl.clear();
    _staffEmailCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelOnboardingProvider);
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);

    if (_hotelNameCtrl.text != state.hotelName) {
      _hotelNameCtrl.text = state.hotelName;
    }
    if (_hotelAddressCtrl.text != state.hotelAddress) {
      _hotelAddressCtrl.text = state.hotelAddress;
    }
    if (!state.isCustomHotelId && _hotelIdCtrl.text != state.hotelId) {
      _hotelIdCtrl.text = state.hotelId;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Onboarding SaaS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (state.currentStep > 0) {
              ref.read(hotelOnboardingProvider.notifier).previousStep();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(state.currentStep, theme, statusColors),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: AppInfoBanner(
                  icon: Icons.error_outline_rounded,
                  color: statusColors.danger,
                  message: state.errorMessage!,
                  action: TextButton(
                    onPressed: () => ref
                        .read(hotelOnboardingProvider.notifier)
                        .validateCurrentStep(),
                    child: const Text('OK'),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screen,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: switch (state.currentStep) {
                      0 => _buildStep1HotelInfo(state, theme),
                      1 => _buildStep2FloorsAndRooms(state, theme),
                      2 => _buildStep3InitialStaff(state, theme, statusColors),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
            _buildBottomActionButtons(state, theme, statusColors),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Indicador de Pasos ─────────────────────────────

  Widget _buildStepIndicator(
    int currentStep,
    ThemeData theme,
    AppStatusColors statusColors,
  ) {
    const steps = [
      '1. Datos del Hotel',
      '2. Pisos y Habitaciones',
      '3. Usuarios Iniciales',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md + 2,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(steps.length, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              final color = isCompleted
                  ? statusColors.success
                  : (isCurrent
                      ? AppColors.primary
                      : theme.colorScheme.outline);

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => ref
                            .read(hotelOnboardingProvider.notifier)
                            .goToStep(index),
                        borderRadius: AppRadius.mdAll,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                            horizontal: AppSpacing.xxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: color,
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: AppSpacing.xs + 2),
                                Flexible(
                                  child: Text(
                                    steps[index],
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? AppColors.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 16,
                        height: 2,
                        color: isCompleted
                            ? statusColors.success
                            : theme.colorScheme.outlineVariant,
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ─────────────────────────── Paso 1: Datos del Hotel ─────────────────────────

  Widget _buildStep1HotelInfo(HotelOnboardingState state, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.hotel_rounded,
                color: AppColors.primary,
                size: 44,
                iconSize: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Paso 1: Datos Generales del Hotel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ingresa la información comercial y selecciona tu plan de suscripción SaaS.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: AppSpacing.xxl),

          TextFormField(
            controller: _hotelNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre comercial del hotel *',
              hintText: 'Ej. Gran Hotel Central',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            onChanged: (val) =>
                ref.read(hotelOnboardingProvider.notifier).setHotelName(val),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextFormField(
            controller: _hotelIdCtrl,
            decoration: InputDecoration(
              labelText: 'Identificador único del Inquilino (hotelId) *',
              hintText: 'hotel_nombre_unico',
              prefixIcon: const Icon(Icons.tag_rounded),
              helperText:
                  'Identificador del tenant para aislamiento estricto en Firestore.',
              suffixIcon: state.isCustomHotelId
                  ? IconButton(
                      icon: const Icon(Icons.restore_rounded),
                      tooltip: 'Restablecer autogenerado',
                      onPressed: () {
                        ref
                            .read(hotelOnboardingProvider.notifier)
                            .setHotelName(_hotelNameCtrl.text);
                      },
                    )
                  : null,
            ),
            onChanged: (val) =>
                ref.read(hotelOnboardingProvider.notifier).setCustomHotelId(val),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextFormField(
            controller: _hotelAddressCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección física *',
              hintText: 'Av. Las Palmas 123, Cancún, México',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
            onChanged: (val) =>
                ref.read(hotelOnboardingProvider.notifier).setHotelAddress(val),
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número de pisos a administrar:',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Define la estructura vertical de tu establecimiento.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: state.floorsCount > 1
                          ? () => ref
                              .read(hotelOnboardingProvider.notifier)
                              .setFloorsCount(state.floorsCount - 1)
                          : null,
                    ),
                    Text(
                      '${state.floorsCount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: state.floorsCount < 50
                          ? () => ref
                              .read(hotelOnboardingProvider.notifier)
                              .setFloorsCount(state.floorsCount + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Selecciona tu Plan SaaS:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 460) {
                return Column(
                  children: [
                    _buildPlanCard(
                      'basic',
                      'Básico',
                      '1-2 pisos · Gestión esencial',
                      state.plan,
                      theme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPlanCard(
                      'standard',
                      'Estándar',
                      'Multi-piso · Relojes y tareas',
                      state.plan,
                      theme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildPlanCard(
                      'premium',
                      'Premium',
                      'Completo · Smart TV + Wearable',
                      state.plan,
                      theme,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      'basic',
                      'Básico',
                      '1-2 pisos\nGestión esencial',
                      state.plan,
                      theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildPlanCard(
                      'standard',
                      'Estándar',
                      'Multi-piso\nRelojes y tareas',
                      state.plan,
                      theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildPlanCard(
                      'premium',
                      'Premium',
                      'Completo\nSmart TV + Wearable',
                      state.plan,
                      theme,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String planKey,
    String title,
    String description,
    String selectedPlan,
    ThemeData theme,
  ) {
    final isSelected = planKey == selectedPlan;
    return AppCard(
      accent: isSelected ? AppColors.primary : null,
      tinted: isSelected,
      onTap: () => ref.read(hotelOnboardingProvider.notifier).setPlan(planKey),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.onSurfaceVariant,
            size: AppIconSize.md,
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Paso 2: Pisos y Habitaciones ───────────────────

  Widget _buildStep2FloorsAndRooms(
    HotelOnboardingState state,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.meeting_room_rounded,
                color: AppColors.primary,
                size: 44,
                iconSize: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso 2: Pisos, Tipos y Amenities',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Configura las habitaciones para cada piso.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppPill(
                label: 'Total: ${state.totalRoomsCount} habitaciones',
                color: AppColors.primary,
                icon: Icons.door_front_door_rounded,
              ),
              TextButton.icon(
                onPressed: () => ref
                    .read(hotelOnboardingProvider.notifier)
                    .applyQuickPreset(),
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  size: AppIconSize.sm,
                ),
                label: const Text('Generación rápida'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.floorsConfig.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final floor = state.floorsConfig[index];
              return _buildFloorCard(floor, index, theme);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCard(FloorConfig floor, int floorIndex, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  '${floor.floorNumber}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Piso ${floor.floorNumber} — Rango: ${(floor.floorNumber * 100) + 1} a ${(floor.floorNumber * 100) + floor.roomCount}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Habitaciones: ', style: theme.textTheme.bodyMedium),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: floor.roomCount > 1
                        ? () => ref
                            .read(hotelOnboardingProvider.notifier)
                            .updateFloorConfig(
                              floorIndex,
                              floor.copyWith(roomCount: floor.roomCount - 1),
                            )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      '${floor.roomCount}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: floor.roomCount < 30
                        ? () => ref
                            .read(hotelOnboardingProvider.notifier)
                            .updateFloorConfig(
                              floorIndex,
                              floor.copyWith(roomCount: floor.roomCount + 1),
                            )
                        : null,
                  ),
                ],
              ),

              DropdownButton<RoomType>(
                value: floor.roomType,
                items: RoomType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (newType) {
                  if (newType != null) {
                    ref
                        .read(hotelOnboardingProvider.notifier)
                        .updateFloorConfig(
                          floorIndex,
                          floor.copyWith(roomType: newType),
                        );
                  }
                },
              ),

              SizedBox(
                width: 136,
                child: TextFormField(
                  initialValue: floor.pricePerNight.toStringAsFixed(0),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    labelText: 'Precio/noche',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final price = double.tryParse(val) ?? floor.pricePerNight;
                    ref
                        .read(hotelOnboardingProvider.notifier)
                        .updateFloorConfig(
                          floorIndex,
                          floor.copyWith(pricePerNight: price),
                        );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Amenities incluidas:',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Wrap(
            spacing: AppSpacing.sm - 2,
            runSpacing: AppSpacing.xs,
            children: availableAmenities.map((amenity) {
              final isSelected = floor.amenities.contains(amenity);
              return FilterChip(
                label: Text(amenity, style: theme.textTheme.labelMedium),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                checkmarkColor: AppColors.primary,
                onSelected: (selected) {
                  final nextAmenities = List<String>.from(floor.amenities);
                  if (selected) {
                    nextAmenities.add(amenity);
                  } else {
                    nextAmenities.remove(amenity);
                  }
                  ref
                      .read(hotelOnboardingProvider.notifier)
                      .updateFloorConfig(
                        floorIndex,
                        floor.copyWith(amenities: nextAmenities),
                      );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Paso 3: Usuarios Iniciales ─────────────────────

  Widget _buildStep3InitialStaff(
    HotelOnboardingState state,
    ThemeData theme,
    AppStatusColors statusColors,
  ) {
    final authState = ref.watch(authProvider);
    final ownerName = authState.name?.isNotEmpty == true
        ? authState.name!
        : 'Dueño del Hotel';
    final ownerEmail = authState.email?.isNotEmpty == true
        ? authState.email!
        : 'dueno@hotel.com';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.group_rounded,
                color: AppColors.primary,
                size: 44,
                iconSize: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso 3: Creación de Usuarios Iniciales',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tu cuenta quedará como Administrador. Registra miembros de tu equipo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),

          AppCard(
            accent: AppColors.primary,
            tinted: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const AppIconBadge(
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$ownerName (Tú)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$ownerEmail · Rol: Administrador (Activo)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppPill(
                  label: 'Dueño / Admin',
                  color: AppColors.primary,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Agregar personal operativo:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _staffNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _staffEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<UserRole>(
                      initialValue: _selectedStaffRole,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.receptionist,
                          child: Text('Recepcionista'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.housekeeper,
                          child: Text('Ama de llaves'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.maintenance,
                          child: Text('Mantenimiento'),
                        ),
                      ],
                      onChanged: (role) {
                        if (role != null) {
                          setState(() => _selectedStaffRole = role);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md + 2,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar'),
                    onPressed: _addStaffMember,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (state.staffList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No has agregado personal adicional. Puedes agregarlos después desde Administración.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.staffList.length,
              itemBuilder: (context, index) {
                final staff = state.staffList[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppIconBadge(
                    icon: Icons.person_rounded,
                    color: statusColors.neutral,
                  ),
                  title: Text(staff.name, style: theme.textTheme.titleSmall),
                  subtitle: Text('${staff.email} · ${staff.role.label}'),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: statusColors.danger,
                    ),
                    onPressed: () => ref
                        .read(hotelOnboardingProvider.notifier)
                        .removeStaff(index),
                  ),
                );
              },
            ),

          const Divider(height: AppSpacing.xxl),

          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de configuración a dar de alta:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('• Hotel: ${state.hotelName} (${state.hotelId})'),
                Text(
                  '• Pisos: ${state.floorsCount} | Plan: ${state.plan.toUpperCase()}',
                ),
                Text(
                  '• Habitaciones generadas: ${state.totalRoomsCount} habitaciones',
                ),
                Text(
                  '• Usuarios a registrar: 1 Administrador + ${state.staffList.length} empleados',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Botones de Acción Inferiores ───────────────────

  Widget _buildBottomActionButtons(
    HotelOnboardingState state,
    ThemeData theme,
    AppStatusColors statusColors,
  ) {
    return Container(
      padding: AppSpacing.screen,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.currentStep > 0)
            OutlinedButton.icon(
              onPressed: state.isSubmitting
                  ? null
                  : () => ref
                      .read(hotelOnboardingProvider.notifier)
                      .previousStep(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Anterior'),
            )
          else
            const SizedBox.shrink(),
          if (state.currentStep < 2)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              onPressed: () =>
                  ref.read(hotelOnboardingProvider.notifier).nextStep(),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Siguiente'),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              onPressed: state.isSubmitting ? null : _submitWizard,
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                state.isSubmitting
                    ? 'Generando estructura...'
                    : 'Finalizar y dar de alta hotel',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitWizard() async {
    final authState = ref.read(authProvider);
    final ownerId = authState.email != null && authState.email!.isNotEmpty
        ? authState.email!.replaceAll('@', '_').replaceAll('.', '_')
        : 'owner_${DateTime.now().millisecondsSinceEpoch}';
    final ownerName = authState.name ?? 'Dueño del Hotel';
    final ownerEmail = authState.email ?? 'dueno@hotel.com';

    await ref.read(hotelOnboardingProvider.notifier).submitOnboarding(
          ownerId: ownerId,
          ownerName: ownerName,
          ownerEmail: ownerEmail,
        );

    if (!mounted) return;
    final state = ref.read(hotelOnboardingProvider);
    if (state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Hotel "${state.hotelName}" dado de alta exitosamente con ${state.totalRoomsCount} habitaciones!',
          ),
          backgroundColor: AppStatusColors.of(context).success,
        ),
      );
      context.go(AppRoutes.dashboard);
    }
  }
}
