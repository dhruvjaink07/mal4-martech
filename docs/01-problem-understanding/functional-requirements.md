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

### FR-006: Review Campaign — Must

The system must allow an authorised Reviewer (ST-002) to review a submitted campaign.

**Reviewer actions:**
1. **Approve** — The campaign meets all standards and is authorised to proceed.
2. **Reject** — The campaign is fundamentally unsuitable and should not proceed.
3. **Request Changes** — The campaign requires specific modifications before it can be approved.

**Business rules:**
- A Reviewer can only act on campaigns in **Pending Review** state.
- The Reviewer must be reviewing the current submitted version (not a stale version).
- A Reviewer cannot review a campaign they submitted (separation of duties — see A-008).
- Each review decision must record: reviewer identity, decision, timestamp, version reviewed, and optional comments/feedback.

---

### FR-007: Approval Decision — Must

When a Reviewer approves a campaign, the system must transition it from **Pending Review** to **Approved** state.

**Business rules:**
- The approval is bound to a specific campaign version. If the campaign is subsequently modified, this approval may be invalidated (see FR-014).
- The approval record is immutable and becomes part of the audit trail.

> **Open question (OQ-009):** Single-approval vs. consensus-approval. Does one authorised reviewer's approval suffice, or must all assigned reviewers approve?
>
> **Initial recommendation (for MAL4):** Single-approval model — any one authorised Reviewer can approve. This simplifies the state machine while demonstrating the core workflow. The architecture should be designed to support consensus approval as a future extension.

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

### FR-012: Scheduling Gate — Must

The system must enforce that only campaigns in **Approved** state can transition to **Scheduled** state.

**Business rules:**
- A campaign cannot be scheduled if it is in any state other than **Approved**.
- The scheduling action must verify that the approved version is still the current version (no unapproved modifications have been made).
- Scheduling must record: who initiated scheduling, timestamp, version scheduled.

> **Scope note:** The actual scheduling mechanism (determining delivery time, triggering execution) is out of scope. The system enforces the gate — only approved campaigns can be marked as scheduled.

---

## 5. Version Management

### FR-013: Campaign Versioning — Must

The system must maintain an immutable version history for each campaign.

**Requirements:**
- A new version is created when:
  - A campaign is submitted for review (FR-004).
  - A campaign is revised after changes are requested (FR-010).
- Each version captures a complete snapshot of the campaign state at that point in time.
- Versions are numbered sequentially (v1, v2, v3, ...).
- Previous versions are read-only and cannot be modified.
- Approval decisions are linked to specific version numbers.

**Business rules:**
- The "current version" is the most recent version.
- A campaign in **Approved** state has an approval linked to a specific version number. If the campaign content changes, this linkage enables change detection.

---

### FR-014: Re-Approval on Material Change — Should

The system should detect when material changes are made to an approved campaign and invalidate the existing approval, requiring re-review.

**Material changes (initial definition):**
- Budget change beyond a defined threshold.
- Target audience modification.
- Schedule change (start or end date).
- Content or objective modification.

**Business rules:**
- When a material change is detected, the campaign transitions from **Approved** back to **Draft** (requiring re-submission) or directly to **Pending Review** (automatic re-submission).
- The previous approval record is preserved in the audit trail but marked as superseded.
- The definition of "material change" should be configurable by the System Administrator (ST-003).

> **Open question (OQ-002):** How granular should change detection be? Compare: any field change invalidates approval vs. only specific field changes vs. threshold-based (e.g., budget change > 10%).
>
> **Initial recommendation:** For the MAL4 deliverable, treat any edit to an approved campaign as a material change requiring re-approval. This is the safest default and the simplest to implement. Configurable thresholds are a future enhancement.

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

The following states emerge from the functional requirements:

| State | Entered via | Exit transitions | Owning actor |
|---|---|---|---|
| **Draft** | FR-001 (creation), FR-005 (withdrawal), FR-008 (post-rejection restart) | Submit (→ Pending Review) | Marketer |
| **Pending Review** | FR-004 (submission), FR-010 (re-submission) | Approve (→ Approved), Reject (→ Rejected), Request Changes (→ Changes Requested), Withdraw (→ Draft) | Reviewer |
| **Changes Requested** | FR-009 | Revise + Re-submit (→ Pending Review) | Marketer |
| **Approved** | FR-007 | Schedule (→ Scheduled), Material Change (→ Draft) | System / Marketer |
| **Rejected** | FR-008 | Restart (→ Draft) | Marketer |
| **Scheduled** | FR-012 | — (terminal for this system's scope) | System |

> **Note:** This state model aligns with the MAL4 expected states (Draft → Pending Review → Changes Requested → Approved → Scheduled) while adding Rejected as a necessary terminal state.

---

## Requirements Traceability

| Requirement | Stakeholder(s) | MAL4 Criterion |
|---|---|---|
| FR-001 to FR-003 | ST-001 (Marketer) | Structure & boundaries, Working user journey |
| FR-004 to FR-005 | ST-001 (Marketer) | Data & state management |
| FR-006 to FR-011 | ST-001, ST-002 (Reviewer) | Data & state management, Working user journey |
| FR-012 | ST-001, ST-002 | Structure & boundaries |
| FR-013 to FR-014 | ST-001, ST-002, ST-005 | Data & state management, Trade-offs |
| FR-015 to FR-016 | ST-002, ST-003, ST-005 | Testing & observability |
| FR-017 to FR-018 | ST-003, ST-005 | Structure & boundaries |
| FR-019 | ST-001, ST-002 | Failure & recovery handling |

---

## Assumptions

| ID | Assumption | Traces to |
|---|---|---|
| A-010 | A campaign version is a complete snapshot, not a diff. This simplifies comparison but increases storage. | FR-013 |
| A-011 | The initial system supports a single approval model (one reviewer approves). Consensus/multi-stage is a designed-for extension. | FR-007, OQ-009 |
| A-012 | Campaign state transitions are synchronous and strongly consistent — the state must be correct immediately after the operation completes. | FR-006, FR-007, FR-008, FR-009 |

---

## Open Questions

| ID | Question | Traces to |
|---|---|---|
| OQ-002 | How granular should material change detection be for re-approval triggering? | FR-014 |
| OQ-009 | Single-approval vs. consensus-approval model? | FR-007 |
| OQ-010 | Can a submission be withdrawn after partial reviewer action? | FR-005 |
| OQ-011 | Should campaigns support collaborative editing (multiple Marketers editing the same draft)? | FR-002 |
| OQ-012 | Should the system enforce review deadlines or SLAs for pending reviews? | Not yet captured — potential future FR |
| OQ-013 | Should a rejected campaign allow direct re-submission, or must it go through a full Draft → Submit cycle? | FR-008 |
