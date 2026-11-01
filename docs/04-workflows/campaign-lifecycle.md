# Campaign Lifecycle Specification

> **Document Status:** Approved v1.0  
> **Last Updated:** 2026-11-01  
> **Owner:** Domain Research & Requirements Lead  
> **Traces to:** [`problem-statement.md`](../01-problem-understanding/problem-statement.md), [`functional-requirements.md`](../01-problem-understanding/functional-requirements.md), [`non-functional-requirements.md`](../01-problem-understanding/non-functional-requirements.md), [`user-journey-flow.mmd`](user-journey-flow.mmd)

---

## 1. Executive Summary

The campaign lifecycle governs the operational states through which a marketing campaign proposal moves—from initial concept drafting to final scheduling for multi-channel execution. 

Unlike informal content workflows, this platform enforces a **deterministic finite state machine (FSM)**. Every state transition is atomic, validated against explicit business preconditions, protected by optimistic concurrency locking, and logged synchronously into an immutable audit ledger.

The review phase incorporates a **multi-level sequential approval pipeline** (Stage 1: Creative $\rightarrow$ Stage 2: Compliance $\rightarrow$ Stage 3: Finance) and an automated **material change invalidation engine** that prevents post-approval drift.

---

## 2. Formal State Definitions

The platform defines **six primary states** with sequential review progression:

```
 ┌─────────┐      Submit (FR-004)     ┌────────────────────────────────────────────────────────┐
 │  DRAFT  │ ───────────────────────▶ │ PENDING REVIEW                                         │
 └─────────┘                          │                                                        │
      ▲                               │  ┌─────────────────┐  Pass   ┌──────────────────────┐  │
      │                               │  │ Stage 1:        │────────▶│ Stage 2:             │  │
      │                               │  │ Creative Brand  │         │ Legal & Compliance   │  │
      │                               │  │ (ST-002a)       │         │ (ST-002b)            │  │
      │                               │  └────────┬────────┘         └──────────┬───────────┘  │
      │                               │           │                             │              │
      │                               │           │ Pass                        │              │
      │                               │           ▼                             ▼              │
      │                               │  ┌─────────────────┐             Changes / Rejection   │
      │                               │  │ Stage 3:        │──────────────┐                    │
      │                               │  │ Finance & DOA   │              │                    │
      │                               │  │ (ST-002c)       │              │                    │
      │                               │  └────────┬────────┘              │                    │
      │                               └───────────┼───────────────────────┼────────────────────┘
      │                                           │ Final Pass            │
      │                  ┌────────────────────────┴─────────┐             │
      │                  │                                  │             │
      │                  ▼                                  ▼             ▼
      │         ┌─────────────────┐                  ┌─────────────┐┌─────────────────┐
      │ Revise  │ CHANGES         │◀─────────────────┤  REJECTED   ││ CHANGES         │
      │ (FR-010)│ REQUESTED       │  Material Change └──────┬──────┘│ REQUESTED       │
      │         └────────┬────────┘  Invalidation           │       └─────────────────┘
      │                  │           (FR-014)               │ Restart
      │                  ▼                                  ▼ (FR-008)
      │             ┌─────────┐                        ┌─────────┐        ┌───────────┐
      └─────────────│  DRAFT  │                        │  DRAFT  │        │ SCHEDULED │
                    └─────────┘                        └─────────┘        └─────▲─────┘
                         │                                                      │ Schedule (FR-012)
                         └──────────────────────────────────────────────────────┴── [APPROVED] ───┘
```

### 2.1 State Catalog

| State Name | Owning Actor | Data Modifiability | Description & Invariants |
|:---|:---|:---:|:---|
| **`DRAFT`** | Marketer (`ST-001`) | Read / Write | Working proposal copy. The marketer creates and updates campaign metadata, objectives, audience definitions, budget caps, schedule windows, and creative links. **Invariant:** No reviewer decisions or scheduling gates may execute in this state. |
| **`PENDING REVIEW`** | Reviewers (`ST-002a/b/c`) | Read-Only (Locked) | Sequential domain evaluation gate. The proposal payload is frozen into an immutable snapshot (`vN`). Marketers cannot edit the campaign while under review. Encompasses three sequential sub-states: `Stage 1: Creative`, `Stage 2: Compliance`, and `Stage 3: Finance`. **Invariant:** Only authorized reviewers distinct from the creator may act on each stage. |
| **`CHANGES REQUESTED`** | Marketer (`ST-001`) | Read / Write | Actionable feedback gate. A reviewer at any stage requested modifications and attached specific comments to version `vN`. The campaign returns to the marketer to edit and generate working draft `vN+1`. |
| **`REJECTED`** | Reviewers (`ST-002a/b/c`) | Terminal / Reset | Negative determination. The proposal was deemed fundamentally non-viable or non-compliant with brand, regulatory, or budgetary standards. Terminal for the active review cycle; can be restarted to `DRAFT` if desired. |
| **`APPROVED`** | System / Reviewers | Read-Only (Guarded) | Positive determination. All three sequential stages (Creative, Compliance, Finance) have granted explicit sign-offs cryptographically bound to snapshot `vN`. **Invariant:** Any subsequent material modification automatically revokes approval status and reverts the campaign. |
| **`SCHEDULED`** | System (`ST-003`) | Terminal for Scope | Execution gate cleared. The platform verified that the approved version matches the active version with all three stage signatures valid, handing the campaign over to downstream execution adapters. |

