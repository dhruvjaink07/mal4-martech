import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/campaign_state.dart';
import '../../data/mock_campaign_repository.dart';
import '../../domain/campaign_entity.dart';
import '../../domain/campaign_repository.dart';

final campaignRepositoryProvider = Provider<MockCampaignRepository>((ref) {
  return MockCampaignRepository();
});

enum CampaignFilterTab {
  all('All'),
  pending('Pending Review'),
  changesRequested('Changes Req'),
  approved('Approved');

  final String label;
  const CampaignFilterTab(this.label);
}

final campaignFilterTabProvider = StateProvider<CampaignFilterTab>((ref) {
  return CampaignFilterTab.all;
});

final campaignSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Manages the list of campaigns with live search and category filtering
class CampaignListNotifier extends AsyncNotifier<List<Campaign>> {
  @override
  Future<List<Campaign>> build() async {
    final repository = ref.watch(campaignRepositoryProvider);
    return repository.getCampaigns();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(campaignRepositoryProvider);
      return repository.getCampaigns();
    });
  }

  Future<Campaign> createDraft(CampaignDraftInput input, String creatorId, String creatorName) async {
    final repository = ref.read(campaignRepositoryProvider);
    final created = await repository.createDraft(input, creatorId, creatorName);
    await refresh();
    return created;
  }

  Future<Campaign> submitForReview(String campaignId, int expectedVersion, String submitterId, String submitterName) async {
    final repository = ref.read(campaignRepositoryProvider);
    final updated = await repository.submitForReview(campaignId, expectedVersion, submitterId, submitterName);
    await refresh();
    return updated;
  }

  Future<Campaign> advanceStage({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String reviewerRole,
    String? notes,
  }) async {
    final repository = ref.read(campaignRepositoryProvider);
    final updated = await repository.advanceStage(
      campaignId: campaignId,
      expectedVersion: expectedVersion,
      currentStage: currentStage,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerRole: reviewerRole,
      notes: notes,
    );
    await refresh();
    return updated;
  }

  Future<Campaign> requestChanges({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String feedback,
  }) async {
    final repository = ref.read(campaignRepositoryProvider);
    final updated = await repository.requestChanges(
      campaignId: campaignId,
      expectedVersion: expectedVersion,
      currentStage: currentStage,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      feedback: feedback,
    );
    await refresh();
    return updated;
  }

  Future<Campaign> rejectCampaign({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String reason,
  }) async {
    final repository = ref.read(campaignRepositoryProvider);
    final updated = await repository.rejectCampaign(
      campaignId: campaignId,
      expectedVersion: expectedVersion,
      currentStage: currentStage,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reason: reason,
    );
    await refresh();
    return updated;
  }

  Future<Campaign> reviseAndResubmit({
    required String campaignId,
    required int expectedVersion,
    required CampaignDraftInput input,
    required String submitterId,
    required String submitterName,
    required String feedbackAddressed,
  }) async {
    final repository = ref.read(campaignRepositoryProvider);
    final updated = await repository.reviseAndResubmit(
      campaignId: campaignId,
      expectedVersion: expectedVersion,
      input: input,
      submitterId: submitterId,
      submitterName: submitterName,
      feedbackAddressed: feedbackAddressed,
    );
    await refresh();
    return updated;
  }

  Future<Campaign> scheduleCampaign({
    required String campaignId,
    required int expectedVersion,
    required String actorId,
    required String actorName,
  }) async {
    final repository = ref.read(campaignRepositoryProvider);
    final updated = await repository.scheduleCampaign(
      campaignId: campaignId,
      expectedVersion: expectedVersion,
      actorId: actorId,
      actorName: actorName,
    );
    await refresh();
    return updated;
  }
}

final campaignListProvider = AsyncNotifierProvider<CampaignListNotifier, List<Campaign>>(() {
  return CampaignListNotifier();
});

/// Filtered campaigns based on active filter tab and search query
final filteredCampaignsProvider = Provider<AsyncValue<List<Campaign>>>((ref) {
  final campaignsAsync = ref.watch(campaignListProvider);
  final filterTab = ref.watch(campaignFilterTabProvider);
  final searchQuery = ref.watch(campaignSearchQueryProvider).trim().toLowerCase();

  return campaignsAsync.whenData((campaigns) {
    var filtered = campaigns;

    switch (filterTab) {
      case CampaignFilterTab.all:
        break;
      case CampaignFilterTab.pending:
        filtered = filtered.where((c) => c.state == CampaignState.pendingReview).toList();
        break;
      case CampaignFilterTab.changesRequested:
        filtered = filtered.where((c) => c.state == CampaignState.changesRequested).toList();
        break;
      case CampaignFilterTab.approved:
        filtered = filtered.where((c) => c.state == CampaignState.approved || c.state == CampaignState.scheduled).toList();
        break;
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(searchQuery) ||
            c.id.toLowerCase().contains(searchQuery) ||
            c.submittedByName.toLowerCase().contains(searchQuery) ||
            c.budget.costCenter.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return filtered;
  });
});

/// Provider for single campaign details
final campaignDetailProvider = FutureProvider.family<Campaign?, String>((ref, id) async {
  ref.watch(campaignListProvider); // invalidate when campaigns change
  final repository = ref.watch(campaignRepositoryProvider);
  return repository.getCampaignById(id);
});

/// Provider for stage approvals of a campaign
final stageApprovalsProvider = FutureProvider.family<List<StageApproval>, String>((ref, id) async {
  ref.watch(campaignListProvider);
  final repository = ref.watch(campaignRepositoryProvider);
  return repository.getStageApprovals(id);
});

/// Provider for audit events of a campaign
final campaignAuditEventsProvider = FutureProvider.family<List<AuditEvent>, String>((ref, id) async {
  ref.watch(campaignListProvider);
  final repository = ref.watch(campaignRepositoryProvider);
  return repository.getAuditEvents(id);
});

/// Provider for latest revision diff of a campaign
final campaignLatestDiffProvider = FutureProvider.family<CampaignRevisionDiff?, String>((ref, id) async {
  ref.watch(campaignListProvider);
  final repository = ref.watch(campaignRepositoryProvider);
  return repository.getLatestDiff(id);
});

/// Global audit trail provider (all campaigns)
final allAuditEventsProvider = FutureProvider<List<AuditEvent>>((ref) async {
  ref.watch(campaignListProvider);
  final repository = ref.watch(campaignRepositoryProvider);
  return repository.getAllAuditEvents();
});

