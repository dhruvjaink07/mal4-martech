# Functional Requirements

> **Document Status:** Draft v1.0
> **Last Updated:** 2026-11-01
> **Owner:** Domain Research & Requirements Lead
> **Traces to:** [Problem Statement](problem-statement.md), [Stakeholders](stakeholders.md)

---

## Overview

Functional requirements are organised by domain capability. Each requirement has a stable ID for traceability across architecture documents.

Requirements are prioritised using MoSCoW:

- **Must** — Required for the core campaign review & approval workflow. Must be addressed in the architecture.
- **Should** — Important for a complete system. Should be designed but may be simplified in the MAL4 deliverable.
- **Could** — Desirable enhancements. Acknowledged in the architecture but not necessarily implemented.
- **Won't (this time)** — Explicitly out of scope for the initial architecture.

---

## 1. Campaign Management

### FR-001: Campaign Creation — Must

The system must allow an authenticated Marketer (ST-001) to create a new campaign in **Draft** state.

A campaign must include the following minimum metadata:

| Field | Type | Required | Notes |
|---|---|---|---|
| Campaign name | Text | Yes | Human-readable identifier |
| Objective / description | Text | Yes | Purpose and goals of the campaign |
| Target audience | Text / structured | Yes | Description or reference to audience segment |
| Budget | Numeric | Yes | Planned spend amount |
| Schedule | Date range | Yes | Proposed start and end dates |
| Channel(s) | Enum / list | Should | Email, social, paid media, etc. |
| Content references | References / text | Should | Links or references to creative assets |

**Business rule:** A newly created campaign is always in **Draft** state. No approval actions are permitted on a Draft campaign that has not been submitted.

---

### FR-002: Campaign Editing — Must

The system must allow a Marketer to edit a campaign when it is in **Draft** or **Changes Requested** state.

**Business rules:**
- A campaign in **Pending Review**, **Approved**, or **Scheduled** state cannot be directly edited.
- Editing a campaign in **Draft** state modifies the current working version.
- Editing a campaign in **Changes Requested** state creates a new version (see FR-013).
- Only the campaign creator or a user with the Marketer role and appropriate permissions may edit a campaign.

---

### FR-003: Campaign Deletion — Could

The system could allow a Marketer to delete a campaign in **Draft** state. Campaigns that have entered the review process (any state beyond Draft) should not be permanently deleted — they should be archived.

**Business rule:** Deletion is a soft delete (archival). The audit trail must be preserved.

---

## 2. Campaign Submission

### FR-004: Submit for Review — Must

The system must allow a Marketer to submit a campaign for review, transitioning it from **Draft** to **Pending Review** state.

**Business rules:**
- All required fields must be populated before submission is allowed (validation).
- Submission creates an immutable snapshot (version) of the campaign. This is the version that reviewers evaluate. (See FR-013.)
- The Marketer cannot edit the campaign while it is in **Pending Review** state.
- Submission must record: submitter identity, timestamp, and version number.

---

### FR-005: Withdraw Submission — Should

The system should allow a Marketer to withdraw a campaign from review, transitioning it from **Pending Review** back to **Draft** state, provided no reviewer has yet acted on it.

**Business rules:**
- If a reviewer has already submitted an approval decision (approve, reject, or request changes), withdrawal is not permitted.
- Withdrawal must be recorded in the audit trail.

