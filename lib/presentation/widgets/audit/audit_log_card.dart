import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/domain/entities/audit_log.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';
import 'package:intl/intl.dart';

class AuditLogCard extends StatelessWidget {
  final AuditLog log;

  const AuditLogCard({super.key, required this.log});

  Color _getActionColor(BuildContext context, AuditActionType type) {
    final statusColors = AppStatusColors.of(context);
    return switch (type) {
      AuditActionType.cancellation => statusColors.danger,
      AuditActionType.checkIn => statusColors.success,
      AuditActionType.checkOut => statusColors.info,
      AuditActionType.roleChange => statusColors.warning,
      AuditActionType.subscription => statusColors.purple,
      AuditActionType.hotel => AppColors.primary,
      AuditActionType.other => statusColors.neutral,
    };
  }

  IconData _getActionIcon(AuditActionType type) {
    return switch (type) {
      AuditActionType.cancellation => Icons.cancel_rounded,
      AuditActionType.checkIn => Icons.login_rounded,
      AuditActionType.checkOut => Icons.logout_rounded,
      AuditActionType.roleChange => Icons.manage_accounts_rounded,
      AuditActionType.subscription => Icons.card_membership_rounded,
      AuditActionType.hotel => Icons.apartment_rounded,
      AuditActionType.other => Icons.receipt_long_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final actionColor = _getActionColor(context, log.actionType);
    final actionIcon = _getActionIcon(log.actionType);

    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp);

    return AppCard(
      accent: log.isCritical ? actionColor : null,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                label: log.actionType.label,
                color: actionColor,
                icon: actionIcon,
                outlined: true,
                dense: true,
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: AppIconSize.xs,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              AppIconBadge(
                icon: Icons.person_rounded,
                color: actionColor,
                size: 24,
                iconSize: AppIconSize.xs,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Operado por: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      log.operatorDisplayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (log.performedByName != null &&
                        log.performedBy.isNotEmpty &&
                        log.performedBy != log.performedByName)
                      Text(
                        ' (${log.performedBy})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),

          Text(
            log.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),

          if (log.reason != null && log.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppInfoBanner(
              icon: Icons.error_outline_rounded,
              color: statusColors.danger,
              title: 'Motivo de cancelación:',
              message: log.reason!,
            ),
          ],

          if (log.targetId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    'Ref: #${log.targetId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