---

## 3. Formal State Transition Matrix

The table below defines all legal transitions between primary states. Any transition not explicitly marked as **Allowed** is strictly rejected with a `400 Bad Request` or `409 Conflict`.

| From State $\downarrow$ \ To State $\rightarrow$ | `DRAFT` | `PENDING REVIEW` | `CHANGES REQUESTED` | `REJECTED` | `APPROVED` | `SCHEDULED` |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **`DRAFT`** | — | **Allowed**<br/>*(Submit `FR-004` $\rightarrow$ Stage 1)* | ❌ Illegal | ❌ Illegal | ❌ Illegal | ❌ Illegal |
| **`PENDING REVIEW`** | **Allowed**<br/>*(Withdraw `FR-005` prior to review)* | **Allowed**<br/>*(Advance Stage $k \rightarrow k+1$)* | **Allowed**<br/>*(Changes `FR-009` at any stage)* | **Allowed**<br/>*(Reject `FR-008` at any stage)* | **Allowed**<br/>*(Stage 3 Final Pass `FR-007`)* | ❌ Illegal |
| **`CHANGES REQUESTED`**| ❌ Illegal | **Allowed**<br/>*(Re-submit `FR-010` $\rightarrow$ Stage 1)* | — | ❌ Illegal | ❌ Illegal | ❌ Illegal |
| **`REJECTED`** | **Allowed**<br/>*(Restart `FR-008`)* | ❌ Illegal | ❌ Illegal | — | ❌ Illegal | ❌ Illegal |
| **`APPROVED`** | ❌ Illegal | ❌ Illegal | **Allowed**<br/>*(Material Change Revocation `FR-014`)* | ❌ Illegal | — | **Allowed**<br/>*(Schedule Gate `FR-012`)* |
| **`SCHEDULED`** | ❌ Illegal | ❌ Illegal | ❌ Illegal | ❌ Illegal | ❌ Illegal | — |

---

## 4. Transition Preconditions, Invariants & Postconditions

### 4.1 Transition: `DRAFT` $\rightarrow$ `PENDING REVIEW [Stage 1: Creative]` (Submission)
- **Trigger:** Marketer triggers submission (`FR-004`).
- **Preconditions:**
  1. All mandatory fields populated: `name`, `target_audience`, `budget > 0`, `start_date`, `end_date` (`end_date > start_date`).
  2. Actor must hold `Marketer` role (`FR-017`).
  3. Campaign must currently be in `DRAFT` state.
- **Invariants Enforced:**
  1. An immutable version snapshot (`vN`) is created and hash-digested via SHA-256 (`FR-013`).
  2. Submitter ID is recorded as `created_by` / `submitted_by`.
  3. Review stage index is initialized to `1` (`Stage 1: Creative`).
- **Postconditions:**
  1. Campaign state = `PENDING REVIEW`, `stage_index = 1`.
  2. Immutable audit log entry written: `CampaignSubmittedEvent`.
  3. Asynchronous notification dispatched to Creative Reviewers (`ST-002a`).

---

### 4.2 Transition: `PENDING REVIEW [Stage 1]` $\rightarrow$ `PENDING REVIEW [Stage 2: Compliance]` (Stage 1 Advance)
- **Trigger:** Creative Reviewer approves Stage 1 (`FR-006`, `FR-007`).
- **Preconditions:**
  1. Actor must hold `CreativeReviewer` role (`ST-002a`) (`FR-017`).
  2. **Separation of Duties:** `actor_id != campaign.submitted_by` (`FR-018`).
  3. Campaign must be in `PENDING REVIEW` with `stage_index == 1`.
  4. Version token check must match active `campaign.version` and `snapshot_hash`.