> **Open question (OQ-010):** Should withdrawal be allowed after partial reviews in a multi-reviewer scenario? (e.g., one reviewer approved, but others haven't acted yet.)

---

## 3. Review and Approval Workflow

### FR-006: Review Campaign (Multi-Level Sequential Pipeline) — Must

The system must route submitted campaigns through a structured, multi-level sequential review pipeline comprising three mandatory domain gates:

```
[Draft / Revision] ──Submit──▶ [Stage 1: Creative Review]
                                      │ (Pass)
                                      ▼
                               [Stage 2: Compliance Review]
                                      │ (Pass)
                                      ▼
                               [Stage 3: Finance Authorization]
                                      │ (Final Pass)
                                      ▼
                                  [APPROVED]
```

1. **Stage 1: Creative & Brand Review (`ST-002a`)** — Verifies brand voice, visual assets, creative copy, and marketing objective alignment.
2. **Stage 2: Legal & Compliance Audit (`ST-002b`)** — Verifies regulatory disclosures, GDPR/CAN-SPAM consent requirements, claim disclaimers, and prohibited audience segmenting.
3. **Stage 3: Finance & Budget Authorization (`ST-002c`)** — Verifies budget cost centers, delegation-of-authority (DOA) financial caps, and spend justification under SOX 404.

**Reviewer actions at any stage:**
1. **Approve / Advance** — Stage criteria met. If Stage 1 or 2, advances campaign to next stage (`Pending Review [Stage k+1]`). If Stage 3, transitions campaign to `Approved` (`FR-007`).
2. **Request Changes** — Campaign requires specific modifications before it can clear the current stage. Transitions campaign to `Changes Requested` (`FR-009`) and returns to Marketer.
3. **Reject** — Campaign is fundamentally unsuitable or non-compliant. Transitions campaign to `Rejected` (`FR-008`), terminating the review cycle.

**Business rules:**
- A Reviewer can only act on campaigns in **Pending Review** at their authorized stage.
- The Reviewer must be reviewing the current submitted version snapshot (`snapshot_hash`).
- Strict Separation of Duties: A Reviewer cannot review a campaign they submitted (`submitted_by_id != reviewer_id`).
- Each review action records: reviewer ID, decision, stage index, timestamp, snapshot hash, and mandatory feedback comments for rejections/changes requested.

---

### FR-007: Approval Decision & Stage Progression — Must

When an authorized reviewer approves a campaign at a given stage, the system must atomically record the stage approval and transition the campaign forward:

**Progression rules:**
- **Stage 1 (Creative) Approval:** Records `StageApproval(stage=1, reviewer=ST-002a)`. Moves campaign to `Pending Review [Stage 2: Compliance]`. Notifies Legal/Compliance reviewers.
- **Stage 2 (Compliance) Approval:** Records `StageApproval(stage=2, reviewer=ST-002b)`. Moves campaign to `Pending Review [Stage 3: Finance]`. Notifies Finance approvers.
- **Stage 3 (Finance) Approval (Final Gate):** Records `StageApproval(stage=3, reviewer=ST-002c)`. Transitions campaign from `Pending Review` to **`Approved`** state. Notifies Submitting Marketer and unlocks the Scheduling Gate (`FR-012`).

**Business rules:**
- The approval is cryptographically bound to the immutable version snapshot (`snapshot_hash`). If the campaign is subsequently modified, all prior stage approvals are invalidated (see FR-014).
- All stage approval records are immutable, append-only, and preserved in the audit log.

> **Defensible Architecture Position (Multi-Level Approval vs. Single Gate):**
> - *Why Chosen:* Single-gate models allow generalist marketers to approve complex legal disclaimers or junior managers to authorize six-figure ad budgets, violating SOX 404 Section 8 and FINRA Rule 2210. A sequential pipeline enforces strict segregation of duties (SoD) while serving as a progressive quality filter (filtering creative flaws before consuming expensive legal and finance hours).
> - *Why Not Single Gate:* Fails compliance audits and creates liability.
> - *Why Not BPMN Workflow Engine:* Over-engineering. A deterministic 3-stage state machine avoids heavy external engine dependencies, distributed transaction failures, and dual-state synchronization bugs.

---

### FR-008: Rejection Decision — Must

When a Reviewer rejects a campaign, the system must transition it from **Pending Review** to **Rejected** state.

**Business rules:**
- The Reviewer must provide a reason for rejection.
- A rejected campaign can be moved back to **Draft** by the Marketer to begin a new revision cycle if desired.
- Rejection is a terminal state for the current review cycle — a new submission starts a new cycle.

---

### FR-009: Request Changes Decision — Must

When a Reviewer requests changes, the system must transition the campaign from **Pending Review** to **Changes Requested** state.

**Business rules:**
- The Reviewer must provide feedback describing the required changes.
- The campaign returns to the Marketer for revision (see FR-010).
- The specific feedback must be associated with the version under review.

---

### FR-010: Campaign Revision — Must

The system must allow a Marketer to revise a campaign in **Changes Requested** state and re-submit it for review.

**Business rules:**
- Revising a campaign creates a new version (see FR-013).
- Re-submission transitions the campaign from **Changes Requested** back to **Pending Review**.
- The new version is the one reviewed — reviewers should be able to see what changed from the previous version.
- The revision/re-submission cycle can repeat until the campaign is approved or rejected.

---

### FR-011: Review Feedback Visibility — Should

The system should make reviewer feedback visible to the Marketer when a campaign is in **Changes Requested** state.

**Requirements:**
- Feedback must be associated with the specific campaign version it was given on.
- Historical feedback from previous review cycles should be accessible.

---

## 4. Campaign Scheduling Gate

### FR-012: Scheduling Gate & Verification — Must

The system must enforce that only campaigns in **Approved** state that have fully cleared all three sequential approval stages can transition to **Scheduled** state.

**Business rules:**
- A campaign cannot be scheduled if it is in any state other than **Approved**.
- **Cryptographic Gate Verification:** The scheduling action must verify that:
  1. The campaign is currently in `Approved` state.
  2. All three stage approvals (Creative, Compliance, Finance) exist and match the SHA-256 digest (`snapshot_hash`) of the current version snapshot.
  3. No subsequent material changes have occurred since the final stage approval was granted.
- Scheduling must record: who initiated scheduling, server timestamp, version scheduled, and the immutable snapshot digest.
- Transitioning to Scheduled triggers an asynchronous `CampaignScheduledEvent` via the Transactional Outbox to the external execution/scheduling adapter.

> **Scope note:** The actual message delivery mechanism (ad placement, push dispatch, email broadcast) is out of scope. The system strictly enforces the governance gate — only fully approved, unmutated campaigns can be marked as scheduled.

---

## 5. Version Management & Invalidation

### FR-013: Campaign Versioning — Must

The system must maintain an immutable version history for each campaign.

**Requirements:**
- A new version is created when:
  - A campaign is submitted for review (FR-004).
  - A campaign is revised after changes are requested (FR-010).
  - A material change occurs on an approved or in-review campaign (FR-014).
- Each version captures a complete snapshot of the campaign state at that point in time (`snapshot_hash` SHA-256 digest).
- Versions are numbered sequentially (v1, v2, v3, ...).
- Previous version snapshots are strictly read-only and immutable.
- Approval decisions are bound to specific `(version_number, snapshot_hash)` tuples.

**Business rules:**
- The "current version" is the most recent version.
- A campaign in **Approved** state has approvals linked to a specific snapshot digest. If campaign parameters mutate, the digest diverges, immediately triggering change detection and approval invalidation.

---

### FR-014: Material Change Detection & Approval Invalidation — Must

The system must detect when material changes are made to an approved or in-review campaign, immediately invalidate existing approval sign-offs, increment the version, and require re-approval.

**1. Classification of Campaign Modifications:**

| Parameter Category | Change Scope | Classification | System Reaction | Rationale |
|:---|:---|:---:|:---|:---|
| **Budget Modification** | Spend delta $\ge \pm 10\%$ OR crosses DOA tier | **Material** | Invalidate Approval $\rightarrow$ Reset to Stage 1 or Changes Requested | SOX 404 financial authorization limits; spend commitments must be re-cleared by Finance (`ST-002c`). |
| **Target Audience Scope** | Geo/demographic shift OR list size variance $> 15\%$ | **Material** | Invalidate Approval $\rightarrow$ Reset to Stage 1 or Changes Requested | Privacy/GDPR regulatory compliance; targeting new segments requires fresh compliance review (`ST-002b`). |
| **Content Copy / Claims** | Headline, body, promotional terms, or disclaimer edits | **Material** | Invalidate Approval $\rightarrow$ Reset to Stage 1 or Changes Requested | Brand safety and advertising truth-in-advertising laws (FTC/FINRA); requires Creative (`ST-002a`) and Legal (`ST-002b`) review. |
| **Schedule Window** | Launch date shifted $> 72$ hours or window lengthened | **Material** | Invalidate Approval $\rightarrow$ Reset to Stage 1 or Changes Requested | Channel capacity, seasonal offer validity, and financial quarterly booking alignment. |
| **Operational Tags & UTMs** | Internal tracking tags, UTM campaign labels, notes | **Non-Material** | Retain Approval $\rightarrow$ Append to Audit Trail | Operational telemetry parameters that do not alter customer-facing messaging, budget liability, or legal exposure. |

**2. System Invalidation Behavior:**
- When a material change is committed on an **`Approved`** campaign:
  1. The system revokes the approval sign-off tokens.
  2. The campaign transitions from **`Approved`** to **`Changes Requested`** (or **`Draft`**), locking the scheduling gate (`FR-012`).
  3. A new version snapshot is generated ($vN \rightarrow vN+1$).
  4. An `ApprovalRevokedEvent` is written atomically to the audit trail and the Transactional Outbox.
  5. The campaign must be re-submitted and clear the sequential approval pipeline before scheduling can occur.
- When a material change is committed on a campaign in **`Pending Review`** (e.g., at Stage 2):
  1. Prior stage approvals (Stage 1 Creative) are invalidated.
  2. The review pipeline resets to **Stage 1** on the new version snapshot $vN+1$.

> **Defensible Architecture Position (Material Change Detection vs. Alternatives):**
> - *Why Chosen:* Eliminates "post-approval drift" (the catastrophic governance failure where version 1 is approved, but modified version 2 with doubled budget and unvetted claims is published). Restricting invalidation strictly to *material* modifications prevents unnecessary approval churn and delays for harmless internal operational tag edits.
> - *Why Not Invalidate on Every Edit:* Paralyzes marketing agility; forcing an executive re-approval loop across 3 directors because a marketer adjusted a campaign tracking tag leads users to bypass the system.
> - *Why Not Silent Mutation:* Zero governance; exposes the firm to uncapped budget overruns, deceptive advertising lawsuits, and regulatory sanctions.

---

## 6. Audit Trail

### FR-015: Audit Logging — Must

The system must record an immutable audit trail of all significant campaign lifecycle events.

**Each audit entry must capture:**

| Field | Description |
|---|---|
| Event ID | Unique identifier for the event |
| Timestamp | When the action occurred (server time, UTC) |
| Actor | Who performed the action (user ID) |
| Action | What was done (created, submitted, approved, rejected, changes_requested, revised, scheduled) |
| Campaign ID | Which campaign was affected |
| Version | Which campaign version was affected |
| Details | Additional context (e.g., reviewer feedback, reason for rejection) |

**Business rules:**
- Audit entries are append-only. They cannot be modified or deleted.
- The audit trail must support reconstruction of the complete approval history for any campaign.
- Audit entries must be queryable by campaign, by actor, and by time range.

---

### FR-016: Approval History View — Should

The system should provide a view of the complete approval history for a campaign, showing:
- All versions submitted.
- Review decisions made on each version (with reviewer identity, timestamp, and feedback).
- Current approval status.

**Stakeholder:** Primarily for Reviewers (ST-002) and System Administrators (ST-003). Also valuable for Marketers (ST-001) to track progress.

---

## 7. Access Control

### FR-017: Role-Based Access Control — Must

The system must enforce role-based access control (RBAC) with at minimum the following roles:

| Role | Permissions |
|---|---|
| **Marketer** | Create, edit (Draft/Changes Requested), submit, withdraw, view own campaigns |
| **Reviewer** | View submitted campaigns, approve, reject, request changes |
| **Admin** | All Marketer and Reviewer permissions, plus: manage users, configure workflows, view audit logs, view all campaigns |

**Business rules:**
- A user must be authenticated to perform any action.
- A Reviewer cannot review a campaign they created or submitted (FR-006).
- Role assignments are managed by the System Administrator (ST-003).
- Permissions are checked on every state-transitioning action.

---

### FR-018: Self-Review Prevention — Must

The system must prevent a user from approving, rejecting, or requesting changes on a campaign they submitted.

**Rationale:** Separation of duties is a fundamental governance control confirmed across all major MarTech platforms (Marketo separates edit/approve permissions, Salesforce separates Submitter/Approver roles).

---

## 8. Notifications — Should

### FR-019: Lifecycle Notifications — Should

The system should notify relevant stakeholders when campaign state transitions occur.

| Event | Notify |
|---|---|
| Campaign submitted for review | Assigned Reviewer(s) |
| Campaign approved | Submitting Marketer |
| Campaign rejected | Submitting Marketer |
| Changes requested | Submitting Marketer |
| Revised campaign re-submitted | Assigned Reviewer(s) |

**Business rule:** Notification delivery failure must not block the state transition. Notifications are best-effort and eventually consistent. (See A-009.)

> **Architecture Lead input needed:** Notification mechanism (in-app, push, email) and reliability guarantees to be determined during solution design.

---

## Campaign State Summary

The following states and sub-states emerge from the functional requirements:

| State | Review Stage Sub-State | Entered via | Exit transitions | Owning actor |
|---|---|---|---|---|
| **Draft** | — | FR-001 (creation), FR-005 (withdrawal), FR-008 (post-rejection restart) | Submit (→ Pending Review [Stage 1]) | Marketer |
| **Pending Review** | `Stage 1: Creative` | FR-004 (submission), FR-010 (re-submission) | Advance (→ Stage 2), Reject (→ Rejected), Request Changes (→ Changes Requested), Withdraw (→ Draft) | Creative Reviewer (`ST-002a`) |
| **Pending Review** | `Stage 2: Compliance` | Advance from Stage 1 | Advance (→ Stage 3), Reject (→ Rejected), Request Changes (→ Changes Requested) | Legal/Compliance (`ST-002b`) |
| **Pending Review** | `Stage 3: Finance` | Advance from Stage 2 | Final Approve (→ Approved), Reject (→ Rejected), Request Changes (→ Changes Requested) | Finance Approver (`ST-002c`) |
| **Changes Requested** | — | FR-009 (from any stage) | Revise + Re-submit (→ Pending Review [Stage 1]) | Marketer |
| **Approved** | — | FR-007 (Stage 3 pass) | Schedule (→ Scheduled), Material Change (→ Changes Requested / Draft) | System / Marketer |
| **Rejected** | — | FR-008 (from any stage) | Restart (→ Draft) | Marketer |
| **Scheduled** | — | FR-012 | — (terminal governance gate for this system's scope) | System / Scheduler |

> **Note:** This state model completely satisfies the MAL4 expected lifecycle (Draft → Pending Review → Changes Requested → Approved → Scheduled) while supporting the 3-stage sequential review pipeline and explicit rejected/restart paths.

---

## Requirements Traceability

| Requirement | Stakeholder(s) | MAL4 Criterion |
|---|---|---|
| FR-001 to FR-003 | ST-001 (Marketer) | Structure & boundaries, Working user journey |
| FR-004 to FR-005 | ST-001 (Marketer) | Data & state management |
| FR-006 to FR-011 | ST-001, ST-002a, ST-002b, ST-002c (Reviewers) | Data & state management, Working user journey, Architecture Defence |
| FR-012 | ST-001, ST-002c, System | Structure & boundaries |
| FR-013 to FR-014 | ST-001, ST-002a/b/c, ST-005 | Data & state management, Trade-offs & Defence |
| FR-015 to FR-016 | ST-002a/b/c, ST-003, ST-005 | Testing & observability |
| FR-017 to FR-018 | ST-003, ST-005 | Structure & boundaries |
| FR-019 | ST-001, ST-002a/b/c | Failure & recovery handling |

---

## Assumptions

| ID | Assumption | Traces to | Status |
|---|---|---|---|
| A-010 | A campaign version is a complete snapshot, not a diff. This simplifies comparison and guarantees $O(1)$ mobile reads. | FR-013 | High (Resolved) |
| A-011 | The system implements a **multi-level sequential approval pipeline** (Stage 1: Creative → Stage 2: Compliance/Legal → Stage 3: Finance/Budget). All 3 must approve for the campaign to clear the scheduling gate. | FR-006, FR-007 | High (Resolved) |
| A-012 | Campaign state transitions are synchronous and strongly consistent via database optimistic concurrency control (`WHERE id = :id AND version = :v`). | FR-006, FR-007, FR-008, FR-009 | High (Resolved) |
| A-015 | Any material change (budget $\ge \pm 10\%$, audience pivot, claims/disclaimer change, date shift $>72$h) invalidates approval and re-enters the review loop. | FR-014 | High (Resolved) |

---

## Open Questions

| ID | Question | Traces to | Status | Defensible Resolution |
|---|---|---|---|---|
| OQ-001 | Should the system support multi-level (sequential) approval stages? | FR-006, FR-007 | **Resolved** | **Adopted.** 3-stage sequential pipeline (Creative → Legal → Finance) enforced to eliminate regulatory liability and SoD breaches. |
| OQ-002 | How granular should material change detection be for re-approval triggering? | FR-014 | **Resolved** | **Material Change Classification Adopted.** Material parameters (budget, audience, claims, dates) invalidate approvals. Operational UTM tags do not. |
| OQ-009 | Single-approval vs. consensus-approval model? | FR-007 | **Resolved** | **Sequential Stage Gate.** 1 authorized domain specialist required per stage across 3 sequential stages. |
| OQ-010 | Can a submission be withdrawn after partial reviewer action? | FR-005 | Open | Withdrawal blocked once formal review action has commenced on current snapshot. |
| OQ-011 | Should campaigns support collaborative editing (multiple Marketers editing the same draft)? | FR-002 | Open | Single-editor locking via optimistic concurrency control for v1. |
| OQ-012 | Should the system enforce review deadlines or SLAs for pending reviews? | Future Scope | Deferred | SLA monitoring and reminder escalations deferred to post-hackathon. |
| OQ-013 | Should a rejected campaign allow direct re-submission, or must it go through a full Draft → Submit cycle? | FR-008 | **Resolved** | Must transition to Draft, bump version, and re-enter via Stage 1. |
