import 'package:flutter/material.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/field_diff_tile.dart';
import '../../../campaign_management/domain/campaign_repository.dart';

class StructuredDiffViewerScreen extends StatelessWidget {
  final CampaignRevisionDiff diff;

  const StructuredDiffViewerScreen({super.key, required this.diff});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMaterial = diff.diffs.any((d) => d.isMaterial);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${diff.campaignId.toUpperCase()} • REVISION AUDIT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
            Text(
              'v${diff.previousVersion} → v${diff.currentVersion} Diff Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Governance impact banner
            AppCard(
              backgroundColor: hasMaterial
                  ? AppColors.defenseRed.withValues(alpha: 0.1)
                  : AppColors.defenseGreen.withValues(alpha: 0.1),
              borderColor: hasMaterial
                  ? AppColors.defenseRed.withValues(alpha: 0.5)
                  : AppColors.defenseGreen.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hasMaterial ? Icons.warning_rounded : Icons.check_circle_rounded,
                    color: hasMaterial ? AppColors.defenseRed : AppColors.defenseGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasMaterial
                              ? 'MATERIAL CHANGES DETECTED (STAGE 1 RESET)'
                              : 'NON-MATERIAL REVISION (NO STAGE INVALIDATION)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: hasMaterial ? AppColors.defenseRed : AppColors.defenseGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasMaterial
                              ? 'This revision contains material modifications (budget shift ≥10%, reach variance >15%, or flight date shift >72h). Under governance rule BR-004, prior approvals are invalidated and the review pipeline is reset to Stage 1 (Creative & Brand).'
                              : 'All modified fields are within non-material governance boundaries. Prior stage approvals remain preserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Feedback Addressed Summary
            if (diff.reviewerFeedbackAddressed != null) ...[
              Text(
                'FEEDBACK ADDRESSED IN THIS REVISION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 6),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply_rounded, size: 16, color: AppColors.defenseGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${diff.reviewerFeedbackAddressed}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Snapshot Hashes Comparison
            Text(
              'CRYPTOGRAPHIC SNAPSHOT FINGERPRINTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
            const SizedBox(height: 6),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHashRow('v${diff.previousVersion} SHA-256', diff.previousSnapshotHash, isDark),
                  const SizedBox(height: 8),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                  const SizedBox(height: 8),
                  _buildHashRow('v${diff.currentVersion} SHA-256', diff.currentSnapshotHash, isDark),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Field Diffs List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MODIFIED ATTRIBUTES (${diff.diffs.length})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
                Text(
                  'v${diff.previousVersion} (Old) → v${diff.currentVersion} (New)',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...diff.diffs.map((fieldDiff) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FieldDiffTile(
                  fieldName: fieldDiff.fieldName,
                  oldValue: fieldDiff.oldValue,
                  newValue: fieldDiff.newValue,
                  isMaterial: fieldDiff.isMaterial,
                  rationale: fieldDiff.rationale,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHashRow(String label, String hash, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hash,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Courier',
            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