- **Invariants Enforced:**
  1. Stage 1 approval record created: `StageApproval(stage=1, actor_id=ST-002a, snapshot_hash=...)`.
- **Postconditions:**
  1. Campaign `stage_index = 2` (`Stage 2: Compliance`).
  2. Audit log entry written: `Stage1ApprovedEvent`.
  3. Asynchronous notification dispatched to Legal/Compliance Officers (`ST-002b`).

---

### 4.3 Transition: `PENDING REVIEW [Stage 2]` $\rightarrow$ `PENDING REVIEW [Stage 3: Finance]` (Stage 2 Advance)
- **Trigger:** Legal/Compliance Officer approves Stage 2 (`FR-006`, `FR-007`).
- **Preconditions:**
  1. Actor must hold `ComplianceReviewer` role (`ST-002b`).
  2. **Separation of Duties:** `actor_id != campaign.submitted_by`.
  3. Campaign must be in `PENDING REVIEW` with `stage_index == 2`.
  4. Stage 1 approval must exist and match current `snapshot_hash`.
- **Invariants Enforced:**
  1. Stage 2 approval record created: `StageApproval(stage=2, actor_id=ST-002b, snapshot_hash=...)`.
- **Postconditions:**
  1. Campaign `stage_index = 3` (`Stage 3: Finance`).
  2. Audit log entry written: `Stage2ApprovedEvent`.
  3. Asynchronous notification dispatched to Finance Approvers (`ST-002c`).

---

### 4.4 Transition: `PENDING REVIEW [Stage 3]` $\rightarrow$ `APPROVED` (Final Stage Authorization)
- **Trigger:** Finance Approver approves Stage 3 (`FR-007`).
- **Preconditions:**
  1. Actor must hold `FinanceApprover` role (`ST-002c`).
  2. **Separation of Duties:** `actor_id != campaign.submitted_by`.
  3. Campaign must be in `PENDING REVIEW` with `stage_index == 3`.
  4. Stages 1 and 2 approvals must exist and match current `snapshot_hash`.
- **Invariants Enforced:**
  1. Stage 3 approval record created: `StageApproval(stage=3, actor_id=ST-002c, snapshot_hash=...)`.
  2. Full cryptographic approval binding established linking `snapshot_vN.hash` with all three signatures.
- **Postconditions:**
  1. Campaign state = `APPROVED`.
  2. Campaign `approved_version = vN`.
  3. Audit log entry written: `CampaignApprovedEvent`.
  4. Notification dispatched to Marketer confirming full clearance for scheduling.

---

### 4.5 Transition: `PENDING REVIEW [Any Stage]` $\rightarrow$ `CHANGES REQUESTED` (Request Changes)
- **Trigger:** Reviewer at Stage 1, 2, or 3 requests revisions (`FR-009`).
- **Preconditions:**
  1. Actor must be authorized for current stage.
  2. `actor_id != campaign.submitted_by` (Separation of duties).
  3. Reviewer must provide mandatory structured feedback comments.
  4. Version token check must succeed.
- **Postconditions:**
  1. Campaign state = `CHANGES REQUESTED`.
  2. Feedback notes permanently attached to `vN` snapshot history tagged with the originating stage.
  3. Audit log entry written: `ChangesRequestedEvent`.
  4. Marketer notified with specific stage feedback.

---

### 4.6 Transition: `CHANGES REQUESTED` $\rightarrow$ `PENDING REVIEW [Stage 1]` (Re-submission)
- **Trigger:** Marketer re-submits revised proposal (`FR-010`).
- **Preconditions:**
  1. Actor must be the campaign creator / marketer.
  2. Working draft edits must satisfy all mandatory validation rules.
- **Postconditions:**
  1. New immutable snapshot created: `version = vN + 1` with new SHA-256 digest (`FR-013`).
  2. Prior stage approval records archived as superseded.
  3. Campaign state = `PENDING REVIEW`, `stage_index = 1` (resets to Stage 1 Creative).
  4. Audit log entry written: `CampaignResubmittedEvent`.
  5. Creative Reviewers notified to inspect revised snapshot `vN+1`.

---

### 4.7 Transition: `PENDING REVIEW [Any Stage]` $\rightarrow$ `REJECTED` (Rejection)
- **Trigger:** Reviewer rejects proposal (`FR-008`).
- **Preconditions:**
  1. Actor must be authorized for current stage.
  2. Reviewer must provide mandatory rejection rationale.
  3. Version token check must succeed.
