import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/presentation/providers/connectivity/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  final EdgeInsetsGeometry margin;
  final bool compact;

  const OfflineBanner({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final isOnline = syncState.isOnline;

    if (isOnline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bannerBgColor = isDark
        ? const Color(0xFF78350F).withValues(alpha: 0.9)
        : const Color(0xFFFEF3C7);
    final bannerBorderColor = isDark
        ? const Color(0xFFB45309)
        : const Color(0xFFF59E0B);
    final bannerTextColor = isDark
        ? const Color(0xFFFEF3C7)
        : const Color(0xFF92400E);
    final bannerIconColor = isDark
        ? const Color(0xFFFCD34D)
        : const Color(0xFFD97706);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: const Key('offline_banner'),
        margin: margin,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: bannerBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bannerBorderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: bannerBorderColor.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bannerIconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: compact ? 16 : 18,
                color: bannerIconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Modo fuera de línea',
                        style: TextStyle(
                          color: bannerTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 12 : 13,
                        ),
                      ),
                      if (syncState.hasPendingWrites) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: bannerIconColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Sincronización pendiente',
                            style: TextStyle(
                              color: bannerTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Mostrando datos guardados en caché local. Los cambios se enviarán al reconectar.',
                      style: TextStyle(
                        color: bannerTextColor.withValues(alpha: 0.85),
                        fontSize: 11,
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
