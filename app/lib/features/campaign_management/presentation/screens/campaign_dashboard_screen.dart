import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/empty_state_view.dart';
import '../../../../core/design_system/widgets/status_badge.dart';
import '../../../../core/models/campaign_state.dart';
import '../../domain/campaign_entity.dart';
import '../providers/campaign_providers.dart';
import 'campaign_detail_screen.dart';
import 'create_campaign_screen.dart';

class CampaignDashboardScreen extends ConsumerWidget {
  const CampaignDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCampaignsAsync = ref.watch(campaignListProvider);
    final filteredCampaignsAsync = ref.watch(filteredCampaignsProvider);
    final activeFilterTab = ref.watch(campaignFilterTabProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(campaignListProvider.notifier).refresh(),
        color: AppColors.defenseGreen,
        child: CustomScrollView(
          slivers: [
            // Header & KPI Metrics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAMPAIGN OPERATIONS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Campaign Governance',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quick Add Button
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateCampaignScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New Campaign'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.defenseGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // KPI Metrics Row
                    allCampaignsAsync.when(
                      data: (campaigns) => _buildKpiRow(context, campaigns),
                      loading: () => const SizedBox(
                        height: 72,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (err, _) => Text('Error loading metrics: $err'),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Search input
                    TextField(
                      onChanged: (query) {
                        ref.read(campaignSearchQueryProvider.notifier).state = query;
                      },
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search campaigns by name, ID, or cost center...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.defenseGreen, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Filter tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: CampaignFilterTab.values.map((tab) {
                          final isSelected = activeFilterTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(tab.label),
                              selected: isSelected,
                              onSelected: (_) {
                                ref.read(campaignFilterTabProvider.notifier).state = tab;
                              },
                              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              selectedColor: AppColors.defenseGreen.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.defenseGreen
                                    : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.defenseGreen
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Campaigns List
            filteredCampaignsAsync.when(
              data: (campaigns) {
                if (campaigns.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No Campaigns Found',
                      message: 'Try adjusting your search query or switching the status filter.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final campaign = campaigns[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CampaignItemCard(
                            campaign: campaign,
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
                      childCount: campaigns.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.defenseGreen),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Failed to load campaigns: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, List<Campaign> campaigns) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = campaigns.length;
    final pending = campaigns.where((c) => c.state == CampaignState.pendingReview).length;
    final changesReq = campaigns.where((c) => c.state == CampaignState.changesRequested).length;
    final approved = campaigns.where((c) => c.state == CampaignState.approved || c.state == CampaignState.scheduled).length;

    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            title: 'TOTAL',
            count: total.toString(),
            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            title: 'PENDING',
            count: pending.toString(),
            color: AppColors.statePending,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            title: 'CHANGES',
            count: changesReq.toString(),
            color: AppColors.stateChangesReq,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            title: 'APPROVED',
            count: approved.toString(),
            color: AppColors.defenseGreen,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _KpiTile({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignItemCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const _CampaignItemCard({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('MMM dd, yyyy');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: ID, Version tag, and Status Badge
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
          const SizedBox(height: 10),

          // Title
          Text(
            campaign.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Objective excerpt
          Text(
            campaign.objective,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 10),

          // Metadata Footer
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 14,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              const SizedBox(width: 4),
              Text(
                campaign.budget.formattedAmount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.defenseGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Tier ${campaign.budget.doaTier}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.defenseGreen,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              const SizedBox(width: 4),
              Text(
                campaign.submittedByName,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Schedule info
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              const SizedBox(width: 4),
              Text(
                'Flight: ${dateFmt.format(campaign.schedule.startDate)} – ${dateFmt.format(campaign.schedule.endDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const Spacer(),
              Text(
                campaign.currentStageName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.defenseGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
