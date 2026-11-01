import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/models/campaign_state.dart';
import '../../../../core/utils/hash_util.dart';
import '../domain/campaign_entity.dart';
import '../domain/campaign_repository.dart';
import '../domain/value_objects.dart';

class MockCampaignRepository implements CampaignRepository {
  static const _uuid = Uuid();

  final List<Campaign> _campaigns = [];
  final List<AuditEvent> _auditEvents = [];
  final List<StageApproval> _stageApprovals = [];
  final Map<String, List<CampaignRevisionDiff>> _revisionDiffs = {};

  MockCampaignRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();

    // cmp_01: Stage 1 (Creative & Brand) Pending
    final c1Budget = BudgetAllocation(
      amount: 45000.0,
      currency: 'USD',
      costCenter: 'CC-MKTG-GLOBAL',
      doaTier: BudgetAllocation.calculateDoaTier(45000.0),
    );
    final c1Audience = const AudienceCriteria(
      segmentName: 'Global Online Shoppers (25-45)',
      targetRegions: ['North America', 'Europe', 'APAC'],
      channels: ['Meta', 'Google Ads', 'TikTok', 'Display'],
      estimatedReach: 850000,
    );
    final c1Schedule = ScheduleWindow(
      startDate: now.add(const Duration(days: 14)),
      endDate: now.add(const Duration(days: 60)),
    );
    final c1Hash = HashUtil.computeSnapshotHash(
      campaignId: 'cmp_01',
      version: 1,
      name: 'Q4 Global Holiday Omni-Channel Surge',
      objective: 'Drive global brand engagement and conversion uplift across holiday storefronts.',
      budgetAmount: c1Budget.amount,
      costCenter: c1Budget.costCenter,
      segmentName: c1Audience.segmentName,
      channels: c1Audience.channels,
      startDate: c1Schedule.startDate,
      endDate: c1Schedule.endDate,
    );

