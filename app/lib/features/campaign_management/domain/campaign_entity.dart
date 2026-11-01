import '../../../../core/models/campaign_state.dart';
import 'value_objects.dart';

class Campaign {
  final String id;
  final String name;
  final String objective;
  final CampaignState state;
  final int stageIndex; // 1: Creative, 2: Compliance, 3: Finance
  final int version; // Monotonic snapshot integer (1, 2, 3...)
  final String activeSnapshotId;
  final String snapshotHash; // SHA-256 digest
  final String submittedById;
  final String submittedByName;
  final BudgetAllocation budget;
  final AudienceCriteria audience;
  final ScheduleWindow schedule;
  final List<String> assetLinks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Campaign({
    required this.id,
    required this.name,
    required this.objective,
    required this.state,
    required this.stageIndex,
    required this.version,
    required this.activeSnapshotId,
    required this.snapshotHash,
    required this.submittedById,
    required this.submittedByName,
    required this.budget,
    required this.audience,
    required this.schedule,
    required this.assetLinks,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => state == CampaignState.draft;
  bool get isPendingReview => state == CampaignState.pendingReview;
  bool get isChangesRequested => state == CampaignState.changesRequested;
  bool get isApproved => state == CampaignState.approved;
  bool get isScheduled => state == CampaignState.scheduled;
  bool get isRejected => state == CampaignState.rejected;

  String get currentStageName {
    switch (stageIndex) {
      case 1:
        return 'Stage 1: Creative & Brand';
      case 2:
        return 'Stage 2: Legal & Compliance';
      case 3:
      default:
        return 'Stage 3: Finance & DOA';
    }
  }

  Campaign copyWith({
    String? name,
    String? objective,
    CampaignState? state,
    int? stageIndex,
    int? version,
    String? activeSnapshotId,
    String? snapshotHash,
    BudgetAllocation? budget,
    AudienceCriteria? audience,
    ScheduleWindow? schedule,
    List<String>? assetLinks,
    DateTime? updatedAt,
  }) {
    return Campaign(
      id: id,
      name: name ?? this.name,
      objective: objective ?? this.objective,
      state: state ?? this.state,
      stageIndex: stageIndex ?? this.stageIndex,
      version: version ?? this.version,
      activeSnapshotId: activeSnapshotId ?? this.activeSnapshotId,
      snapshotHash: snapshotHash ?? this.snapshotHash,
      submittedById: submittedById,
      submittedByName: submittedByName,
      budget: budget ?? this.budget,
      audience: audience ?? this.audience,
      schedule: schedule ?? this.schedule,
      assetLinks: assetLinks ?? this.assetLinks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class StageApproval {
  final String id;
  final String campaignId;
  final String snapshotId;
  final int versionNumber;
  final int stageIndex; // 1: Creative, 2: Compliance, 3: Finance
  final String reviewerId;
  final String reviewerName;
  final String reviewerRole;
  final String snapshotHash;
  final String? notes;
  final DateTime approvedAt;

  const StageApproval({
    required this.id,
    required this.campaignId,
    required this.snapshotId,
    required this.versionNumber,
    required this.stageIndex,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerRole,
    required this.snapshotHash,
    this.notes,
    required this.approvedAt,
  });

  String get stageTitle {
    switch (stageIndex) {
      case 1:
        return 'Creative & Brand Review';
      case 2:
        return 'Legal & Compliance Audit';
      case 3:
      default:
        return 'Finance & DOA Authorization';
    }
  }
}

class AuditEvent {
  final String id;
  final String campaignId;
  final int versionNumber;
  final int? stageIndex;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String previousState;
  final String newState;
  final String snapshotHash;
  final String details;
  final DateTime timestamp;

  const AuditEvent({
    required this.id,
    required this.campaignId,
    required this.versionNumber,
    this.stageIndex,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.previousState,
    required this.newState,
    required this.snapshotHash,
    required this.details,
    required this.timestamp,
  });
}

