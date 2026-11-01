# Campaign Revision & Versioning Workflow

> **Document Status:** Approved v1.0  
> **Last Updated:** 2026-11-01  
> **Owner:** Domain Research & Requirements Lead  
> **Traces to:** [`functional-requirements.md`](../01-problem-understanding/functional-requirements.md), [`non-functional-requirements.md`](../01-problem-understanding/non-functional-requirements.md), [`campaign-lifecycle.md`](campaign-lifecycle.md), [`approval-workflow.md`](approval-workflow.md)

---

## 1. Overview & Purpose

In marketing operations, campaign proposals rarely pass through review on the first attempt without adjustments. Editorial tweaks, legal disclaimers, audience refinement, and budget negotiations regularly mandate revisions.

However, an unstructured revision process creates severe architectural risks:
1. **Post-Approval Drift:** A campaign is approved at version 1, modified in-place to version 2, and scheduled without anyone realizing the approved copy was replaced.
2. **Context Loss:** Marketers lose track of why changes were requested, or reviewers cannot identify what changed between submission cycles.
3. **Audit Invalidation:** Inability to prove to regulators (GDPR, FINRA, SOX) which specific version of creative assets, disclaimers, or budgets were reviewed and approved.

This specification details the **structured revision loop**, **version snapshot algebra**, **multi-stage reset rules**, and **material change detection** that guarantee end-to-end version integrity.

---

## 2. Revision Triggers & Pipeline Reset Rules

Revisions occur under three distinct business triggers:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    REVISION TRIGGERS                                        │
├─────────────────────────┬─────────────────────────────────┬─────────────────────────────────┤
│  TRIGGER 1: PRE-APPROV  │     TRIGGER 2: POST-APPROV      │       TRIGGER 3: RESTART        │
│  (Stage Review Feedback)│     (Material Modification)     │       (Post-Rejection)          │
├─────────────────────────┼─────────────────────────────────┼─────────────────────────────────┤
│ Reviewer at Stage 1, 2, │ Marketer edits an already-      │ Proposal was rejected at any    │
│ or 3 requests changes.  │ approved campaign proposal.     │ stage; marketer overhauls draft.│
│ State: CHANGES_REQUESTED│ State: APPROVED                 │ State: REJECTED                 │
│ Action: Revise & Resub. │ Action: Revoke & Pipeline Reset │ Action: Restart to Draft        │
│ Reset: Stage 1 Creative │ Reset: Stage 1 Creative         │ Reset: Stage 1 Creative         │
└─────────────────────────┴─────────────────────────────────┴─────────────────────────────────┘
```

### 2.1 Trigger 1: Changes Requested (Pre-Approval Revision Loop)
- **Source:** Reviewer at Stage 1 (Creative), Stage 2 (Compliance), or Stage 3 (Finance) executes `REQUEST_CHANGES` (`FR-009`).
- **Flow:**
  1. Campaign enters `CHANGES REQUESTED` state.
  2. The system exposes reviewer feedback notes specifically linked to snapshot `vN` and tagged with the originating stage.
  3. Marketer updates the campaign parameters in a mutable working draft.
  4. Marketer clicks **Re-submit Revised Campaign** (`FR-010`).
  5. The platform validates mandatory fields, generates immutable snapshot `vN+1` with a new SHA-256 digest, and transitions the campaign back to `PENDING REVIEW [Stage 1: Creative]`.
  6. **Pipeline Reset Rule:** Resubmission always resets review to **Stage 1 (Creative)**. This is a vital architectural defense: if Legal requested disclaimer changes or copy adjustments at Stage 2, Creative must first verify that those modifications still preserve brand integrity before Legal and Finance re-audit the proposal.

### 2.2 Trigger 2: Post-Approval Material Modification (Approval Invalidation)
- **Source:** Marketer modifies a campaign that is already in `APPROVED` state (`FR-014`).
- **Defensive Rule:** An approval belongs to **one and only one** immutable version snapshot.
- **Flow:**
  1. Marketer saves a material edit to an approved campaign (budget delta $\ge \pm 10\%$, audience pivot, copy/disclaimer changes, date shifts $> 72$h).
  2. The system intercepts the write, invalidates all three prior stage approvals, and transitions state to `CHANGES REQUESTED` (locking the scheduling gate `FR-012`).
  3. A new version snapshot `vN+1` is created, and an `ApprovalRevokedEvent` is written to the audit log.
  4. The campaign must be re-submitted and clear all three stages of the sequential pipeline before scheduling can occur.

### 2.3 Trigger 3: Rejected Proposal Overhaul
- **Source:** Marketer re-opens a proposal in `REJECTED` state (`FR-008`).
- **Flow:**
  1. The marketer initiates a restart.
  2. The campaign transitions back to `DRAFT` as a new revision iteration.
  3. Historical review feedback, rejection causes, and superseded snapshots remain preserved in the audit trail.

---

## 3. Version Snapshot Algebra & Data Model

Rather than using incremental delta diffs (which introduce complex snapshot reconstruction lag) or in-place table overwrites (which destroy version history), the platform implements an **Immutable Snapshot Pattern** (`FR-013`).

### 3.1 Version Lifecycle

```
[Drafting v1] ────▶ [Submit v1] ──────────────▶ [Changes Requested at Stage 2]
                          │ (Snapshot Hash: 0x9f1a)       │
                          ▼                               ▼
                 [Immutable Snapshot v1]          [Marketer Edits Draft]
                                                          │
                                                          ▼
                                                  [Submit v2] ──▶ [Approved v2]
                                                          │          (Hash: 0x4c2b)
                                                          ▼
                                                 [Immutable Snapshot v2]
