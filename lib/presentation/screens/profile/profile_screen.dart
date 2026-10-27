import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/admin/employees_provider.dart';
import 'dart:math';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── AppBar con gradiente ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(email: authState.email, roleLabel: authState.role?.label ?? ''),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Tarjeta de información ─────────────────────────────────
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: authState.email ?? 'No disponible',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Rol',
                      value: authState.role?.label ?? 'Desconocido',
                      trailing: _RoleBadge(roleLabel: authState.role?.label ?? ''),
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Estado',
                      value: 'Activo',
                      trailing: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Tarjeta de configuración (Wearable) ───────────────────────────────
                if (authState.role == UserRole.housekeeper) ...[
                  _InfoCard(
                    children: [
                      _ActionRow(
                        icon: Icons.watch_outlined,
                        label: 'Vincular Reloj (Wearable)',
                        onTap: () async {
                          final userId = FirebaseAuth.instance.currentUser?.uid;
                          if (userId == null) return;
                          
                          // Generar PIN de 4 dígitos
                          final pin = (1000 + Random().nextInt(9000)).toString();
                          
                          try {
                            // Guardar mediante el repositorio
                            await ref
                                .read(employeesRepositoryProvider)
                                .linkWearablePin(userId, pin);
                            
                            // Mostrar PIN al usuario
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.watch, size: 48, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Vincula tu Reloj',
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ingresa este PIN de 4 dígitos en la pantalla de tu smartwatch para sincronizarlo.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 32),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            pin,
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: () => Navigator.pop(dialogContext),
                                            child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Panel de Administración ────────────────────────────────
                if (authState.role == UserRole.admin) ...[
                  _InfoCard(
                    children: [
                      _ActionRow(
                        icon: Icons.people_outline,
                        label: 'Administrar Empleados',
                        onTap: () => context.push('/admin/employees'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Botón cerrar sesión ────────────────────────────────────
                _LogoutButton(
                  onLogout: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),

                const SizedBox(height: 12),

                // Versión de la app
                Center(
                  child: Text(
                    'Hotel Manager v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Header ─────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String? email;
  final String roleLabel;
  const _ProfileHeader({required this.email, required this.roleLabel});

  /// Iniciales del email para el avatar
  String get _initials {
    if (email == null || email!.isEmpty) return '?';
    final name = email!.split('@').first;
    if (name.isEmpty) return '?';
    if (name.length == 1) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF661A), Color(0xFFFF9A5C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Avatar con iniciales
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              email ?? 'usuario@hotel.com',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            _RoleBadge(light: true, roleLabel: roleLabel),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Role Badge ─────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final bool light;
  final String roleLabel;
  const _RoleBadge({this.light = false, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.25)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 13,
            color: light ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            roleLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: light ? Colors.white : AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Info Card ──────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────── Info Row ───────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 2),
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

// ─────────────────────────── Action Row ─────────────────────────────────────

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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
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
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Logout Button ──────────────────────────────────

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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(_loading ? 'Cerrando sesión...' : 'Cerrar sesión'),
      ),
    );
  }
}
