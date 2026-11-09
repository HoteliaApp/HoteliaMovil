import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/user.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
      UserStatus.rejected => cs.error,
      UserStatus.inactive => cs.outline,
      _ => AppColors.primary,
    };

    final icon = switch (status) {
      UserStatus.rejected => Icons.cancel_outlined,
      UserStatus.inactive => Icons.block_outlined,
      _ => Icons.hourglass_empty,
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.secondaryContainer.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                          child: Icon(icon, size: 40, color: iconColor),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                            context.go('/login');
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Volver al inicio / Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