- **Postconditions:**
  1. Campaign state = `REJECTED`.
  2. Audit log entry written: `CampaignRejectedEvent`.
  3. Terminal for active cycle. Marketer notified.

---

### 4.8 Transition: `APPROVED` $\rightarrow$ `SCHEDULED` (Scheduling Gate)
- **Trigger:** Marketer or scheduler triggers release (`FR-012`).
- **Preconditions:**
  1. Campaign must currently be in `APPROVED` state.
  2. **Cryptographic Integrity Verification:** Active proposal payload digest must match `approved_version` snapshot digest (`NFR-002`).
  3. All three stage approvals (Creative, Compliance, Finance) must be present and valid for the current digest.
- **Postconditions:**
  1. Campaign state = `SCHEDULED`.
  2. Audit log entry written: `CampaignScheduledEvent`.
  3. Outbox event emitted for downstream scheduling/delivery adapters.

---

### 4.9 Transition: `APPROVED` $\rightarrow$ `CHANGES REQUESTED` (Material Change Invalidation)
- **Trigger:** Marketer or system commits a material modification to an approved campaign (`FR-014`).
- **Material Change Evaluation:**
  - Budget delta $\ge \pm 10\%$ or crosses DOA threshold.
  - Audience demographic/geographic pivot or list size variance $> 15\%$.
  - Content copy, claims, creative assets, or disclaimers edited.
  - Schedule start/end dates shifted $> 72$ hours.
- **Postconditions:**
  1. System revokes all three stage approval tokens.
  2. Campaign state transitions to `CHANGES REQUESTED` (or `DRAFT`), locking the scheduling gate (`FR-012`).
  3. Version counter increments ($vN \rightarrow vN+1$).
  4. Audit log entry written: `ApprovalRevokedEvent` (Reason: Material change detected).
  5. Marketer notified to re-submit proposal through the sequential approval pipeline.

---

## 5. Concurrency & Collision Rules

To prevent conflicting or stale approvals across mobile devices:
1. **Version Vector / ETag:** Every campaign record carries an integer `version` field and a `stage_index` field.
2. **Optimistic Locking:** When a reviewer submits a decision (e.g., `ADVANCE_STAGE`), the update query must match both `version` and `stage_index`:
   ```sql
   UPDATE campaigns 
   SET stage_index = stage_index + 1, version = version + 1, updated_at = NOW()
   WHERE id = :campaign_id 
     AND version = :expected_version 
     AND stage_index = :expected_stage 
     AND state = 'PENDING_REVIEW';
   ```
3. **Collision Outcome:** If rows affected equals 0, the platform rejects the incoming request with a `409 Conflict` error, preventing duplicate or stale approvals.

---

## 6. Audit Trail Event Mapping

Every lifecycle state transition generates an immutable domain event written synchronously to the audit log table:

| Lifecycle Transition | Audit Event Type | Payload Attributes Captured |
|:---|:---|:---|
| Draft Creation | `CampaignCreated` | `campaign_id`, `creator_id`, `timestamp`, `initial_name` |
| Submission | `CampaignSubmitted` | `campaign_id`, `version`, `submitter_id`, `snapshot_hash`, `initial_stage=1` |
| Stage 1 Creative Pass | `Stage1Approved` | `campaign_id`, `version`, `reviewer_id`, `stage=1`, `snapshot_hash` |
| Stage 2 Compliance Pass | `Stage2Approved` | `campaign_id`, `version`, `reviewer_id`, `stage=2`, `snapshot_hash` |
| Stage 3 Finance Sign-off | `CampaignApproved` | `campaign_id`, `version`, `reviewer_id`, `stage=3`, `snapshot_hash`, `doa_tier` |
| Changes Requested | `ChangesRequested` | `campaign_id`, `version`, `reviewer_id`, `stage_index`, `feedback_text` |
| Re-submission | `CampaignResubmitted` | `campaign_id`, `new_version`, `submitter_id`, `snapshot_hash`, `diff_summary` |
| Rejection | `CampaignRejected` | `campaign_id`, `version`, `reviewer_id`, `stage_index`, `rejection_reason` |
| Material Invalidation | `ApprovalRevoked` | `campaign_id`, `revoked_version`, `actor_id`, `material_fields_changed` |
| Scheduling Clearance | `CampaignScheduled` | `campaign_id`, `scheduled_version`, `actor_id`, `release_time`, `snapshot_hash` |
