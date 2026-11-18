import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/router/app_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/onboarding/hotel_onboarding_provider.dart';

/// Pantalla del Asistente Guiado de Onboarding (H-25).
/// Permite a nuevos clientes hoteleros registrar su hotel, configurar pisos,
/// generar habitaciones con amenities y dar de alta usuarios iniciales en 3 pasos.
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

  // Controladores para agregar empleados iniciales en el Paso 3
  final _staffNameCtrl = TextEditingController();
  final _staffEmailCtrl = TextEditingController();
  UserRole _selectedStaffRole = UserRole.receptionist;

  // Lista de amenities estándar disponibles
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
        const SnackBar(
          content: Text('Ingresa un nombre y correo válido para el empleado.'),
          backgroundColor: Colors.red,
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
    final isDark = theme.brightness == Brightness.dark;

    // Sincronizar controladores de texto si no están en edición activa
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.currentStep > 0) {
              ref.read(hotelOnboardingProvider.notifier).previousStep();
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, const Color(0xFF1E1E1E)]
                : [AppColors.backgroundLight, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(state.currentStep, theme),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: MaterialBanner(
                    backgroundColor: theme.colorScheme.errorContainer,
                    content: Text(
                      state.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => ref
                            .read(hotelOnboardingProvider.notifier)
                            .validateCurrentStep(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: switch (state.currentStep) {
                        0 => _buildStep1HotelInfo(state, theme),
                        1 => _buildStep2FloorsAndRooms(state, theme),
                        2 => _buildStep3InitialStaff(state, theme),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ),
              ),
              _buildBottomActionButtons(state, theme),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Indicador de Pasos ─────────────────────────────

  Widget _buildStepIndicator(int currentStep, ThemeData theme) {
    const steps = [
      '1. Datos del Hotel',
      '2. Pisos y Habitaciones',
      '3. Usuarios Iniciales',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(steps.length, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              final color = isCompleted
                  ? AppColors.success
                  : (isCurrent ? AppColors.primary : Colors.grey.shade500);

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => ref
                            .read(hotelOnboardingProvider.notifier)
                            .goToStep(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: color,
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    steps[index],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrent ? AppColors.primary : theme.textTheme.bodyMedium?.color,
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
                        color: isCompleted ? AppColors.success : Colors.grey.shade400,
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hotel, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paso 1: Datos Generales del Hotel',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa la información comercial y selecciona tu plan de suscripción SaaS.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const Divider(height: 32),

            // Nombre comercial
            TextFormField(
              controller: _hotelNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre comercial del hotel *',
                hintText: 'Ej. Gran Hotel Central',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  ref.read(hotelOnboardingProvider.notifier).setHotelName(val),
            ),
            const SizedBox(height: 16),

            // Identificador de inquilino (hotelId)
            TextFormField(
              controller: _hotelIdCtrl,
              decoration: InputDecoration(
                labelText: 'Identificador único del Inquilino (hotelId) *',
                hintText: 'hotel_nombre_unico',
                prefixIcon: const Icon(Icons.tag),
                border: const OutlineInputBorder(),
                helperText: 'Identificador del tenant para aislamiento estricto en Firestore.',
                suffixIcon: state.isCustomHotelId
                    ? IconButton(
                        icon: const Icon(Icons.restore),
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
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _hotelAddressCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección física *',
                hintText: 'Av. Las Palmas 123, Cancún, México',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  ref.read(hotelOnboardingProvider.notifier).setHotelAddress(val),
            ),
            const SizedBox(height: 20),

            // Cantidad de pisos
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Número de pisos a administrar:',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Define la estructura vertical de tu establecimiento.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: state.floorsCount > 1
                            ? () => ref
                                .read(hotelOnboardingProvider.notifier)
                                .setFloorsCount(state.floorsCount - 1)
                            : null,
                      ),
                      Text(
                        '${state.floorsCount}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
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
            const SizedBox(height: 24),

            // Selección de Plan SaaS
            Text(
              'Selecciona tu Plan SaaS:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 460) {
                  return Column(
                    children: [
                      _buildPlanCard('basic', 'Básico', '1-2 pisos · Gestión esencial', state.plan, theme),
                      const SizedBox(height: 8),
                      _buildPlanCard('standard', 'Estándar', 'Multi-piso · Relojes y tareas', state.plan, theme),
                      const SizedBox(height: 8),
                      _buildPlanCard('premium', 'Premium', 'Completo · Smart TV + Wearable', state.plan, theme),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildPlanCard('basic', 'Básico', '1-2 pisos\nGestión esencial', state.plan, theme),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPlanCard('standard', 'Estándar', 'Multi-piso\nRelojes y tareas', state.plan, theme),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPlanCard('premium', 'Premium', 'Completo\nSmart TV + Wearable', state.plan, theme),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
    return InkWell(
      onTap: () =>
          ref.read(hotelOnboardingProvider.notifier).setPlan(planKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(25) : theme.cardColor,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Paso 2: Pisos y Habitaciones ───────────────────

  Widget _buildStep2FloorsAndRooms(
      HotelOnboardingState state, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.meeting_room, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paso 2: Pisos, Tipos y Amenities',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Configura las habitaciones para cada piso.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Barra resumen y acción rápida
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.door_front_door, size: 18),
                  label: Text(
                    'Total: ${state.totalRoomsCount} habitaciones',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.primary.withAlpha(20),
                ),
                TextButton.icon(
                  onPressed: () => ref
                      .read(hotelOnboardingProvider.notifier)
                      .applyQuickPreset(),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generación rápida'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de configuraciones por piso
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.floorsConfig.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final floor = state.floorsConfig[index];
                return _buildFloorCard(floor, index, theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorCard(FloorConfig floor, int floorIndex, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Piso ${floor.floorNumber} — Rango: ${(floor.floorNumber * 100) + 1} a ${(floor.floorNumber * 100) + floor.roomCount}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Controles de cantidad, tipo y precio
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Cantidad de habitaciones
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Habitaciones: '),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove, size: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${floor.roomCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add, size: 16),
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

              // Tipo de habitación
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

              // Precio por noche
              SizedBox(
                width: 130,
                child: TextFormField(
                  initialValue: floor.pricePerNight.toStringAsFixed(0),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    labelText: 'Precio/noche',
                    isDense: true,
                    border: OutlineInputBorder(),
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
          const SizedBox(height: 12),

          // Amenities selector (Chips)
          Text(
            'Amenities incluidas:',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: availableAmenities.map((amenity) {
              final isSelected = floor.amenities.contains(amenity);
              return FilterChip(
                label: Text(amenity, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                selectedColor: AppColors.primary.withAlpha(40),
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
      HotelOnboardingState state, ThemeData theme) {
    final authState = ref.watch(authProvider);
    final ownerName = authState.name?.isNotEmpty == true
        ? authState.name!
        : 'Dueño del Hotel';
    final ownerEmail = authState.email?.isNotEmpty == true
        ? authState.email!
        : 'dueno@hotel.com';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paso 3: Creación de Usuarios Iniciales',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tu cuenta quedará como Administrador. Registra miembros de tu equipo.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Tarjeta del Dueño (Admin)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$ownerName (Tú)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$ownerEmail · Rol: Administrador (Activo)',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Dueño / Admin', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulario para agregar personal adicional
            Text(
              'Agregar personal operativo:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _staffEmailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UserRole>(
                        initialValue: _selectedStaffRole,
                        isExpanded: true,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
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
                          if (role != null) setState(() => _selectedStaffRole = role);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                      onPressed: _addStaffMember,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de personal inicial configurado
            if (state.staffList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No has agregado personal adicional. Puedes agregarlos después desde Administración.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.black54),
                    ),
                    title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${staff.email} · ${staff.role.label}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => ref
                          .read(hotelOnboardingProvider.notifier)
                          .removeStaff(index),
                    ),
                  );
                },
              ),

            const Divider(height: 32),

            // Resumen de la configuración
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen de configuración a dar de alta:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('• Hotel: ${state.hotelName} (${state.hotelId})'),
                  Text('• Pisos: ${state.floorsCount} | Plan: ${state.plan.toUpperCase()}'),
                  Text('• Habitaciones generadas: ${state.totalRoomsCount} habitaciones'),
                  Text('• Usuarios a registrar: 1 Administrador + ${state.staffList.length} empleados'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Botones de Acción Inferiores ───────────────────

  Widget _buildBottomActionButtons(
      HotelOnboardingState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
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
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
            )
          else
            const SizedBox.shrink(),
          if (state.currentStep < 2)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () =>
                  ref.read(hotelOnboardingProvider.notifier).nextStep(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Siguiente'),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  : const Icon(Icons.check_circle),
              label: Text(
                state.isSubmitting
                    ? 'Generando estructura...'
                    : 'Finalizar y dar de alta hotel',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
          backgroundColor: Colors.green,
        ),
      );
      // Redirigir al dashboard del nuevo hotel
      context.go(AppRoutes.dashboard);
    }
  }
}
