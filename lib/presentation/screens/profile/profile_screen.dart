import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';
import 'package:hotel_app/presentation/providers/providers.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:hotel_app/presentation/widgets/subscription/subscription.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final roleLabel = authState.role?.label ?? 'Desconocido';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          // ── Cabecera de perfil limpia y sobria ──
          _ProfileHeaderCard(
            email: authState.email,
            roleLabel: roleLabel,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Tarjeta de información ──
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_rounded,
                  label: 'Correo electrónico',
                  value: authState.email ?? 'No disponible',
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.badge_rounded,
                  label: 'Rol',
                  value: roleLabel,
                  trailing: AppPill(
                    label: roleLabel.toUpperCase(),
                    color: AppColors.primary,
                    icon: Icons.star_rounded,
                    dense: true,
                  ),
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.verified_user_rounded,
                  label: 'Estado',
                  value: 'Activo',
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Tarjeta de Apariencia ──
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                AppIconBadge(
                  icon: ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : ref.watch(themeModeProvider) == ThemeMode.light
                          ? Icons.light_mode_rounded
                          : Icons.brightness_auto_rounded,
                  color: AppColors.primary,
                  size: 36,
                  iconSize: AppIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tema visual', style: theme.textTheme.titleSmall),
                      Text(
                        'Claro, oscuro o sistema',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 16),
                    ),
                  ],
                  selected: {ref.watch(themeModeProvider)},
                  onSelectionChanged: (selected) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selected.first);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Configuración Wearable (Camarista) ──
          if (authState.role == UserRole.housekeeper) ...[
            AppCard(
              padding: EdgeInsets.zero,
              child: _ActionRow(
                icon: Icons.watch_rounded,
                label: 'Vincular Reloj (Wearable)',
                onTap: () => _linkWearable(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Panel de Administración ──
          if (authState.role == UserRole.admin) ...[
            const SubscriptionCard(),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.people_rounded,
                    label: 'Administrar Empleados',
                    onTap: () => context.push('/admin/employees'),
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.card_membership_rounded,
                    label: 'Detalles de Suscripción SaaS',
                    onTap: () => context.push('/admin/subscription'),
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.history_edu_rounded,
                    label: 'Bitácora de Auditoría',
                    onTap: () => context.push('/admin/audit'),
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reportes de Productividad',
                    onTap: () => context.push('/admin/reports'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Cerrar sesión ──
          _LogoutButton(
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Hotelia v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _linkWearable(BuildContext context, WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final pin = (1000 + Random().nextInt(9000)).toString();

    try {
      await ref.read(employeesRepositoryProvider).linkWearablePin(userId, pin);
      if (!context.mounted) return;
      final theme = Theme.of(context);
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconBadge(
                  icon: Icons.watch_rounded,
                  color: AppColors.primary,
                  size: 68,
                  iconSize: 34,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Vincula tu Reloj',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ingresa este PIN de 4 dígitos en la pantalla de tu smartwatch para sincronizarlo.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  accent: AppColors.primary,
                  tinted: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Text(
                    pin,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String? email;
  final String roleLabel;
  const _ProfileHeaderCard({required this.email, required this.roleLabel});

  String get _initials {
    if (email == null || email!.isEmpty) return '?';
    final name = email!.split('@').first;
    if (name.isEmpty) return '?';
    if (name.length == 1) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      accent: AppColors.primary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: AppAlpha.badge),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? 'usuario@hotel.com',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppPill(
                  label: roleLabel.toUpperCase(),
                  color: AppColors.primary,
                  icon: Icons.star_rounded,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      child: Row(
        children: [
          AppIconBadge(
            icon: icon,
            color: AppColors.primary,
            size: 36,
            iconSize: AppIconSize.sm,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            AppIconBadge(
              icon: icon,
              color: theme.colorScheme.onSurfaceVariant,
              size: 36,
              iconSize: AppIconSize.sm,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIconSize.md - 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final Future<void> Function() onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final danger = AppStatusColors.of(context).danger;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: danger,
          side: BorderSide(color: danger),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
        ),
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onLogout();
                if (mounted) setState(() => _loading = false);
              },
        icon: _loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: danger,
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(_loading ? 'Cerrando sesión...' : 'Cerrar sesión'),
      ),
    );
  }
}
