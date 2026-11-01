---
name: flutter-testing-quality
description: Use when creating and executing unit, widget, and integration tests for the MAL4 MarTech Campaign Review & Approval Flutter app. Verifies domain invariants (anti-self-approval, monotonic stage progression, material change invalidation), widget rendering, mock repository behavior, state transition flows, and test coverage for the MAL4 Testing & Observability rubric. Trigger on requests like "write Flutter tests", "verify domain invariants in tests", "test the 3-stage review flow", "create widget tests", or "verify test coverage".
---

# Flutter Testing & Quality Assurance — MAL4 MarTech Platform

Act as a **Staff Mobile QA & Test Automation Architect** for the MAL4 MarTech Campaign Review & Approval Flutter application.

## 1. Purpose & Quality Standards

Deliver a comprehensive, deterministic test suite verifying the Flutter prototype. Testing directly addresses **15% of the MAL4 Evaluation Rubric** (*Testing & Observability*).

The test suite must mathematically prove that the mobile application:
1. Enforces all **Domain Invariants** (Anti-Self-Approval, Monotonic Stage Progression, Material Change Invalidation, Scheduling Gate Clearance).
2. Handles **Edge Cases & Failure Modes** (OCC 409 collisions, network retry idempotency, validation errors).
3. Renders pixel-perfect **Widgets & Ergonomic Touch Targets** ($\ge 48\times 48\text{dp}$).
4. Executes the full **End-to-End User Journey** across Marketer, Creative Reviewer, Compliance Officer, and Finance Approver personas without relying on external cloud infrastructure.

---

## 2. When to Use This Skill

Activate this skill when:
- Writing unit tests for pure Dart domain entities, value objects, and business rules.
- Writing unit tests for `MockCampaignRepository` and `MockReviewRepository`.
- Writing controller/notifier tests verifying state transitions (`loading`, `loaded`, `conflict`, `error`).
- Writing widget tests verifying rendering, button tap handlers, and dialogs.
- Creating integration user journey tests demonstrating the complete 3-stage review lifecycle.
- Measuring and reporting code coverage and quality metrics for hackathon evaluation.

---

## 3. Testing Taxonomy & Directory Layout

```
test/
├── unit/                              # Pure Dart unit tests (Fast, no Flutter engine required)
│   ├── domain/
│   │   ├── budget_allocation_test.dart       # Materiality thresholds (+-10%, DOA tiers)
│   │   ├── audience_criteria_test.dart       # Audience variance (>15%) materiality
│   │   ├── schedule_window_test.dart         # Date shift (>72h) materiality
│   │   └── campaign_aggregate_test.dart      # Anti-Self-Approval, stage invariants
│   └── data/
│       ├── mock_campaign_repository_test.dart # CRUD, OCC version checking, 409 collisions
│       └── mock_review_repository_test.dart   # Stage advancement, idempotency caching
│
├── presentation/                      # State controller & notifier tests
│   ├── campaign_list_controller_test.dart
│   └── review_controller_test.dart
│
├── widgets/                           # Component & screen widget tests
│   ├── status_badge_test.dart                # Visual badge colors & labels
│   ├── stage_progress_bar_test.dart          # Multi-step progress indicator
│   ├── field_diff_tile_test.dart             # Side-by-side diff highlighting
│   └── review_action_sheet_test.dart         # Touch targets & button handlers
│
└── integration/                       # Full user journey integration tests
    ├── full_approval_journey_test.dart       # Draft -> S1 -> S2 -> S3 -> Approved -> Scheduled
    ├── revision_loop_journey_test.dart       # S2 Changes Req -> Edit -> Reset to S1 -> Re-approval
    └── material_invalidation_test.dart       # Approved -> Material Edit -> Approval Revoked
```

---

## 4. Key Test Implementations & Verification Scenarios

### 4.1 Domain Invariant Tests (`test/unit/domain/campaign_aggregate_test.dart`)

