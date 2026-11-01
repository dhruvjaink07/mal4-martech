import 'package:flutter_test/flutter_test.dart';
import 'package:mal4_campaign_approval_app/core/models/campaign_state.dart';
import 'package:mal4_campaign_approval_app/features/campaign_management/data/mock_campaign_repository.dart';
import 'package:mal4_campaign_approval_app/features/campaign_management/domain/campaign_repository.dart';

void main() {
  late MockCampaignRepository repo;

  setUp(() {
    repo = MockCampaignRepository();
  });

  group('MockCampaignRepository Domain Invariants & Logic', () {
    test('Anti-Self-Approval: Campaign author cannot approve their own submission', () async {
      // cmp_01 author is usr_marketer_alex
      expect(
        () => repo.advanceStage(
          campaignId: 'cmp_01',
          expectedVersion: 1,
          currentStage: 1,
          reviewerId: 'usr_marketer_alex', // author
          reviewerName: 'Alex Chen',
          reviewerRole: 'Campaign Marketer',
        ),
        throwsA(predicate((e) => e.toString().contains('Anti-Self-Approval Violation'))),
      );
    });

    test('Anti-Self-Approval: Campaign author cannot request changes or reject own proposal', () async {
      expect(
        () => repo.requestChanges(
          campaignId: 'cmp_01',
          expectedVersion: 1,
          currentStage: 1,
          reviewerId: 'usr_marketer_alex',
          reviewerName: 'Alex Chen',
          feedback: 'Some feedback',
        ),
        throwsA(predicate((e) => e.toString().contains('Anti-Self-Approval Violation'))),
      );

      expect(
        () => repo.rejectCampaign(
          campaignId: 'cmp_01',
          expectedVersion: 1,
          currentStage: 1,
          reviewerId: 'usr_marketer_alex',
          reviewerName: 'Alex Chen',
          reason: 'Some reason',
        ),
        throwsA(predicate((e) => e.toString().contains('Anti-Self-Approval Violation'))),
      );
    });

    test('Monotonic Stage Progression: Cannot approve Stage 2 when active is Stage 1', () async {
      // cmp_01 is at Stage 1
      expect(
        () => repo.advanceStage(
          campaignId: 'cmp_01',
          expectedVersion: 1,
          currentStage: 2, // Illegal: Skipping Stage 1
          reviewerId: 'usr_compliance_marcus',
          reviewerName: 'Marcus Vance',
          reviewerRole: 'Legal & Compliance Officer',
        ),
        throwsA(predicate((e) => e.toString().contains('IllegalProgression'))),
      );
    });

    test('Optimistic Concurrency Control (OCC): Throws ConflictFailure on version mismatch', () async {
      expect(
        () => repo.advanceStage(
          campaignId: 'cmp_01',
          expectedVersion: 99, // mismatch
          currentStage: 1,
          reviewerId: 'usr_creative_elena',
          reviewerName: 'Elena Rostova',
          reviewerRole: 'Creative & Brand Lead',
        ),
        throwsA(predicate((e) => e.toString().contains('ConflictFailure(409)'))),
      );
    });

    test('Sequential Pipeline Advancement: S1 -> S2 -> S3 -> Approved', () async {
      // Advance Stage 1 (Creative)
      final afterS1 = await repo.advanceStage(
        campaignId: 'cmp_01',
        expectedVersion: 1,
        currentStage: 1,
        reviewerId: 'usr_creative_elena',
        reviewerName: 'Elena Rostova',
        reviewerRole: 'Creative & Brand Lead',
        notes: 'Visual assets approved.',
      );
      expect(afterS1.stageIndex, equals(2));
      expect(afterS1.state, equals(CampaignState.pendingReview));

      // Advance Stage 2 (Legal & Compliance)
      final afterS2 = await repo.advanceStage(
        campaignId: 'cmp_01',
        expectedVersion: 1,
        currentStage: 2,
        reviewerId: 'usr_compliance_marcus',
        reviewerName: 'Marcus Vance',
        reviewerRole: 'Legal & Compliance Officer',
        notes: 'Compliance terms verified.',
      );
      expect(afterS2.stageIndex, equals(3));
      expect(afterS2.state, equals(CampaignState.pendingReview));

      // Advance Stage 3 (Finance & Budget)
      final afterS3 = await repo.advanceStage(
        campaignId: 'cmp_01',
        expectedVersion: 1,
        currentStage: 3,
        reviewerId: 'usr_finance_sophia',
        reviewerName: 'Sophia Sterling',
        reviewerRole: 'Finance Director',
        notes: 'Budget verified against DOA Tier 2 limits.',
      );
      expect(afterS3.stageIndex, equals(3));
      expect(afterS3.state, equals(CampaignState.approved));

      // Verify approvals history
      final approvals = await repo.getStageApprovals('cmp_01');
      expect(approvals.length, equals(3));
    });

    test('Material Change Invalidation & Revision: Bumps to v2 and resets to Stage 1', () async {
      // cmp_03 is in changesRequested with budget $75,000
      final existing = await repo.getCampaignById('cmp_03');
      expect(existing, isNotNull);
      expect(existing!.state, equals(CampaignState.changesRequested));

      // Revise with $95,000 budget (+26.6% material delta)
      final input = CampaignDraftInput(
        name: existing.name,
        objective: existing.objective,
        amount: 95000.0, // Material change > 10%
        currency: 'USD',
        costCenter: existing.budget.costCenter,
        segmentName: existing.audience.segmentName,
        targetRegions: existing.audience.targetRegions,
        channels: existing.audience.channels,
        estimatedReach: existing.audience.estimatedReach,
        startDate: existing.schedule.startDate,
        endDate: existing.schedule.endDate,
        assetLinks: existing.assetLinks,
      );

      final revised = await repo.reviseAndResubmit(
        campaignId: 'cmp_03',
        expectedVersion: 1,
        input: input,
        submitterId: 'usr_marketer_alex',
        submitterName: 'Alex Chen',
        feedbackAddressed: 'Updated regulatory disclaimers and scaled budget.',
      );

      expect(revised.version, equals(2));
      expect(revised.stageIndex, equals(1)); // Reset to Stage 1 (Creative)
      expect(revised.state, equals(CampaignState.pendingReview));

      // Verify diff was generated
      final diff = await repo.getLatestDiff('cmp_03');
      expect(diff, isNotNull);
      expect(diff!.previousVersion, equals(1));
      expect(diff.currentVersion, equals(2));
      expect(diff.diffs.any((d) => d.isMaterial), isTrue);

      // Verify audit event was logged
      final auditEvents = await repo.getAuditEvents('cmp_03');
      expect(auditEvents.any((e) => e.action == 'CAMPAIGN_REVISED_AND_RESUBMITTED'), isTrue);
    });

    test('Scheduling Gate: Unapproved campaign cannot be scheduled; Approved campaign succeeds', () async {
      // cmp_01 is pendingReview -> scheduling must fail
      expect(
        () => repo.scheduleCampaign(
          campaignId: 'cmp_01',
          expectedVersion: 1,
          actorId: 'usr_ops',
          actorName: 'Operations Lead',
        ),
        throwsA(predicate((e) => e.toString().contains('SchedulingGateViolation'))),
      );

      // cmp_04 is approved -> scheduling succeeds
      final scheduled = await repo.scheduleCampaign(
        campaignId: 'cmp_04',
        expectedVersion: 1,
        actorId: 'usr_ops',
        actorName: 'Operations Lead',
      );
      expect(scheduled.state, equals(CampaignState.scheduled));

      final audit = await repo.getAuditEvents('cmp_04');
      expect(audit.first.action, equals('CAMPAIGN_SCHEDULED'));
    });
  });
}

