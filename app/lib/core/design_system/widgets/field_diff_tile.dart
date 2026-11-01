import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class FieldDiffTile extends StatelessWidget {
  final String fieldName;
  final String oldValue;
  final String newValue;
  final bool isMaterial;
  final String? rationale;

  const FieldDiffTile({
    super.key,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.isMaterial,
    this.rationale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppSpacing.borderMd,
        border: Border.all(
          color: isMaterial ? AppColors.defenseRed.withValues(alpha: 0.5) : borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fieldName.toUpperCase(),
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 12.0,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: isMaterial ? AppColors.defenseRedLight : AppColors.stateDraftBg,
                  borderRadius: AppSpacing.borderSm,
                ),
                child: Text(
                  isMaterial ? 'MATERIAL' : 'NON-MATERIAL',
                  style: AppTypography.labelBadge.copyWith(
                    fontSize: 9.5,
                    color: isMaterial ? AppColors.defenseRed : AppColors.stateDraftText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Old value
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 24,
                child: Text('[-]', style: TextStyle(color: AppColors.defenseRed, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text(
                  oldValue,
                  style: AppTypography.codeMedium.copyWith(
                    fontSize: 12.0,
                    color: AppColors.defenseRed,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          // New value
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 24,
                child: Text('[+]', style: TextStyle(color: AppColors.defenseGreen, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text(
                  newValue,
                  style: AppTypography.codeMedium.copyWith(
                    fontSize: 12.0,
                    color: AppColors.defenseGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (rationale != null) ...[
            const SizedBox(height: 6.0),
            Text(
              rationale!,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.0,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

