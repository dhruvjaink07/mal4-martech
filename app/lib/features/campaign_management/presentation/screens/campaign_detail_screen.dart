import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_button.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/stage_progress_bar.dart';
import '../../../../core/design_system/widgets/status_badge.dart';
import '../../../../core/providers/persona_provider.dart';
import '../../domain/campaign_entity.dart';
import '../../domain/campaign_repository.dart';
import '../providers/campaign_providers.dart';
import '../../../multi_stage_review/presentation/widgets/review_action_sheet.dart';
import '../../../revision_and_diff/presentation/screens/structured_diff_viewer_screen.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final approvalsAsync = ref.watch(stageApprovalsProvider(campaignId));
    final diffAsync = ref.watch(campaignLatestDiffProvider(campaignId));
    final activePersona = ref.watch(currentPersonaProvider);

    return campaignAsync.when(
      data: (campaign) {
        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Campaign Detail')),
            body: const Center(child: Text('Campaign not found.')),
          );
        }

        final isAuthor = activePersona.id == campaign.submittedById;
        final isAuthorReviewRestricted = isAuthor && campaign.isPendingReview;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${campaign.id.toUpperCase()} • v${campaign.version}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Courier',
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
                Text(
                  campaign.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
                // Top Status & Stage Progress Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(state: campaign.state, stageIndex: campaign.stageIndex),
                          const Spacer(),
                          Text(
                            'Active: ${campaign.currentStageName}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StageProgressBar(
                        state: campaign.state,
                        currentStage: campaign.stageIndex,
                        version: campaign.version,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Invariant: Anti-Self-Approval Banner
                if (isAuthorReviewRestricted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      backgroundColor: AppColors.stateChangesReq.withValues(alpha: 0.1),
                      borderColor: AppColors.stateChangesReq.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.gavel_rounded, color: AppColors.stateChangesReq, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ANTI-SELF-APPROVAL ENFORCED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.stateChangesReq,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'You created this proposal as ${campaign.submittedByName}. Under Segregation of Duties (SoD) governance, you cannot approve your own submission.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Changes Requested Banner
                if (campaign.isChangesRequested)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      backgroundColor: AppColors.defenseRed.withValues(alpha: 0.08),
                      borderColor: AppColors.defenseRed.withValues(alpha: 0.4),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.defenseRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ACTION REQUIRED: CHANGES REQUESTED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.defenseRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'A reviewer requested changes on version v${campaign.version}. Click "Revise Campaign" below to update and resubmit.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Revision Diff button (if diff available)
                diffAsync.when(
                  data: (diff) {
                    if (diff == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StructuredDiffViewerScreen(diff: diff),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          borderColor: AppColors.defenseGreen.withValues(alpha: 0.5),
                          child: Row(
                            children: [
                              const Icon(Icons.difference_outlined, color: AppColors.defenseGreen, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STRUCTURED REVISION DIFF AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Compare v${diff.previousVersion} vs v${diff.currentVersion} (${diff.diffs.length} modified fields)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.defenseGreen),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Bento Section 1: Campaign Overview
                _buildSectionTitle('CAMPAIGN DETAILS', isDark),
                const SizedBox(height: 6),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        campaign.objective,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 14, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted by ${campaign.submittedByName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time_rounded, size: 14, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(campaign.updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Bento Section 2: Budget & DOA Governance
                _buildSectionTitle('BUDGET & FINANCIAL GOVERNANCE', isDark),
                const SizedBox(height: 6),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL BUDGET',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                campaign.budget.formattedAmount,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.defenseGreen,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.defenseGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.defenseGreen.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'DOA TIER ${campaign.budget.doaTier}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.defenseGreen,
                                  ),
                                ),
                                Text(
                                  campaign.budget.doaTierLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Cost Center:',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            campaign.budget.costCenter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Bento Section 3: Audience & Flight Window
                _buildSectionTitle('AUDIENCE & FLIGHT WINDOW', isDark),
                const SizedBox(height: 6),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TARGET AUDIENCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  campaign.audience.segmentName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ESTIMATED REACH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                campaign.audience.formattedReach,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'CHANNELS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: campaign.audience.channels.map((ch) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Text(
                              ch,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff_rounded, size: 14, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          const SizedBox(width: 4),
                          Text(
                            'Flight Window (${campaign.schedule.durationDays} Days):',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            campaign.schedule.formattedRange,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Bento Section 4: Cryptographic Integrity
                _buildSectionTitle('CRYPTOGRAPHIC SNAPSHOT INTEGRITY', isDark),
                const SizedBox(height: 6),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security_rounded, size: 16, color: AppColors.defenseGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SNAPSHOT HASH (SHA-256)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Copy hash',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: campaign.snapshotHash));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Snapshot SHA-256 hash copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          campaign.snapshotHash,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Courier',
                            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Bento Section 5: Stage Approvals History
                _buildSectionTitle('STAGE APPROVAL AUDIT TRAIL', isDark),
                const SizedBox(height: 6),
                approvalsAsync.when(
                  data: (approvals) {
                    if (approvals.isEmpty) {
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: Text(
                            'No approvals recorded yet for v${campaign.version}.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: approvals.map((appr) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.defenseGreen, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appr.stageTitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Verified by ${appr.reviewerName} (${appr.reviewerRole}) • ${DateFormat('MMM dd, HH:mm').format(appr.approvedAt)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                        ),
                                      ),
                                      if (appr.notes != null && appr.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '"${appr.notes}"',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
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
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 80), // spacing for bottom bar
              ],
            ),
          ),

          // Contextual Bottom Action Bar
          bottomNavigationBar: _buildBottomActionBar(context, ref, campaign, activePersona, isAuthorReviewRestricted),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.defenseGreen)),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error loading campaign: $err')),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    Campaign campaign,
    dynamic activePersona,
    bool isAuthorReviewRestricted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: _resolveBottomAction(context, ref, campaign, activePersona, isAuthorReviewRestricted),
      ),
    );
  }

  Widget _resolveBottomAction(
    BuildContext context,
    WidgetRef ref,
    Campaign campaign,
    dynamic activePersona,
    bool isAuthorReviewRestricted,
  ) {
    // State: Draft
    if (campaign.isDraft) {
      return AppButton(
        label: 'Submit for Stage 1 Review',
        variant: AppButtonVariant.primary,
        onPressed: () async {
          await ref.read(campaignListProvider.notifier).submitForReview(
                campaign.id,
                campaign.version,
                activePersona.id,
                activePersona.name,
              );
          ref.invalidate(campaignDetailProvider(campaign.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Campaign submitted to Stage 1!'),
                backgroundColor: AppColors.defenseGreen,
              ),
            );
          }
        },
      );
    }

    // State: Pending Review
    if (campaign.isPendingReview) {
      if (isAuthorReviewRestricted) {
        return const AppButton(
          label: 'Review Locked (Author Anti-Self-Approval)',
          variant: AppButtonVariant.secondary,
          onPressed: null, // Disabled
        );
      }

      return AppButton(
        label: 'Review ${campaign.currentStageName}',
        variant: AppButtonVariant.primary,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ReviewActionSheet(campaign: campaign),
          );
        },
      );
    }

    // State: Changes Requested
    if (campaign.isChangesRequested) {
      return AppButton(
        label: 'Revise & Resubmit Proposal (v${campaign.version + 1})',
        variant: AppButtonVariant.primary,
        onPressed: () {
          _showRevisionDialog(context, ref, campaign, activePersona);
        },
      );
    }

    // State: Approved
    if (campaign.isApproved) {
      return AppButton(
        label: 'Execute Scheduling Gate (DSP Distribution)',
        variant: AppButtonVariant.primary,
        onPressed: () async {
          await ref.read(campaignListProvider.notifier).scheduleCampaign(
                campaignId: campaign.id,
                expectedVersion: campaign.version,
                actorId: activePersona.id,
                actorName: activePersona.name,
              );
          ref.invalidate(campaignDetailProvider(campaign.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scheduling gate verified! Campaign locked for automated execution.'),
                backgroundColor: AppColors.defenseGreen,
              ),
            );
          }
        },
      );
    }

    // State: Scheduled
    if (campaign.isScheduled) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_rounded, size: 16, color: AppColors.defenseGreen),
          SizedBox(width: 8),
          Text(
            'Campaign Locked & Scheduled for Distribution',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.defenseGreen,
            ),
          ),
        ],
      );
    }

    // State: Rejected
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.cancel_rounded, size: 16, color: AppColors.defenseRed),
        SizedBox(width: 8),
        Text(
          'Campaign Terminated (Rejected)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.defenseRed,
          ),
        ),
      ],
    );
  }

  void _showRevisionDialog(BuildContext context, WidgetRef ref, Campaign campaign, dynamic activePersona) {
    final feedbackController = TextEditingController(
      text: 'Updated compliance disclosure copy and aligned terms with legal feedback.',
    );
    final budgetController = TextEditingController(text: campaign.budget.amount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Revise Campaign (v${campaign.version} → v${campaign.version + 1})'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submitting a revision generates a new cryptographic snapshot (vN+1). If budget, reach, or flight window changes materially, the pipeline resets to Stage 1 (Creative & Brand).',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: feedbackController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Reviewer Feedback Addressed',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().length < 5 ? 'Explain changes made' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Revised Budget (USD)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) return 'Valid budget required';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.defenseGreen),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogCtx).pop();

                final revisedBudget = double.parse(budgetController.text);
                final input = CampaignDraftInput(
                  name: campaign.name,
                  objective: campaign.objective,
                  amount: revisedBudget,
                  currency: campaign.budget.currency,
                  costCenter: campaign.budget.costCenter,
                  segmentName: campaign.audience.segmentName,
                  targetRegions: campaign.audience.targetRegions,
                  channels: campaign.audience.channels,
                  estimatedReach: campaign.audience.estimatedReach,
                  startDate: campaign.schedule.startDate,
                  endDate: campaign.schedule.endDate,
                  assetLinks: campaign.assetLinks,
                );

                await ref.read(campaignListProvider.notifier).reviseAndResubmit(
                      campaignId: campaign.id,
                      expectedVersion: campaign.version,
                      input: input,
                      submitterId: activePersona.id,
                      submitterName: activePersona.name,
                      feedbackAddressed: feedbackController.text.trim(),
                    );

                ref.invalidate(campaignDetailProvider(campaign.id));
                ref.invalidate(campaignLatestDiffProvider(campaign.id));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Revision submitted! Version bumped to v2 and reset to Stage 1.'),
                      backgroundColor: AppColors.defenseGreen,
                    ),
                  );
                }
              },
              child: const Text('Resubmit v2'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
      ),
    );
  }
}