```

1. **Working Draft vs. Immutable Snapshot:**
   - A campaign has a primary mutable row in `campaigns` representing the current working state.
   - Upon submission, the platform creates an immutable row in `campaign_snapshots` containing a full canonical JSON payload of all metadata, targets, budgets, and asset references.
2. **Version Numbering & Digest:**
   - Sequential monotonic integer: `v1`, `v2`, `v3`, $\dots$
   - Snapshot hash: SHA-256 digest of the canonical JSON payload (`snapshot_hash`).
3. **Multi-Stage Approval Binding:**
   - The `stage_approvals` table explicitly records `snapshot_id`, `version_number`, `stage_index`, and `snapshot_hash`.
   - The approval of each stage is mathematically tied to the exact payload reviewed.

---

## 4. Material Change Classification Matrix

When an edit is attempted on an active or approved campaign, the system classifies the change as **Material** or **Non-Material** (`FR-014`):

| Campaign Parameter | Scope of Modification | Classification | System Reaction | Rationale |
|:---|:---|:---:|:---|:---|
| **Budget Modification** | Delta $\ge \pm 10\%$ OR crosses DOA tier | **Material** | Invalidate Sign-offs $\rightarrow$ Reset to Stage 1 | SOX 404 financial authorization limits; spend commitments must be re-verified by Finance (`ST-002c`). |
| **Audience Segment Pivot** | New demographic/geo criteria OR list size variance $> 15\%$ | **Material** | Invalidate Sign-offs $\rightarrow$ Reset to Stage 1 | Regulatory compliance; marketing to new demographics (e.g., minors or restricted regions) requires fresh compliance clearance (`ST-002b`). |
| **Schedule Start / End Shift** | Launch date shifted $> 72$ hours or window lengthened | **Material** | Invalidate Sign-offs $\rightarrow$ Reset to Stage 1 | Operational channel booking conflict; promotional discount expiration dates. |
| **Content Copy / Creative Link** | Headline, body copy, offer terms, or legal disclaimer edits | **Material** | Invalidate Sign-offs $\rightarrow$ Reset to Stage 1 | Brand safety and legal advertising claims verification (`ST-002a`, `ST-002b`). |
| **Operational Tags & UTMs** | Internal campaign tags, UTM telemetry labels, internal notes | **Non-Material** | Retain Approval (Logged in audit) | Operational telemetry parameters that do not alter customer-facing messaging, budget liability, or legal risk. |

> **Governance Principle:** Restricting invalidation strictly to *material* modifications prevents unnecessary approval churn and delays for harmless internal operational tag edits, while maintaining 100% protection against post-approval drift.

---

## 5. Reviewer Side-by-Side Diffing

When reviewing a revised campaign (`v2`, `v3`), reviewers must not be forced to re-read the entire proposal from scratch to spot changes.

The platform generates a **Structured Field Diff** displayed directly in the mobile and web review screens:
```json
{
  "campaign_id": "cmp_849204",
  "previous_version": 1,
  "current_version": 2,
  "changes": [
    {
      "field": "budget",
      "old_value": 15000.00,
      "new_value": 12500.00,
      "change_type": "MODIFIED",
      "materiality": "MATERIAL"
    },
    {
      "field": "target_audience",
      "old_value": "US & EU All Users",
      "new_value": "US Only, Opted-In Loyalty Members",
      "change_type": "MODIFIED",
      "materiality": "MATERIAL"
    },
    {
      "field": "utm_campaign",
      "old_value": "spring_26_promo",
      "new_value": "spring_26_loyalty",
      "change_type": "MODIFIED",
      "materiality": "NON_MATERIAL"
    }
  ],
  "reviewer_feedback_addressed": {
    "stage": 2,
    "reviewer": "Legal & Compliance (ST-002b)",
    "comment": "Budget reduced by 15% and EU audience removed per GDPR advice."
  }
}
```

This guarantees that reviewers across all three stages can instantly confirm that their requested adjustments were faithfully implemented before granting stage approval.
