import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_button.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/empty_state_view.dart';
import '../../../../core/design_system/widgets/status_badge.dart';
import '../../../../core/models/campaign_state.dart';
import '../../../../core/models/mock_persona.dart';
import '../../../../core/providers/persona_provider.dart';
import '../../../campaign_management/domain/campaign_entity.dart';
import '../../../campaign_management/presentation/providers/campaign_providers.dart';
import '../../../campaign_management/presentation/screens/campaign_detail_screen.dart';
import '../widgets/review_action_sheet.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  int? _selectedStageFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePersona = ref.watch(currentPersonaProvider);
    final campaignsAsync = ref.watch(campaignListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(campaignListProvider.notifier).refresh(),
        color: AppColors.defenseGreen,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GATE EVALUATION QUEUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pending Approvals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Active Persona Queue Attribution Banner
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      backgroundColor: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 18,
                            color: activePersona.authorizedStage != null
                                ? AppColors.defenseGreen
                                : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activePersona.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                  ),
                                ),
                                Text(
                                  activePersona.authorizedStage != null
                                      ? 'Designated Reviewer: Stage ${activePersona.authorizedStage}'
                                      : 'System Role: ${activePersona.title}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Stage filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStageFilterChip('All Pending', null, isDark),
                          const SizedBox(width: 6),
                          _buildStageFilterChip('Stage 1 (Creative)', 1, isDark),
                          const SizedBox(width: 6),
                          _buildStageFilterChip('Stage 2 (Legal)', 2, isDark),
                          const SizedBox(width: 6),
                          _buildStageFilterChip('Stage 3 (Finance)', 3, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Queue List
            campaignsAsync.when(
              data: (allCampaigns) {
                // Filter only pending review campaigns
                var pending = allCampaigns.where((c) => c.state == CampaignState.pendingReview).toList();

                if (_selectedStageFilter != null) {
                  pending = pending.where((c) => c.stageIndex == _selectedStageFilter).toList();
                }

                if (pending.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Queue Cleared',
                      message: 'No campaigns are currently waiting for stage approval.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final campaign = pending[index];
                        final isAuthor = activePersona.id == campaign.submittedById;
                        final isDesignatedStage = activePersona.authorizedStage == campaign.stageIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ReviewQueueCard(
                            campaign: campaign,
                            isAuthor: isAuthor,
                            isDesignatedStage: isDesignatedStage,
                            activePersona: activePersona,
                            onReview: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ReviewActionSheet(campaign: campaign),
                              );
                            },
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CampaignDetailScreen(campaignId: campaign.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: pending.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.defenseGreen)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error loading queue: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageFilterChip(String label, int? stage, bool isDark) {
    final isSelected = _selectedStageFilter == stage;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStageFilter = stage);
      },
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      selectedColor: AppColors.defenseGreen.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.defenseGreen : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.defenseGreen : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}

class _ReviewQueueCard extends StatelessWidget {
  final Campaign campaign;
  final bool isAuthor;
  final bool isDesignatedStage;
  final MockPersona activePersona;
  final VoidCallback onReview;
  final VoidCallback onTap;

  const _ReviewQueueCard({
    required this.campaign,
    required this.isAuthor,
    required this.isDesignatedStage,
    required this.activePersona,
    required this.onReview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID and Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${campaign.id.toUpperCase()} • v${campaign.version}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Courier',
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(
                state: campaign.state,
                stageIndex: campaign.stageIndex,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            campaign.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: 6),

          // Submitter & Stage
          Row(
            children: [
              Text(
                'Submitted by: ${campaign.submittedByName}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const Spacer(),
              Text(
                campaign.budget.formattedAmount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 10),

          // Action row
          if (isAuthor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.defenseRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, size: 14, color: AppColors.defenseRed),
                  SizedBox(width: 6),
                  Text(
                    'Author Anti-Self-Approval: Locked',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.defenseRed),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                if (isDesignatedStage)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.defenseGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Assigned to Your Stage',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.defenseGreen),
                    ),
                  ),
                const Spacer(),
                AppButton(
                  label: 'Review Decision',
                  variant: ButtonVariant.primary,
                  height: 36,
                  onPressed: onReview,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

