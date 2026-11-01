import 'package:flutter/material.dart';
import '../../models/campaign_state.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class StageProgressBar extends StatelessWidget {
  final CampaignState state;
  final int currentStage; // 1, 2, or 3
  final int version;

  const StageProgressBar({
    super.key,
    required this.state,
    required this.currentStage,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppSpacing.borderLg,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'APPROVAL PIPELINE',
                style: AppTypography.labelUppercase.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
                  borderRadius: AppSpacing.borderSm,
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'Snapshot v$version',
                  style: AppTypography.codeMedium.copyWith(
                    fontSize: 11.0,
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: _buildStageNode(
                  stageNum: 1,
                  title: 'Creative',
                  subtitle: 'Brand Voice',
                  context: context,
                ),
              ),
              _buildConnector(1, context),
              Expanded(
                child: _buildStageNode(
                  stageNum: 2,
                  title: 'Compliance',
                  subtitle: 'Legal & GDPR',
                  context: context,
                ),
              ),
              _buildConnector(2, context),
              Expanded(
                child: _buildStageNode(
                  stageNum: 3,
                  title: 'Finance',
                  subtitle: 'SOX & Budget',
                  context: context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int afterStage, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isPassed = false;

    if (state == CampaignState.approved || state == CampaignState.scheduled) {
      isPassed = true;
    } else if (state == CampaignState.pendingReview && currentStage > afterStage) {
      isPassed = true;
    }

    final color = isPassed
        ? AppColors.defenseGreen
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      width: 18.0,
      height: 2.0,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }

  Widget _buildStageNode({
    required int stageNum,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconBg;
    Color iconFg;
    Widget iconChild;
    Color titleColor;

    if (state == CampaignState.approved || state == CampaignState.scheduled) {
      iconBg = AppColors.defenseGreen;
      iconFg = Colors.white;
      iconChild = const Icon(Icons.check, size: 14, color: Colors.white);
      titleColor = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    } else if (state == CampaignState.pendingReview) {
      if (currentStage > stageNum) {
        iconBg = AppColors.defenseGreen;
        iconFg = Colors.white;
        iconChild = const Icon(Icons.check, size: 14, color: Colors.white);
        titleColor = isDark ? AppColors.darkForeground : AppColors.lightForeground;
      } else if (currentStage == stageNum) {
        iconBg = AppColors.defenseGreen.withValues(alpha: 0.15);
        iconFg = AppColors.defenseGreen;
        iconChild = Text('$stageNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11));
        titleColor = AppColors.defenseGreen;
      } else {
        iconBg = isDark ? AppColors.darkElevated : AppColors.lightElevated;
        iconFg = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
        iconChild = Text('$stageNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: iconFg));
        titleColor = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
      }
    } else if (state == CampaignState.changesRequested && currentStage == stageNum) {
      iconBg = AppColors.stateChangesReqBg;
      iconFg = AppColors.stateChangesReqText;
      iconChild = const Icon(Icons.priority_high, size: 14, color: AppColors.stateChangesReqText);
      titleColor = AppColors.stateChangesReqText;
    } else if (state == CampaignState.rejected && currentStage == stageNum) {
      iconBg = AppColors.defenseRed;
      iconFg = Colors.white;
      iconChild = const Icon(Icons.close, size: 14, color: Colors.white);
      titleColor = AppColors.defenseRed;
    } else {
      iconBg = isDark ? AppColors.darkElevated : AppColors.lightElevated;
      iconFg = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
      iconChild = Text('$stageNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: iconFg));
      titleColor = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: Border.all(color: iconFg.withValues(alpha: 0.5), width: 1.0),
          ),
          alignment: Alignment.center,
          child: iconChild,
        ),
        const SizedBox(height: 4.0),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 12.0,
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10.0,
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

