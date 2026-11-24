import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/theme/app_theme.dart';
import 'package:hotel_app/presentation/providers/connectivity/connectivity_provider.dart';
import 'package:hotel_app/presentation/widgets/shared/app_ui.dart';

class OfflineBanner extends ConsumerWidget {
  final EdgeInsetsGeometry margin;
  final bool compact;

  const OfflineBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      0,
    ),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    if (syncState.isOnline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);
    final warningColor = statusColors.warning;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AppCard(
        key: const Key('offline_banner'),
        accent: warningColor,
        tinted: true,
        margin: margin,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compact ? 6 : 8,
        ),
        child: Row(
          children: [
            AppIconBadge(
              icon: Icons.wifi_off_rounded,
              color: warningColor,
              size: compact ? 30 : 36,
              iconSize: compact ? AppIconSize.xs + 2 : AppIconSize.sm,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Modo fuera de línea',
                        style:
                            (compact
                                    ? theme.textTheme.labelMedium
                                    : theme.textTheme.titleSmall)
                                ?.copyWith(
                                  color: warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (syncState.hasPendingWrites)
                        AppPill(
                          label: 'Sincronización pendiente',
                          color: warningColor,
                          dense: true,
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Mostrando datos guardados en caché local. Los cambios se enviarán al reconectar.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