```dart
void main() {
  group('Campaign Aggregate Invariant Tests', () {
    test('Anti-Self-Approval: Creator cannot approve own campaign', () {
      final campaign = Campaign.fixture(submittedById: 'user_alex');
      
      expect(
        () => campaign.advanceStage(
          reviewerId: 'user_alex', // Same as creator
          stageIndex: 1,
        ),
        throwsA(isA<SeparationOfDutiesViolationException>()),
      );
    });

    test('Monotonic Stage Progression: Cannot skip Stage 1 to approve Stage 2', () {
      final campaign = Campaign.fixture(stageIndex: 1, state: CampaignState.pendingReview);
      
      expect(
        () => campaign.advanceStage(
          reviewerId: 'user_marcus',
          stageIndex: 2, // Attempting Stage 2 before Stage 1 approved
        ),
        throwsA(isA<IllegalStageTransitionException>()),
      );
    });

    test('Material Change: 20% budget increase invalidates approval', () {
      final approvedCampaign = Campaign.fixture(
        state: CampaignState.approved,
        budget: BudgetAllocation(amount: 10000, currency: 'USD'),
      );
      
      final updated = approvedCampaign.modifyParameters(
        newBudget: BudgetAllocation(amount: 12500, currency: 'USD'), // +25%
      );

      expect(updated.state, equals(CampaignState.changesRequested));
      expect(updated.stageIndex, equals(1)); // Reset to Stage 1
      expect(updated.version, equals(approvedCampaign.version + 1));
    });
  });
}
```

---

### 4.2 Optimistic Concurrency Control (OCC) Tests (`test/unit/data/mock_campaign_repository_test.dart`)

```dart
test('OCC Collision: Stale version update throws ConflictFailure (409)', () async {
  final repo = MockCampaignRepository();
  final campaign = await repo.getCampaignById('cmp_01'); // version = 1
  
  // First reviewer updates campaign to version 2
  await repo.advanceStage(campaignId: 'cmp_01', expectedVersion: 1, currentStage: 1, reviewerId: 'rev_1');

  // Second reviewer attempts to act with stale version 1
  expect(
    () => repo.advanceStage(campaignId: 'cmp_01', expectedVersion: 1, currentStage: 1, reviewerId: 'rev_2'),
    throwsA(isA<ConflictFailure>()),
  );
});
```

---

### 4.3 Widget Ergonomics & Touch Target Tests (`test/widgets/review_action_sheet_test.dart`)

```dart
testWidgets('ReviewActionSheet enforces >= 48dp touch targets', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReviewActionSheet(stageIndex: 1, campaign: testCampaign),
      ),
    ),
  );

  final approveButton = tester.getRect(find.byKey(const Key('btn_approve_stage')));
  expect(approveButton.height, greaterThanOrEqualTo(48.0));
  expect(approveButton.width, greaterThanOrEqualTo(48.0));
});
```

---

### 4.4 End-to-End User Journey Integration Test (`test/integration/full_approval_journey_test.dart`)

Simulates the complete core user journey across all personas:
1. **Marketer:** Creates campaign `DRAFT` $\rightarrow$ Submits for review $\rightarrow$ Locks snapshot `v1`.
2. **Creative Reviewer (`ST-002a`):** Inspects $v1$ $\rightarrow$ Grants Stage 1 Approval $\rightarrow$ Stage index advances to 2.
3. **Legal/Compliance Officer (`ST-002b`):** Inspects $v1$ $\rightarrow$ Grants Stage 2 Approval $\rightarrow$ Stage index advances to 3.
4. **Finance Approver (`ST-002c`):** Inspects $v1$ budget $\rightarrow$ Grants Final Approval $\rightarrow$ State transitions to `APPROVED`.
5. **System / Scheduler:** Verifies all 3 signatures against `snapshot_hash` $\rightarrow$ Transitions state to `SCHEDULED`.

---

## 5. Constraints & Exclusions

- **NO Live Network Tests:** All tests run locally and deterministically against in-memory mock repositories with zero external internet dependencies.
- **NO Firebase Tests:** Do NOT include Firebase Auth or Firestore mocking dependencies.
- **Fast Execution Standard:** The entire test suite must execute in $< 15\text{ seconds}$ on standard developer machines (`flutter test`).

---

## 6. Expected Output Artifacts

When executing tasks under this skill:
1. Well-structured test files residing in `test/{unit,presentation,widgets,integration}/`.
2. Comprehensive test assertions covering both happy paths and edge cases (400, 403, 409).
3. Test failure diagnostics and reproduction scripts for identified bugs.
4. Code coverage summaries verifying compliance with the MAL4 testing rubric.

