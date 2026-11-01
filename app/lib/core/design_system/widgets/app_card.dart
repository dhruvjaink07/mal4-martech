import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';

enum CardVariant {
  standard,
  accentGreen,
  accentRed,
  elevated,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final CardVariant variant;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.variant = CardVariant.standard,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final effectiveBorderColor = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    Border border;
    if (borderColor != null) {
      border = Border.all(color: borderColor!, width: 1.0);
    } else {
      switch (variant) {
        case CardVariant.accentGreen:
          border = Border(
            left: const BorderSide(color: AppColors.defenseGreen, width: 3.5),
            top: BorderSide(color: effectiveBorderColor),
            right: BorderSide(color: effectiveBorderColor),
            bottom: BorderSide(color: effectiveBorderColor),
          );
          break;
        case CardVariant.accentRed:
          border = Border(
            left: const BorderSide(color: AppColors.defenseRed, width: 3.5),
            top: BorderSide(color: effectiveBorderColor),
            right: BorderSide(color: effectiveBorderColor),
            bottom: BorderSide(color: effectiveBorderColor),
          );
          break;
        case CardVariant.elevated:
        case CardVariant.standard:
          border = Border.all(color: effectiveBorderColor, width: 1.0);
          break;
      }
    }

    final cardContent = Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppSpacing.borderLg,
        border: border,
      ),
      padding: padding ?? AppSpacing.cardPadding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderLg,
          splashColor: AppColors.defenseGreen.withValues(alpha: 0.1),
          highlightColor: isDark ? AppColors.darkElevated : AppColors.lightElevated,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

