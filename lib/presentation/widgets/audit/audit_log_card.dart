import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/audit_log.dart';
import 'package:intl/intl.dart';

class AuditLogCard extends StatelessWidget {
  final AuditLog log;

  const AuditLogCard({
    super.key,
    required this.log,
  });

  Color _getActionColor(AuditActionType type) {
    return switch (type) {
      AuditActionType.cancellation => Colors.red[700]!,
      AuditActionType.checkIn => const Color(0xFF10B981),
      AuditActionType.checkOut => const Color(0xFF2563EB),
      AuditActionType.roleChange => const Color(0xFFF59E0B),
      AuditActionType.subscription => const Color(0xFF8B5CF6),
      AuditActionType.hotel => const Color(0xFF0D9488),
      AuditActionType.other => const Color(0xFF6B7280),
    };
  }

  IconData _getActionIcon(AuditActionType type) {
    return switch (type) {
      AuditActionType.cancellation => Icons.cancel_outlined,
      AuditActionType.checkIn => Icons.login_rounded,
      AuditActionType.checkOut => Icons.logout_rounded,
      AuditActionType.roleChange => Icons.manage_accounts_outlined,
      AuditActionType.subscription => Icons.card_membership_outlined,
      AuditActionType.hotel => Icons.apartment_outlined,
      AuditActionType.other => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionColor = _getActionColor(log.actionType);
    final actionIcon = _getActionIcon(log.actionType);

    final formattedDate =
        DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: log.isCritical
              ? actionColor.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: log.isCritical ? 1.5 : 1.0,
        ),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Badge de acción y fecha/hora
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: actionColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(actionIcon, size: 14, color: actionColor),
                      const SizedBox(width: 6),
                      Text(
                        log.actionType.label,
                        style: TextStyle(
                          color: actionColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Operador (Nombre y correo)
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: actionColor.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: actionColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Operado por: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        log.operatorDisplayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (log.performedByName != null &&
                          log.performedBy.isNotEmpty &&
                          log.performedBy != log.performedByName)
                        Text(
                          ' (${log.performedBy})',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Descripción de la acción
            Text(
              log.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),

            // Motivo destacado (Crucial para Escenario 1 de Cancelaciones)
            if (log.reason != null && log.reason!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motivo de cancelación:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.reason!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Target ID si existe
            if (log.targetId.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ref: #${log.targetId}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
