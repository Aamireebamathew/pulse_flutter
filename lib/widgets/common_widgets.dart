import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GLASS CARD
// ═══════════════════════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.color,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = color ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final shadows = elevated
        ? (isDark ? AppShadows.darkMd : AppShadows.lightMd)
        : (isDark ? AppShadows.darkSm : AppShadows.lightSm);

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final List<Color>? gradient;
  final IconData? icon;
  final double height;
  final bool fullWidth;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.gradient,
    this.icon,
    this.height = 50,
    this.fullWidth = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isDisabled = widget.onPressed == null || widget.loading;

    final defaultGradient = isDark
        ? [AppColors.purple600, AppColors.purple700]
        : [AppColors.blue500, AppColors.blue600];

    final colors = isDisabled
        ? [
            isDark ? AppColors.darkSurface3 : AppColors.lightBorder,
            isDark ? AppColors.darkSurface3 : AppColors.lightBorder,
          ]
        : (widget.gradient ?? defaultGradient);

    final shadows = isDisabled
        ? <BoxShadow>[]
        : (isDark ? AppShadows.purpleGlow : AppShadows.blueGlow);

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _ctrl.forward(),
      onTapUp: isDisabled
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (widget.loading)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: isDisabled ? Colors.white38 : Colors.white),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: AppTextStyles.h4.copyWith(
                        color: isDisabled ? Colors.white38 : Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CARD  ── backward-compatible: supports both old (iconBgColor/iconColor)
//               and new (color) call sites
// ═══════════════════════════════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  // Old API — kept for backward compat with existing screens
  final Color? iconBgColor;
  final Color? iconColor;

  // New API — single accent color (iconBgColor/iconColor derived automatically)
  final Color? color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    // old
    this.iconBgColor,
    this.iconColor,
    // new
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // Resolve colors: prefer explicit iconColor/iconBgColor; fall back to color;
    // fall back to theme primary.
    final accent = iconColor ?? color ?? context.primary;
    final bg = iconBgColor ??
        (color != null
            ? color!.withOpacity(isDark ? 0.15 : 0.10)
            : context.primary.withOpacity(isDark ? 0.15 : 0.10));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.display
                .copyWith(color: context.textPrimary, fontSize: 26),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(color: context.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PULSE LOGO
// ═══════════════════════════════════════════════════════════════════════════════

class PulseLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const PulseLogo({super.key, this.size = 36, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.purple500, AppColors.purple700]
                  : [AppColors.blue400, AppColors.blue600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow:
                isDark ? AppShadows.purpleGlow : AppShadows.blueGlow,
          ),
          child: Icon(Icons.radar_outlined,
              color: Colors.white, size: size * 0.55),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.28),
          Text(
            'Pulse',
            style: AppTextStyles.h2.copyWith(
              color: context.textPrimary,
              fontSize: size * 0.56,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PULSE BACKGROUND
// ═══════════════════════════════════════════════════════════════════════════════

class PulseBackground extends StatelessWidget {
  final Widget child;
  const PulseBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.8),
          radius: 1.2,
          colors: isDark
              ? [AppColors.purple900.withOpacity(0.30), AppColors.darkBg]
              : [AppColors.blue50, AppColors.lightBg],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _DotGridPainter(isDark: isDark)),
          ),
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.purple600.withOpacity(0.10),
                          Colors.transparent,
                        ]
                      : [
                          AppColors.blue400.withOpacity(0.07),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? AppColors.purple600.withOpacity(0.05)
          : AppColors.blue500.withOpacity(0.035)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PULSE SNACK BAR  ── restored for backward compat
// ═══════════════════════════════════════════════════════════════════════════════

class PulseSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    Color bg = isDark ? AppColors.darkSurface3 : AppColors.lightText;
    if (isError) bg = AppColors.error;
    if (isSuccess) bg = AppColors.success;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: duration,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════════

enum BadgeVariant { success, warning, error, info, neutral, purple }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool dot;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final (Color bg, Color fg, Color border) = switch (variant) {
      BadgeVariant.success => (
          isDark
              ? AppColors.success.withOpacity(0.15)
              : AppColors.successBg,
          AppColors.success,
          AppColors.success.withOpacity(0.3),
        ),
      BadgeVariant.warning => (
          isDark
              ? AppColors.warning.withOpacity(0.15)
              : AppColors.warningBg,
          AppColors.warning,
          AppColors.warning.withOpacity(0.3),
        ),
      BadgeVariant.error => (
          isDark
              ? AppColors.error.withOpacity(0.15)
              : AppColors.errorBg,
          AppColors.error,
          AppColors.error.withOpacity(0.3),
        ),
      BadgeVariant.purple => (
          isDark
              ? AppColors.purple600.withOpacity(0.20)
              : AppColors.purple50,
          isDark ? AppColors.purple400 : AppColors.purple600,
          isDark
              ? AppColors.purple600.withOpacity(0.4)
              : AppColors.purple100,
        ),
      BadgeVariant.info => (
          isDark
              ? AppColors.info.withOpacity(0.15)
              : AppColors.infoBg,
          AppColors.info,
          AppColors.info.withOpacity(0.3),
        ),
      BadgeVariant.neutral => (
          isDark ? AppColors.darkSurface3 : AppColors.lightBg,
          isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
          isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6, height: 6,
              decoration:
                  BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(label,
              style: AppTextStyles.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.h3
                        .copyWith(color: context.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: context.textMuted)),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon,
                  size: 32, color: context.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: AppTextStyles.h3
                    .copyWith(color: context.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTextStyles.body
                    .copyWith(color: context.textMuted),
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl2),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING INDICATOR
// ═══════════════════════════════════════════════════════════════════════════════

class PulseLoader extends StatelessWidget {
  final String? message;
  final double size;

  const PulseLoader({super.key, this.message, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size, height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(context.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!,
                style: AppTextStyles.bodySm
                    .copyWith(color: context.textMuted)),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFO BANNER
// ═══════════════════════════════════════════════════════════════════════════════

class InfoBanner extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final BadgeVariant variant;

  const InfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
    this.variant = BadgeVariant.info,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final (Color bg, Color fg, Color border) = switch (variant) {
      BadgeVariant.success => (
          isDark
              ? AppColors.success.withOpacity(0.10)
              : AppColors.successBg,
          AppColors.success,
          AppColors.success.withOpacity(0.25),
        ),
      BadgeVariant.warning => (
          isDark
              ? AppColors.warning.withOpacity(0.10)
              : AppColors.warningBg,
          AppColors.warning,
          AppColors.warning.withOpacity(0.25),
        ),
      BadgeVariant.error => (
          isDark
              ? AppColors.error.withOpacity(0.10)
              : AppColors.errorBg,
          AppColors.error,
          AppColors.error.withOpacity(0.25),
        ),
      BadgeVariant.purple => (
          isDark
              ? AppColors.purple600.withOpacity(0.12)
              : AppColors.purple50,
          isDark ? AppColors.purple400 : AppColors.purple600,
          isDark
              ? AppColors.purple600.withOpacity(0.35)
              : AppColors.purple100,
        ),
      _ => (
          isDark ? AppColors.info.withOpacity(0.10) : AppColors.infoBg,
          AppColors.info,
          AppColors.info.withOpacity(0.25),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.h4.copyWith(color: fg)),
                const SizedBox(height: AppSpacing.xs),
                Text(body,
                    style: AppTextStyles.bodySm
                        .copyWith(color: fg.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LABELED DIVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class LabeledDivider extends StatelessWidget {
  final String label;
  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label,
              style:
                  AppTextStyles.label.copyWith(color: context.textMuted)),
        ),
        Expanded(child: Divider(color: context.border, thickness: 1)),
      ],
    );
  }
}