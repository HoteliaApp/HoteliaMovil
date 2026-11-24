import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final authState = ref.watch(authProvider);
    final status = authState.status ?? UserStatus.pending;

    final title = switch (status) {
      UserStatus.rejected => 'Cuenta Rechazada',
      UserStatus.inactive => 'Cuenta Inactiva',
      _ => 'Cuenta Pendiente',
    };

    final message = switch (status) {
      UserStatus.rejected =>
        'Tu solicitud de registro ha sido rechazada por la administración del hotel.\n\n'
            'Para más información o aclaraciones, contacta directamente a la gerencia.',
      UserStatus.inactive =>
        'Tu cuenta de empleado ha sido desactivada temporalmente.\n\n'
            'Comunícate con el administrador para reactivar tu acceso.',
      _ =>
        'Registro realizado correctamente.\n\n'
            'Tu cuenta está pendiente de validación por parte del gerente.\n\n'
            'Una vez que tu cuenta sea aprobada y se te asigne un rol, '
            'podrás acceder directamente al sistema con los permisos correspondientes.',
    };

    final iconColor = switch (status) {
      UserStatus.rejected => statusColors.danger,
      UserStatus.inactive => statusColors.neutral,
      _ => AppColors.primary,
    };

    final icon = switch (status) {
      UserStatus.rejected => Icons.cancel_rounded,
      UserStatus.inactive => Icons.block_rounded,
      _ => Icons.hourglass_empty_rounded,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                accent: iconColor,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconBadge(
                      icon: icon,
                      color: iconColor,
                      size: 80,
                      iconSize: 40,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Volver al inicio / Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