    final cmp1 = Campaign(
      id: 'cmp_01',
      name: 'Q4 Global Holiday Omni-Channel Surge',
      objective: 'Drive global brand engagement and conversion uplift across holiday storefronts.',
      state: CampaignState.pendingReview,
      stageIndex: 1,
      version: 1,
      activeSnapshotId: 'snp_01_v1',
      snapshotHash: c1Hash,
      submittedById: 'usr_marketer_alex',
      submittedByName: 'Alex Chen',
      budget: c1Budget,
      audience: c1Audience,
      schedule: c1Schedule,
      assetLinks: ['https://assets.enterprise.cdn/creatives/q4_holiday_deck.pdf'],
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 4)),
    );

    // cmp_02: Stage 2 (Legal & Compliance) Pending (Stage 1 approved)
    final c2Budget = BudgetAllocation(
      amount: 8500.0,
      currency: 'USD',
      costCenter: 'CC-RETENTION',
      doaTier: BudgetAllocation.calculateDoaTier(8500.0),
    );
    final c2Audience = const AudienceCriteria(
      segmentName: 'At-Risk Loyalty Tier Gold/Platinum',
      targetRegions: ['North America'],
      channels: ['Email', 'Push Notifications', 'In-App Message'],
      estimatedReach: 120000,
    );
    final c2Schedule = ScheduleWindow(
      startDate: now.add(const Duration(days: 7)),
      endDate: now.add(const Duration(days: 35)),
    );
    final c2Hash = HashUtil.computeSnapshotHash(
      campaignId: 'cmp_02',
      version: 1,
      name: 'Loyalty Tier Member Retention Initiative',
      objective: 'Target churn-risk loyalty members with exclusive re-engagement perks.',
      budgetAmount: c2Budget.amount,
      costCenter: c2Budget.costCenter,
      segmentName: c2Audience.segmentName,
      channels: c2Audience.channels,
      startDate: c2Schedule.startDate,
      endDate: c2Schedule.endDate,
    );

    final cmp2 = Campaign(
      id: 'cmp_02',
      name: 'Loyalty Tier Member Retention Initiative',
      objective: 'Target churn-risk loyalty members with exclusive re-engagement perks.',
      state: CampaignState.pendingReview,
      stageIndex: 2,
      version: 1,
      activeSnapshotId: 'snp_02_v1',
      snapshotHash: c2Hash,
      submittedById: 'usr_marketer_alex',
      submittedByName: 'Alex Chen',
      budget: c2Budget,
      audience: c2Audience,
      schedule: c2Schedule,
      assetLinks: ['https://assets.enterprise.cdn/copy/loyalty_retention_v1.docx'],
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(hours: 18)),
    );

    final approval2S1 = StageApproval(
      id: 'appr_02_s1',
      campaignId: 'cmp_02',
      snapshotId: 'snp_02_v1',
      versionNumber: 1,
      stageIndex: 1,
      reviewerId: 'usr_creative_elena',
      reviewerName: 'Elena Rostova',
      reviewerRole: 'Creative & Brand Lead',
      snapshotHash: c2Hash,
      notes: 'Brand imagery adheres to 2026 design system guidelines. Approved.',
      approvedAt: now.subtract(const Duration(hours: 18)),
    );

    // cmp_03: Changes Requested at Stage 2
    final c3Budget = BudgetAllocation(
      amount: 75000.0,
      currency: 'USD',
      costCenter: 'CC-FINTECH-ACQ',
      doaTier: BudgetAllocation.calculateDoaTier(75000.0),
    );
    final c3Audience = const AudienceCriteria(
      segmentName: 'US Small Business Retailers',
      targetRegions: ['United States'],
      channels: ['LinkedIn', 'Google Search', 'Direct Mail'],
      estimatedReach: 320000,
    );
    final c3Schedule = ScheduleWindow(
      startDate: now.add(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 90)),
    );
    final c3Hash = HashUtil.computeSnapshotHash(
      campaignId: 'cmp_03',
      version: 1,
      name: 'FinTech Retail Acquisition Pilot',
      objective: 'Acquire retail micro-merchant signups with high-yield promotional balance offers.',
      budgetAmount: c3Budget.amount,
      costCenter: c3Budget.costCenter,
      segmentName: c3Audience.segmentName,
      channels: c3Audience.channels,
      startDate: c3Schedule.startDate,
      endDate: c3Schedule.endDate,
    );

    final cmp3 = Campaign(
      id: 'cmp_03',
      name: 'FinTech Retail Acquisition Pilot',
      objective: 'Acquire retail micro-merchant signups with high-yield promotional balance offers.',
      state: CampaignState.changesRequested,
      stageIndex: 2,
      version: 1,
      activeSnapshotId: 'snp_03_v1',
      snapshotHash: c3Hash,
      submittedById: 'usr_marketer_alex',
      submittedByName: 'Alex Chen',
      budget: c3Budget,
      audience: c3Audience,
      schedule: c3Schedule,
      assetLinks: ['https://assets.enterprise.cdn/legal/fintech_terms.pdf'],
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(hours: 6)),
    );

    final approval3S1 = StageApproval(
      id: 'appr_03_s1',
      campaignId: 'cmp_03',
      snapshotId: 'snp_03_v1',
      versionNumber: 1,
      stageIndex: 1,
      reviewerId: 'usr_creative_elena',
      reviewerName: 'Elena Rostova',
      reviewerRole: 'Creative & Brand Lead',
      snapshotHash: c3Hash,
      notes: 'Copy and visual assets look sharp. Approved from creative side.',
      approvedAt: now.subtract(const Duration(days: 3)),
    );

    // cmp_04: Fully Approved (Stage 1, 2, 3 complete)
    final c4Budget = BudgetAllocation(
      amount: 25000.0,
      currency: 'USD',
      costCenter: 'CC-CORP-BRAND',
      doaTier: BudgetAllocation.calculateDoaTier(25000.0),
    );
    final c4Audience = const AudienceCriteria(
      segmentName: 'Enterprise B2B Decision Makers',
      targetRegions: ['North America', 'Europe'],
      channels: ['LinkedIn Ads', 'PR Newswire', 'Industry Publications'],
      estimatedReach: 450000,
    );
    final c4Schedule = ScheduleWindow(
      startDate: now.add(const Duration(days: 45)),
      endDate: now.add(const Duration(days: 120)),
    );
    final c4Hash = HashUtil.computeSnapshotHash(
      campaignId: 'cmp_04',
      version: 1,
      name: 'Brand Identity & Modernization Refresh',
      objective: 'Roll out rebranded brand identity guidelines, visual assets, and collateral.',
      budgetAmount: c4Budget.amount,
      costCenter: c4Budget.costCenter,
      segmentName: c4Audience.segmentName,
      channels: c4Audience.channels,
      startDate: c4Schedule.startDate,
      endDate: c4Schedule.endDate,
    );

    final cmp4 = Campaign(
      id: 'cmp_04',
      name: 'Brand Identity & Modernization Refresh',
      objective: 'Roll out rebranded brand identity guidelines, visual assets, and collateral.',
      state: CampaignState.approved,
      stageIndex: 3,
      version: 1,
      activeSnapshotId: 'snp_04_v1',
      snapshotHash: c4Hash,
      submittedById: 'usr_marketer_alex',
      submittedByName: 'Alex Chen',
      budget: c4Budget,
      audience: c4Audience,
      schedule: c4Schedule,
      assetLinks: ['https://assets.enterprise.cdn/brand/2026_guidelines.pdf'],
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );

    final approval4S1 = StageApproval(
      id: 'appr_04_s1',
      campaignId: 'cmp_04',
      snapshotId: 'snp_04_v1',
      versionNumber: 1,
      stageIndex: 1,
      reviewerId: 'usr_creative_elena',
      reviewerName: 'Elena Rostova',
      reviewerRole: 'Creative & Brand Lead',
      snapshotHash: c4Hash,
      notes: 'Creative alignment confirmed across all asset bundles.',
      approvedAt: now.subtract(const Duration(days: 7)),
    );

    final approval4S2 = StageApproval(
      id: 'appr_04_s2',
      campaignId: 'cmp_04',
      snapshotId: 'snp_04_v1',
      versionNumber: 1,
      stageIndex: 2,
      reviewerId: 'usr_compliance_marcus',
      reviewerName: 'Marcus Vance',
      reviewerRole: 'Legal & Compliance Officer',
      snapshotHash: c4Hash,
      notes: 'Trademark verification and copyright review passed with zero flags.',
      approvedAt: now.subtract(const Duration(days: 4)),
    );

    final approval4S3 = StageApproval(
      id: 'appr_04_s3',
      campaignId: 'cmp_04',
      snapshotId: 'snp_04_v1',
      versionNumber: 1,
      stageIndex: 3,
      reviewerId: 'usr_finance_sophia',
      reviewerName: 'Sophia Sterling',
      reviewerRole: 'Finance Director (DOA Tier 2)',
      snapshotHash: c4Hash,
      notes: 'DOA Tier 2 budget authorization verified against FY26 Cost Center CC-CORP-BRAND.',
      approvedAt: now.subtract(const Duration(days: 1)),
    );

    _campaigns.addAll([cmp1, cmp2, cmp3, cmp4]);
    _stageApprovals.addAll([
      approval2S1,
      approval3S1,
      approval4S1,
      approval4S2,
      approval4S3,
    ]);

    // Initial audit events
    _auditEvents.addAll([
      AuditEvent(
        id: _uuid.v4(),
        campaignId: 'cmp_01',
        versionNumber: 1,
        actorId: 'usr_marketer_alex',
        actorName: 'Alex Chen',
        actorRole: 'Campaign Marketer',
        action: 'CAMPAIGN_SUBMITTED',
        previousState: 'DRAFT',
        newState: 'PENDING_REVIEW',
        snapshotHash: c1Hash,
        details: 'Submitted for Stage 1 (Creative & Brand) review.',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      AuditEvent(
        id: _uuid.v4(),
        campaignId: 'cmp_02',
        versionNumber: 1,
        stageIndex: 1,
        actorId: 'usr_creative_elena',
        actorName: 'Elena Rostova',
        actorRole: 'Creative & Brand Lead',
        action: 'STAGE_1_APPROVED',
        previousState: 'PENDING_REVIEW',
        newState: 'PENDING_REVIEW',
        snapshotHash: c2Hash,
        details: 'Creative & Brand review approved. Advanced to Stage 2 (Compliance).',
        timestamp: now.subtract(const Duration(hours: 18)),
      ),
      AuditEvent(
        id: _uuid.v4(),
        campaignId: 'cmp_03',
        versionNumber: 1,
        stageIndex: 2,
        actorId: 'usr_compliance_marcus',
        actorName: 'Marcus Vance',
        actorRole: 'Legal & Compliance Officer',
        action: 'STAGE_CHANGES_REQUESTED',
        previousState: 'PENDING_REVIEW',
        newState: 'CHANGES_REQUESTED',
        snapshotHash: c3Hash,
        details: 'Compliance disclaimer regarding interest rates and regulatory disclosures is missing in the primary creative bundle.',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      AuditEvent(
        id: _uuid.v4(),
        campaignId: 'cmp_04',
        versionNumber: 1,
        stageIndex: 3,
        actorId: 'usr_finance_sophia',
        actorName: 'Sophia Sterling',
        actorRole: 'Finance Director',
        action: 'STAGE_3_APPROVED',
        previousState: 'PENDING_REVIEW',
        newState: 'APPROVED',
        snapshotHash: c4Hash,
        details: 'All 3 stages approved. Campaign marked APPROVED and unlocked for scheduling.',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  @override
  Future<List<Campaign>> getCampaigns({CampaignState? stateFilter, int? stageFilter}) async {
    await Future.delayed(const Duration(milliseconds: 60));
    var result = List<Campaign>.from(_campaigns);
    if (stateFilter != null) {
      result = result.where((c) => c.state == stateFilter).toList();
    }
    if (stageFilter != null) {
      result = result.where((c) => c.stageIndex == stageFilter).toList();
    }
    // Return sorted descending by updated date
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<Campaign?> getCampaignById(String id) async {
    await Future.delayed(const Duration(milliseconds: 40));
    try {
      return _campaigns.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Campaign> createDraft(CampaignDraftInput input, String creatorId, String creatorName) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final id = 'cmp_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    final budget = BudgetAllocation(
      amount: input.amount,
      currency: input.currency,
      costCenter: input.costCenter,
      doaTier: BudgetAllocation.calculateDoaTier(input.amount),
    );

    final audience = AudienceCriteria(
      segmentName: input.segmentName,
      targetRegions: input.targetRegions,
      channels: input.channels,
      estimatedReach: input.estimatedReach,
    );

    final schedule = ScheduleWindow(
      startDate: input.startDate,
      endDate: input.endDate,
    );

    final snapshotHash = HashUtil.computeSnapshotHash(
      campaignId: id,
      version: 1,
      name: input.name,
      objective: input.objective,
      budgetAmount: budget.amount,
      costCenter: budget.costCenter,
      segmentName: audience.segmentName,
      channels: audience.channels,
      startDate: schedule.startDate,
      endDate: schedule.endDate,
    );

    final campaign = Campaign(
      id: id,
      name: input.name,
      objective: input.objective,
      state: CampaignState.draft,
      stageIndex: 1,
      version: 1,
      activeSnapshotId: 'snp_${id}_v1',
      snapshotHash: snapshotHash,
      submittedById: creatorId,
      submittedByName: creatorName,
      budget: budget,
      audience: audience,
      schedule: schedule,
      assetLinks: input.assetLinks,
      createdAt: now,
      updatedAt: now,
    );

    _campaigns.add(campaign);

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: id,
        versionNumber: 1,
        actorId: creatorId,
        actorName: creatorName,
        actorRole: 'Campaign Marketer',
        action: 'DRAFT_CREATED',
        previousState: 'NONE',
        newState: 'DRAFT',
        snapshotHash: snapshotHash,
        details: 'Initial campaign proposal drafted.',
        timestamp: now,
      ),
    );

    return campaign;
  }

  @override
  Future<Campaign> updateDraft(String id, int expectedVersion, CampaignDraftInput input) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final index = _campaigns.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('Campaign not found ($id)');

    final existing = _campaigns[index];
    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Optimistic locking violation. Expected v$expectedVersion but found v${existing.version}.');
    }
    if (existing.state != CampaignState.draft) {
      throw Exception('IllegalState: Only draft campaigns can be directly updated.');
    }

    final budget = BudgetAllocation(
      amount: input.amount,
      currency: input.currency,
      costCenter: input.costCenter,
      doaTier: BudgetAllocation.calculateDoaTier(input.amount),
    );

    final audience = AudienceCriteria(
      segmentName: input.segmentName,
      targetRegions: input.targetRegions,
      channels: input.channels,
      estimatedReach: input.estimatedReach,
    );

    final schedule = ScheduleWindow(
      startDate: input.startDate,
      endDate: input.endDate,
    );

    final hash = HashUtil.computeSnapshotHash(
      campaignId: id,
      version: existing.version,
      name: input.name,
      objective: input.objective,
      budgetAmount: budget.amount,
      costCenter: budget.costCenter,
      segmentName: audience.segmentName,
      channels: audience.channels,
      startDate: schedule.startDate,
      endDate: schedule.endDate,
    );

    final updated = existing.copyWith(
      name: input.name,
      objective: input.objective,
      budget: budget,
      audience: audience,
      schedule: schedule,
      assetLinks: input.assetLinks,
      snapshotHash: hash,
      updatedAt: DateTime.now(),
    );

    _campaigns[index] = updated;
    return updated;
  }

  @override
  Future<Campaign> submitForReview(String id, int expectedVersion, String submitterId, String submitterName) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _campaigns.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('Campaign not found ($id)');

    final existing = _campaigns[index];
    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Version mismatch. Expected v$expectedVersion, found v${existing.version}');
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      state: CampaignState.pendingReview,
      stageIndex: 1,
      updatedAt: now,
    );

    _campaigns[index] = updated;

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: id,
        versionNumber: existing.version,
        actorId: submitterId,
        actorName: submitterName,
        actorRole: 'Campaign Marketer',
        action: 'CAMPAIGN_SUBMITTED',
        previousState: existing.state.name.toUpperCase(),
        newState: 'PENDING_REVIEW',
        snapshotHash: existing.snapshotHash,
        details: 'Campaign submitted for Stage 1 (Creative & Brand) review.',
        timestamp: now,
      ),
    );

    return updated;
  }

  @override
  Future<Campaign> advanceStage({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String reviewerRole,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index == -1) throw Exception('Campaign not found ($campaignId)');

    final existing = _campaigns[index];

    // Invariant: Anti-Self-Approval
    if (existing.submittedById == reviewerId) {
      throw Exception('Anti-Self-Approval Violation: Campaign author ($reviewerName) cannot review or approve their own submission.');
    }

    // Invariant: Optimistic Concurrency Control
    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Snapshot version conflict. Expected v$expectedVersion, found v${existing.version}');
    }

    // Invariant: Monotonic Stage Progression
    if (existing.stageIndex != currentStage) {
      throw Exception('IllegalProgression: Cannot advance stage $currentStage when active stage is ${existing.stageIndex}.');
    }

    final now = DateTime.now();
    final approval = StageApproval(
      id: 'appr_${_uuid.v4().substring(0, 8)}',
      campaignId: campaignId,
      snapshotId: existing.activeSnapshotId,
      versionNumber: existing.version,
      stageIndex: currentStage,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerRole: reviewerRole,
      snapshotHash: existing.snapshotHash,
      notes: notes,
      approvedAt: now,
    );

    _stageApprovals.add(approval);

    Campaign updated;
    if (currentStage == 1) {
      // Advance to Stage 2
      updated = existing.copyWith(
        stageIndex: 2,
        state: CampaignState.pendingReview,
        updatedAt: now,
      );
    } else if (currentStage == 2) {
      // Advance to Stage 3
      updated = existing.copyWith(
        stageIndex: 3,
        state: CampaignState.pendingReview,
        updatedAt: now,
      );
    } else {
      // Stage 3 complete -> Fully Approved
      updated = existing.copyWith(
        stageIndex: 3,
        state: CampaignState.approved,
        updatedAt: now,
      );
    }

    _campaigns[index] = updated;

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: campaignId,
        versionNumber: existing.version,
        stageIndex: currentStage,
        actorId: reviewerId,
        actorName: reviewerName,
        actorRole: reviewerRole,
        action: 'STAGE_${currentStage}_APPROVED',
        previousState: existing.state.name.toUpperCase(),
        newState: updated.state.name.toUpperCase(),
        snapshotHash: existing.snapshotHash,
        details: notes?.isNotEmpty == true ? notes! : 'Stage $currentStage successfully verified and approved.',
        timestamp: now,
      ),
    );

    return updated;
  }

  @override
  Future<Campaign> requestChanges({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String feedback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index == -1) throw Exception('Campaign not found ($campaignId)');

    final existing = _campaigns[index];

    // Invariant: Anti-Self-Approval
    if (existing.submittedById == reviewerId) {
      throw Exception('Anti-Self-Approval Violation: Campaign author cannot request changes on their own submission.');
    }

    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Snapshot version conflict. Expected v$expectedVersion, found v${existing.version}');
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      state: CampaignState.changesRequested,
      updatedAt: now,
    );

    _campaigns[index] = updated;

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: campaignId,
        versionNumber: existing.version,
        stageIndex: currentStage,
        actorId: reviewerId,
        actorName: reviewerName,
        actorRole: 'Reviewer (Stage $currentStage)',
        action: 'STAGE_CHANGES_REQUESTED',
        previousState: existing.state.name.toUpperCase(),
        newState: 'CHANGES_REQUESTED',
        snapshotHash: existing.snapshotHash,
        details: feedback,
        timestamp: now,
      ),
    );

    return updated;
  }

  @override
  Future<Campaign> rejectCampaign({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerName,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index == -1) throw Exception('Campaign not found ($campaignId)');

    final existing = _campaigns[index];

    // Invariant: Anti-Self-Approval
    if (existing.submittedById == reviewerId) {
      throw Exception('Anti-Self-Approval Violation: Campaign author cannot reject their own submission.');
    }

    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Snapshot version conflict.');
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      state: CampaignState.rejected,
      updatedAt: now,
    );

    _campaigns[index] = updated;

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: campaignId,
        versionNumber: existing.version,
        stageIndex: currentStage,
        actorId: reviewerId,
        actorName: reviewerName,
        actorRole: 'Reviewer (Stage $currentStage)',
        action: 'CAMPAIGN_REJECTED',
        previousState: existing.state.name.toUpperCase(),
        newState: 'REJECTED',
        snapshotHash: existing.snapshotHash,
        details: reason,
        timestamp: now,
      ),
    );

    return updated;
  }

  @override
  Future<Campaign> reviseAndResubmit({
    required String campaignId,
    required int expectedVersion,
    required CampaignDraftInput input,
    required String submitterId,
    required String submitterName,
    required String feedbackAddressed,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index == -1) throw Exception('Campaign not found ($campaignId)');

    final existing = _campaigns[index];
    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Snapshot version conflict. Expected v$expectedVersion, found v${existing.version}');
    }

    final newVersion = existing.version + 1;
    final newSnapshotId = 'snp_${campaignId}_v$newVersion';

    final newBudget = BudgetAllocation(
      amount: input.amount,
      currency: input.currency,
      costCenter: input.costCenter,
      doaTier: BudgetAllocation.calculateDoaTier(input.amount),
    );

    final newAudience = AudienceCriteria(
      segmentName: input.segmentName,
      targetRegions: input.targetRegions,
      channels: input.channels,
      estimatedReach: input.estimatedReach,
    );

    final newSchedule = ScheduleWindow(
      startDate: input.startDate,
      endDate: input.endDate,
    );

    final newHash = HashUtil.computeSnapshotHash(
      campaignId: campaignId,
      version: newVersion,
      name: input.name,
      objective: input.objective,
      budgetAmount: newBudget.amount,
      costCenter: newBudget.costCenter,
      segmentName: newAudience.segmentName,
      channels: newAudience.channels,
      startDate: newSchedule.startDate,
      endDate: newSchedule.endDate,
    );

    // Compute field diffs and materiality
    final diffs = <CampaignFieldDiff>[];

    if (existing.name != input.name) {
      diffs.add(
        CampaignFieldDiff(
          fieldName: 'Campaign Name',
          oldValue: existing.name,
          newValue: input.name,
          isMaterial: false,
        ),
      );
    }

    if (existing.objective != input.objective) {
      diffs.add(
        CampaignFieldDiff(
          fieldName: 'Campaign Objective',
          oldValue: existing.objective,
          newValue: input.objective,
          isMaterial: false,
        ),
      );
    }

    if (existing.budget.amount != newBudget.amount || existing.budget.costCenter != newBudget.costCenter) {
      final isMaterial = existing.budget.isMaterialDelta(newBudget);
      final deltaPct = ((newBudget.amount - existing.budget.amount) / existing.budget.amount * 100).toStringAsFixed(1);
      diffs.add(
        CampaignFieldDiff(
          fieldName: 'Budget Allocation',
          oldValue: existing.budget.formattedAmount,
          newValue: newBudget.formattedAmount,
          isMaterial: isMaterial,
          rationale: isMaterial
              ? 'Budget delta ($deltaPct%) exceeds ±10% threshold. Requires Stage 1 reset.'
              : 'Within ±10% tolerance.',
        ),
      );
    }

    if (existing.audience.segmentName != newAudience.segmentName ||
        existing.audience.estimatedReach != newAudience.estimatedReach) {
      final isMaterial = existing.audience.isMaterialDelta(newAudience);
      diffs.add(
        CampaignFieldDiff(
          fieldName: 'Target Audience & Reach',
          oldValue: '${existing.audience.segmentName} (${existing.audience.formattedReach})',
          newValue: '${newAudience.segmentName} (${newAudience.formattedReach})',
          isMaterial: isMaterial,
          rationale: isMaterial ? 'Audience reach shift exceeds 15% materiality threshold.' : null,
        ),
      );
    }

    if (existing.schedule.startDate != newSchedule.startDate ||
        existing.schedule.endDate != newSchedule.endDate) {
      final isMaterial = existing.schedule.isMaterialShift(newSchedule);
      diffs.add(
        CampaignFieldDiff(
          fieldName: 'Flight Schedule Window',
          oldValue: existing.schedule.formattedRange,
          newValue: newSchedule.formattedRange,
          isMaterial: isMaterial,
          rationale: isMaterial ? 'Flight date shift exceeds 72 hour threshold.' : null,
        ),
      );
    }

    final revisionDiff = CampaignRevisionDiff(
      campaignId: campaignId,
      previousVersion: existing.version,
      currentVersion: newVersion,
      previousSnapshotHash: existing.snapshotHash,
      currentSnapshotHash: newHash,
      reviewerFeedbackAddressed: feedbackAddressed,
      diffs: diffs,
    );

    _revisionDiffs.putIfAbsent(campaignId, () => []).add(revisionDiff);

    // Rule: Material changes invalidate all prior approvals and reset back to Stage 1
    final now = DateTime.now();
    final updated = Campaign(
      id: campaignId,
      name: input.name,
      objective: input.objective,
      state: CampaignState.pendingReview,
      stageIndex: 1, // Reset to Stage 1: Creative & Brand
      version: newVersion,
      activeSnapshotId: newSnapshotId,
      snapshotHash: newHash,
      submittedById: submitterId,
      submittedByName: submitterName,
      budget: newBudget,
      audience: newAudience,
      schedule: newSchedule,
      assetLinks: input.assetLinks,
      createdAt: existing.createdAt,
      updatedAt: now,
    );

    _campaigns[index] = updated;

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: campaignId,
        versionNumber: newVersion,
        stageIndex: 1,
        actorId: submitterId,
        actorName: submitterName,
        actorRole: 'Campaign Marketer',
        action: 'CAMPAIGN_REVISED_AND_RESUBMITTED',
        previousState: 'CHANGES_REQUESTED',
        newState: 'PENDING_REVIEW',
        snapshotHash: newHash,
        details: 'v$newVersion resubmitted. Addressed feedback: "$feedbackAddressed". Prior approvals invalidated; pipeline reset to Stage 1.',
        timestamp: now,
      ),
    );

    return updated;
  }

  @override
  Future<Campaign> scheduleCampaign({
    required String campaignId,
    required int expectedVersion,
    required String actorId,
    required String actorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index == -1) throw Exception('Campaign not found ($campaignId)');

    final existing = _campaigns[index];
    if (existing.version != expectedVersion) {
      throw Exception('ConflictFailure(409): Version mismatch.');
    }

    if (existing.state != CampaignState.approved) {
      throw Exception('SchedulingGateViolation: Campaign must be in APPROVED state before scheduling.');
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      state: CampaignState.scheduled,
      updatedAt: now,
    );

    _campaigns[index] = updated;

    _auditEvents.add(
      AuditEvent(
        id: _uuid.v4(),
        campaignId: campaignId,
        versionNumber: existing.version,
        stageIndex: 3,
        actorId: actorId,
        actorName: actorName,
        actorRole: 'Marketing Operations / Scheduler',
        action: 'CAMPAIGN_SCHEDULED',
        previousState: 'APPROVED',
        newState: 'SCHEDULED',
        snapshotHash: existing.snapshotHash,
        details: 'All 3 stages cryptographically verified. Campaign scheduled for automated DSP distribution.',
        timestamp: now,
      ),
    );

    return updated;
  }

  @override
  Future<List<AuditEvent>> getAuditEvents(String campaignId) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final events = _auditEvents.where((e) => e.campaignId == campaignId).toList();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  @override
  Future<List<StageApproval>> getStageApprovals(String campaignId) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final approvals = _stageApprovals.where((a) => a.campaignId == campaignId).toList();
    approvals.sort((a, b) => a.stageIndex.compareTo(b.stageIndex));
    return approvals;
  }

  @override
  Future<CampaignRevisionDiff?> getLatestDiff(String campaignId) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final diffs = _revisionDiffs[campaignId];
    if (diffs == null || diffs.isEmpty) return null;
    return diffs.last;
  }

  /// Exposed for audit log tab to fetch all events across all campaigns
  Future<List<AuditEvent>> getAllAuditEvents() async {
    await Future.delayed(const Duration(milliseconds: 40));
    final list = List<AuditEvent>.from(_auditEvents);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}
