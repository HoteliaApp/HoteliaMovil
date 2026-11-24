import 'package:flutter/material.dart';
import 'package:hotel_app/config/theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
//  HOTELIA UI KIT — componentes base reutilizables.
//  Derivados del patrón visual del Dashboard (design system H-19).
//  Úsalos en lugar de recrear contenedores/badges a mano en cada pantalla.
// ════════════════════════════════════════════════════════════════════════════

/// Título de sección: ícono naranja opcional + título en negritas +
/// pastilla de conteo opcional a la derecha.
class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
        if (subtitle != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: AppPill(
              key: ValueKey<String>(subtitle!),
              label: subtitle!,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

/// Pastilla/chip de estado con color semántico (fondo tintado + texto del color).
class AppPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;
  final bool dense;

  const AppPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.outlined = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = (dense
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm - 2 : AppSpacing.sm + 2,
        vertical: dense ? AppSpacing.xxs : AppSpacing.xs - 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.badge),
        borderRadius: AppRadius.mdAll,
        border: outlined ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : AppIconSize.xs, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Ícono dentro de un círculo tintado del mismo color.
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.badge),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.45),
    );
  }
}

/// Tarjeta base de la marca: fondo blanco (claro) / gris (oscuro), radio 16,
/// borde suave (opcionalmente tintado con [accent]) y sombra ligera.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Si es true, el fondo se tinta con [accent] (estilo tarjeta de métrica).
  final bool tinted;

  const AppCard({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = accent != null
        ? accent!.withValues(alpha: isDark ? AppAlpha.borderDark : AppAlpha.border)
        : theme.dividerColor.withValues(alpha: isDark ? 0.5 : 0.8);
    final bg = tinted && accent != null
        ? Color.alphaBlend(accent!.withValues(alpha: AppAlpha.tint), theme.cardColor)
        : theme.cardColor;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: bg,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: borderColor),
              boxShadow: tinted ? null : AppShadows.soft,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de métrica: ícono en círculo + valor grande + etiqueta, tintada.
class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      accent: color,
      tinted: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: color, size: 34, iconSize: AppIconSize.sm),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío / informativo centrado (ícono grande + título + mensaje + acción).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? color;

  /// Si es true, se dibuja dentro de una [AppCard] (para listas en secciones).
  final bool inCard;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color,
    this.inCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: inCard ? 36 : AppIconSize.hero, color: c),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: (inCard ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)
              ?.copyWith(
            color: inCard ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: AppSpacing.xl),
          action!,
        ],
      ],
    );

    if (inCard) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
        child: Center(child: content),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: content,
      ),
    );
  }
}

/// Estado de error con botón de reintento.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      color: AppStatusColors.of(context).danger,
      title: 'Algo salió mal',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
    );
  }
}

/// Banner informativo tintado (info/advertencia/error/éxito) dentro del contenido.
class AppInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final String? title;
  final Widget? action;

  const AppInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      accent: color,
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: AppSpacing.sm), action!],
        ],
      ),
    );
  }
}

/// Encabezado de diálogo estándar: ícono en círculo + título.
class AppDialogTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const AppDialogTitle({super.key, required this.icon, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        AppIconBadge(icon: icon, color: c, size: 40, iconSize: AppIconSize.md),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}
