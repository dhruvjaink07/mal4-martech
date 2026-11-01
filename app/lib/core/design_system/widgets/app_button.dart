import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

enum ButtonVariant {
  primary,
  secondary,
  destructive,
  outline,
}

typedef AppButtonVariant = ButtonVariant;

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.defenseGreen;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = isDark ? AppColors.darkElevated : AppColors.lightElevated;
        fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
        break;
      case ButtonVariant.destructive:
        bg = AppColors.defenseRed;
        fg = Colors.white;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
        break;
    }

    final effectiveHeight = height ?? AppSpacing.primaryButtonHeight;

    return SizedBox(
      height: effectiveHeight,
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: Size(width ?? 64.0, effectiveHeight),
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderMd,
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: AppTypography.titleMedium.copyWith(color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}

