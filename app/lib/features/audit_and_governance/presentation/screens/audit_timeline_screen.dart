import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/empty_state_view.dart';
import '../../../campaign_management/domain/campaign_entity.dart';
import '../../../campaign_management/presentation/providers/campaign_providers.dart';
import '../../../campaign_management/presentation/screens/campaign_detail_screen.dart';

class AuditTimelineScreen extends ConsumerStatefulWidget {
  const AuditTimelineScreen({super.key});

  @override
  ConsumerState<AuditTimelineScreen> createState() => _AuditTimelineScreenState();
}

class _AuditTimelineScreenState extends ConsumerState<AuditTimelineScreen> {
  String _selectedActionFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auditEventsAsync = ref.watch(allAuditEventsProvider);

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
                      'IMMUTABLE GOVERNANCE LOG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cryptographic Audit Trail',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every stage evaluation, revision, and scheduling gate is permanently recorded with canonical SHA-256 digests.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('APPROVALS', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('CHANGES', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('REVISIONS', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('SCHEDULED', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Timeline stream
            auditEventsAsync.when(
              data: (events) {
                var filtered = events;
                if (_selectedActionFilter == 'APPROVALS') {
                  filtered = filtered.where((e) => e.action.contains('APPROVED')).toList();
                } else if (_selectedActionFilter == 'CHANGES') {
                  filtered = filtered.where((e) => e.action.contains('CHANGES')).toList();
                } else if (_selectedActionFilter == 'REVISIONS') {
                  filtered = filtered.where((e) => e.action.contains('REVISED')).toList();
                } else if (_selectedActionFilter == 'SCHEDULED') {
                  filtered = filtered.where((e) => e.action.contains('SCHEDULED')).toList();
                }

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.history_edu_rounded,
                      title: 'No Matching Events',
                      message: 'No audit records match the selected action filter.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _AuditEventCard(
                            event: event,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CampaignDetailScreen(campaignId: event.campaignId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.defenseGreen)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Failed to load audit events: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedActionFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedActionFilter = label);
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

class _AuditEventCard extends StatelessWidget {
  final AuditEvent event;
  final VoidCallback onTap;

  const _AuditEventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('MMM dd, yyyy HH:mm:ss');

    Color actionColor;
    IconData actionIcon;

    if (event.action.contains('APPROVED')) {
      actionColor = AppColors.defenseGreen;
      actionIcon = Icons.check_circle_rounded;
    } else if (event.action.contains('CHANGES')) {
      actionColor = AppColors.stateChangesReq;
      actionIcon = Icons.edit_note_rounded;
    } else if (event.action.contains('REJECTED')) {
      actionColor = AppColors.defenseRed;
      actionIcon = Icons.cancel_rounded;
    } else if (event.action.contains('SCHEDULED')) {
      actionColor = AppColors.stateScheduled;
      actionIcon = Icons.lock_clock_rounded;
    } else if (event.action.contains('REVISED')) {
      actionColor = const Color(0xFF8B5CF6);
      actionIcon = Icons.difference_rounded;
    } else {
      actionColor = AppColors.statePending;
      actionIcon = Icons.send_rounded;
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Badge & Timestamp
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: actionColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(actionIcon, size: 13, color: actionColor),
                    const SizedBox(width: 4),
                    Text(
                      event.action,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: actionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                dateFmt.format(event.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Courier',
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Campaign Reference
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${event.campaignId.toUpperCase()} • v${event.versionNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Courier',
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${event.previousState} → ${event.newState}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details / Feedback text
          Text(
            event.details,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),

          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 8),

          // Actor & Hash snippet
          Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 14, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${event.actorName} (${event.actorRole})',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SHA: ${event.snapshotHash.substring(0, 8)}...',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Courier',
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

