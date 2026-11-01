import 'package:flutter/material.dart';
import '../../models/campaign_state.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class StatusBadge extends StatelessWidget {
  final CampaignState state;
  final int? stageIndex; // 1: Creative, 2: Compliance, 3: Finance
  final bool isDense;

  const StatusBadge({
    super.key,
    required this.state,
    this.stageIndex,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (state) {
      case CampaignState.draft:
        bg = AppColors.stateDraftBg;
        fg = AppColors.stateDraftText;
        icon = Icons.edit_note_rounded;
        label = 'Draft';
        break;

      case CampaignState.pendingReview:
        bg = AppColors.statePendingBg;
        fg = AppColors.statePendingText;
        icon = Icons.schedule_rounded;
        if (stageIndex == 1) {
          label = 'Pending: Creative (S1)';
        } else if (stageIndex == 2) {
          label = 'Pending: Compliance (S2)';
        } else if (stageIndex == 3) {
          label = 'Pending: Finance (S3)';
        } else {
          label = 'Pending Review';
        }
        break;

      case CampaignState.changesRequested:
        bg = AppColors.stateChangesReqBg;
        fg = AppColors.stateChangesReqText;
        icon = Icons.rate_review_outlined;
        label = 'Changes Requested';
        break;

      case CampaignState.approved:
        bg = AppColors.stateApprovedBg;
        fg = AppColors.stateApprovedText;
        icon = Icons.check_circle_rounded;
        label = 'Approved';
        break;

      case CampaignState.scheduled:
        bg = AppColors.stateScheduledBg;
        fg = AppColors.stateScheduledText;
        icon = Icons.event_available_rounded;
        label = 'Scheduled';
        break;

      case CampaignState.rejected:
        bg = AppColors.stateRejectedBg;
        fg = AppColors.stateRejectedText;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? 8.0 : 10.0,
        vertical: isDense ? 3.0 : 5.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderPill,
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDense ? 12 : 14, color: fg),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: AppTypography.labelBadge.copyWith(
              color: fg,
              fontSize: isDense ? 10.5 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

