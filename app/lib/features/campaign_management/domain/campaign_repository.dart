import 'campaign_entity.dart';
import '../../../../core/models/campaign_state.dart';

class CampaignDraftInput {
  final String name;
  final String objective;
  final double amount;
  final String currency;
  final String costCenter;
  final String segmentName;
  final List<String> targetRegions;
  final List<String> channels;
  final int estimatedReach;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> assetLinks;

  const CampaignDraftInput({
    required this.name,
    required this.objective,
    required this.amount,
    this.currency = 'USD',
    required this.costCenter,
    required this.segmentName,
    required this.targetRegions,
    required this.channels,
    required this.estimatedReach,
    required this.startDate,
    required this.endDate,
    required this.assetLinks,
  });
}

class CampaignFieldDiff {
  final String fieldName;
  final String oldValue;
  final String newValue;
  final bool isMaterial;
  final String? rationale;

  const CampaignFieldDiff({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.isMaterial,
    this.rationale,
  });
}

class CampaignRevisionDiff {
  final String campaignId;
  final int previousVersion;
  final int currentVersion;
  final String previousSnapshotHash;
  final String currentSnapshotHash;
  final String? reviewerFeedbackAddressed;
  final List<CampaignFieldDiff> diffs;

  const CampaignRevisionDiff({
    required this.campaignId,
    required this.previousVersion,
    required this.currentVersion,
    required this.previousSnapshotHash,
    required this.currentSnapshotHash,
    this.reviewerFeedbackAddressed,
    required this.diffs,
  });
}

abstract class CampaignRepository {
  Future<List<Campaign>> getCampaigns({CampaignState? stateFilter, int? stageFilter});
  Future<Campaign?> getCampaignById(String id);
  Future<Campaign> createDraft(CampaignDraftInput input, String creatorId, String creatorName);
  Future<Campaign> updateDraft(String id, int expectedVersion, CampaignDraftInput input);
  Future<Campaign> submitForReview(String id, int expectedVersion, String submitterId, String submitterName);
  Future<Campaign> advanceStage({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String reviewerRole,
    String? notes,
  });
  Future<Campaign> requestChanges({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String feedback,
  });
  Future<Campaign> rejectCampaign({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String reason,
  });
  Future<Campaign> reviseAndResubmit({
    required String campaignId,
    required int expectedVersion,
    required CampaignDraftInput input,
    required String submitterId,
    required String submitterName,
    required String feedbackAddressed,
  });
  Future<Campaign> scheduleCampaign({
    required String campaignId,
    required int expectedVersion,
    required String actorId,
    required String actorName,
  });
  Future<List<AuditEvent>> getAuditEvents(String campaignId);
  Future<List<StageApproval>> getStageApprovals(String campaignId);
  Future<CampaignRevisionDiff?> getLatestDiff(String campaignId);
}

