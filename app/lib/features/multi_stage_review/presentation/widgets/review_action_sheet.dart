import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_button.dart';
import '../../../../core/design_system/widgets/app_text_field.dart';
import '../../../../core/providers/persona_provider.dart';
import '../../../campaign_management/domain/campaign_entity.dart';
import '../../../campaign_management/presentation/providers/campaign_providers.dart';

import '../../../../core/models/mock_persona.dart';

enum ReviewDecisionMode { approve, requestChanges, reject }

class ReviewActionSheet extends ConsumerStatefulWidget {
  final Campaign campaign;

  const ReviewActionSheet({super.key, required this.campaign});

  @override
  ConsumerState<ReviewActionSheet> createState() => _ReviewActionSheetState();
}

class _ReviewActionSheetState extends ConsumerState<ReviewActionSheet> {
  ReviewDecisionMode _mode = ReviewDecisionMode.approve;
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  bool _isPersonaAuthorizedForStage(MockPersona persona, int stageIndex) {
    if (persona.role == UserRole.administrator) return true;
    return persona.authorizedStage == stageIndex;
  }

  Future<void> _executeDecision() async {
    if (_mode != ReviewDecisionMode.approve && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final activePersona = ref.read(currentPersonaProvider);
    final notifier = ref.read(campaignListProvider.notifier);

    try {
      if (_mode == ReviewDecisionMode.approve) {
        await notifier.advanceStage(
          campaignId: widget.campaign.id,
          expectedVersion: widget.campaign.version,
          currentStage: widget.campaign.stageIndex,
          reviewerId: activePersona.id,
          reviewerName: activePersona.name,
          reviewerRole: activePersona.title,
          notes: _feedbackController.text.trim().isNotEmpty ? _feedbackController.text.trim() : null,
        );
      } else if (_mode == ReviewDecisionMode.requestChanges) {
        await notifier.requestChanges(
          campaignId: widget.campaign.id,
          expectedVersion: widget.campaign.version,
          currentStage: widget.campaign.stageIndex,
          reviewerId: activePersona.id,
          reviewerName: activePersona.name,
          feedback: _feedbackController.text.trim(),
        );
      } else {
        await notifier.rejectCampaign(
          campaignId: widget.campaign.id,
          expectedVersion: widget.campaign.version,
          currentStage: widget.campaign.stageIndex,
          reviewerId: activePersona.id,
          reviewerName: activePersona.name,
          reason: _feedbackController.text.trim(),
        );
      }

      ref.invalidate(campaignDetailProvider(widget.campaign.id));
      ref.invalidate(stageApprovalsProvider(widget.campaign.id));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _mode == ReviewDecisionMode.approve
                  ? 'Stage ${widget.campaign.stageIndex} approved successfully!'
                  : _mode == ReviewDecisionMode.requestChanges
                      ? 'Changes requested on campaign proposal.'
                      : 'Campaign rejected and terminated.',
            ),
            backgroundColor: _mode == ReviewDecisionMode.approve
                ? AppColors.defenseGreen
                : _mode == ReviewDecisionMode.requestChanges
                    ? AppColors.stateChangesReq
                    : AppColors.defenseRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppColors.defenseRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePersona = ref.watch(currentPersonaProvider);
    final isAuthor = activePersona.id == widget.campaign.submittedById;
    final isAuthorized = _isPersonaAuthorizedForStage(activePersona, widget.campaign.stageIndex);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GATE EVALUATION: ${widget.campaign.currentStageName.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review Decision Sheet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Evaluator Persona Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: isAuthorized ? AppColors.defenseGreen : AppColors.stateChangesReq,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evaluating as: ${activePersona.name} (${activePersona.title})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                    ),
                  ),
                  if (!isAuthorized)
                    const Text(
                      'Cross-role mode',
                      style: TextStyle(fontSize: 10, color: AppColors.stateChangesReq),
                    ),
                ],
              ),
            ),

            // Anti-Self-Approval Guard
            if (isAuthor) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.defenseRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.defenseRed.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: AppColors.defenseRed, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Violation: You cannot evaluate or approve your own proposal. Please switch personas above to a designated reviewer.',
                        style: TextStyle(fontSize: 11, color: AppColors.defenseRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Decision Selector (Approve / Request Changes / Reject)
            Row(
              children: [
                Expanded(
                  child: _DecisionOption(
                    title: 'Approve',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.defenseGreen,
                    isSelected: _mode == ReviewDecisionMode.approve,
                    onTap: isAuthor ? null : () => setState(() => _mode = ReviewDecisionMode.approve),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DecisionOption(
                    title: 'Request Changes',
                    icon: Icons.edit_note_rounded,
                    color: AppColors.stateChangesReq,
                    isSelected: _mode == ReviewDecisionMode.requestChanges,
                    onTap: isAuthor ? null : () => setState(() => _mode = ReviewDecisionMode.requestChanges),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DecisionOption(
                    title: 'Reject',
                    icon: Icons.cancel_outlined,
                    color: AppColors.defenseRed,
                    isSelected: _mode == ReviewDecisionMode.reject,
                    onTap: isAuthor ? null : () => setState(() => _mode = ReviewDecisionMode.reject),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Feedback / Notes input
            AppTextField(
              label: _mode == ReviewDecisionMode.approve
                  ? 'Approval Notes (Optional)'
                  : _mode == ReviewDecisionMode.requestChanges
                      ? 'Required Change Feedback'
                      : 'Required Rejection Rationale',
              hint: _mode == ReviewDecisionMode.approve
                  ? 'Add observations or approval reference...'
                  : 'Specify exact modifications required before re-evaluation...',
              controller: _feedbackController,
              maxLines: 3,
              validator: (val) {
                if (_mode != ReviewDecisionMode.approve) {
                  if (val == null || val.trim().length < 10) {
                    return 'Feedback must be at least 10 characters';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            AppButton(
              label: isAuthor
                  ? 'Disabled (Anti-Self-Approval)'
                  : _mode == ReviewDecisionMode.approve
                      ? 'Confirm Stage ${widget.campaign.stageIndex} Approval'
                      : _mode == ReviewDecisionMode.requestChanges
                          ? 'Send Changes Requested'
                          : 'Confirm Proposal Rejection',
              variant: _mode == ReviewDecisionMode.reject
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
              isLoading: _isSubmitting,
              onPressed: isAuthor ? null : _executeDecision,
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DecisionOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText), size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : (isDark ? AppColors.darkForeground : AppColors.lightForeground),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
