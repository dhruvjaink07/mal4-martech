# Campaign Approval Workflow Specification

> **Document Status:** Approved v1.0  
> **Last Updated:** 2026-11-01  
> **Owner:** Domain Research & Requirements Lead  
> **Traces to:** [`functional-requirements.md`](../01-problem-understanding/functional-requirements.md), [`non-functional-requirements.md`](../01-problem-understanding/non-functional-requirements.md), [`campaign-lifecycle.md`](campaign-lifecycle.md), [`user-journey-flow.mmd`](user-journey-flow.mmd)

---

## 1. Overview & Purpose

The approval workflow governs how a submitted campaign proposal is routed, evaluated, and resolved by authorized personnel before it can clear the scheduling gate.

In enterprise marketing operations, the review gate is the critical checkpoint protecting the organization against:
- **Regulatory Penalties:** Advertising standards, GDPR opt-in consent violations, CAN-SPAM disclosure omissions, or SEC/FINRA misleading retail claims.
- **Brand Erosion:** Off-brand messaging, outdated logos, unauthorized discounts, or conflicting promotional schedules.
- **Financial Overspend:** Unbudgeted ad commitments or unauthorized agency spend exceeding delegation of authority (DOA) limits under SOX 404.

To eliminate compliance risk, the platform implements a **deterministic 3-stage sequential approval pipeline** (`Stage 1: Creative` $\rightarrow$ `Stage 2: Compliance` $\rightarrow$ `Stage 3: Finance`), ensuring that each domain specialist inspects and signs off on their specific legal and fiduciary remit.

---

## 2. Review Roles & Separation of Duties (SoD)

### 2.1 Role Matrix

| Role | Domain Responsibilities | Allowed Review Actions |
|:---|:---|:---|
| **Marketer (`ST-001`)** | Proposal creation, parameter definition, asset linking, addressing reviewer comments. | Create, Edit, Submit, Withdraw, Revise. *(Cannot Approve)* |
| **Creative Reviewer (`ST-002a`)** | Brand identity integrity, visual asset quality, tone of voice, objective-audience alignment. | Stage 1: Inspect, Approve (advance to Stage 2), Request Changes, Reject. |
| **Compliance Officer (`ST-002b`)** | Regulatory compliance (GDPR consent, CAN-SPAM, truth-in-advertising disclaimers, claims). | Stage 2: Inspect, Approve (advance to Stage 3), Request Changes, Reject. |
| **Finance Approver (`ST-002c`)** | SOX 404 delegation-of-authority (DOA) financial limits, cost center verification, budget caps. | Stage 3: Inspect, Final Approve (clears scheduling gate), Request Changes, Reject. |
| **Administrator (`ST-003`)** | User provisioning, stage workflow configuration, emergency escalation, audit log inspection. | Configure, Reassign, Override, Audit. |

### 2.2 Strict Separation of Duties (Anti-Self-Approval)
- **Mandate (`FR-018`, `NFR-010`):** No user may approve, reject, or request changes on a campaign proposal they submitted, regardless of their role privileges.
- **Enforcement Mechanism:**
  ```python
  def authorize_review_action(campaign, actor, required_stage):
      # 1. Enforce stage-specific role authorization
      role_stage_map = {
          1: "CreativeReviewer",
          2: "ComplianceReviewer",
          3: "FinanceApprover"
      }
      expected_role = role_stage_map.get(required_stage)
      if actor.role != expected_role and actor.role != "Administrator":
          raise ForbiddenException(f"User lacks {expected_role} role required for Stage {required_stage}")
      
      # 2. Hard Anti-Self-Approval constraint (SOX 404 / FINRA 2210)
      if actor.id == campaign.submitted_by_id:
          raise ForbiddenException("Separation of duties violation: Submitter cannot review their own campaign")
  ```
- **Rationale:** Regulatory alignment with Sarbanes-Oxley (SOX 404) and FINRA Rule 2210, which legally mandate independent principal review of commercial and financial commitments.

---

## 3. Multi-Stage Sequential Approval Pipeline & Decision Contracts

When a campaign is in the `PENDING REVIEW` state, it progresses through three sequential gates:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        SEQUENTIAL APPROVAL PIPELINE (vN)                               │
├─────────────────────────┬─────────────────────────┬────────────────────────────────────┤
│   STAGE 1: CREATIVE     │   STAGE 2: COMPLIANCE   │         STAGE 3: FINANCE           │
│   Brand & Visuals       │   Legal & Regulatory    │         Budget & DOA Caps          │
│   Actor: ST-002a        │   Actor: ST-002b        │         Actor: ST-002c             │
├─────────────────────────┼─────────────────────────┼────────────────────────────────────┤
│ Approve ──▶ Advance S2  │ Approve ──▶ Advance S3  │ Final Approve ──▶ State: APPROVED  │
│ Changes ──▶ Loops Rev.  │ Changes ──▶ Loops Rev.  │ Changes       ──▶ Loops Rev.       │
│ Reject  ──▶ Terminate   │ Reject  ──▶ Terminate   │ Reject        ──▶ Terminate        │
└─────────────────────────┴─────────────────────────┴────────────────────────────────────┘
```

### 3.1 Stage 1: Creative & Brand Review (`FR-006`)
- **Intent:** Confirms messaging, tone of voice, visual assets, and marketing objective alignment.
- **Contract:**
  - **Inputs:** `campaign_id`, `version_token`, `reviewer_id`, `optional_notes`.
  - **Preconditions:** `campaign.state == 'PENDING_REVIEW' AND campaign.stage_index == 1`.
  - **State Result:** Remains in `PENDING_REVIEW`, increments `stage_index = 2`.
  - **Payload Binding:** Emits `Stage1ApprovedEvent` with SHA-256 digest of `snapshot_vN`.
  - **Downstream Effect:** Legal/Compliance queue alert dispatched (`ST-002b`).

### 3.2 Stage 2: Legal & Compliance Audit (`FR-006`)
- **Intent:** Confirms regulatory disclosures, GDPR consent, disclaimers, and truth-in-advertising compliance.
- **Contract:**
  - **Inputs:** `campaign_id`, `version_token`, `reviewer_id`, `optional_notes`.
  - **Preconditions:** `campaign.state == 'PENDING_REVIEW' AND campaign.stage_index == 2 AND Stage 1 Approved`.
  - **State Result:** Remains in `PENDING_REVIEW`, increments `stage_index = 3`.
  - **Payload Binding:** Emits `Stage2ApprovedEvent` with SHA-256 digest of `snapshot_vN`.
  - **Downstream Effect:** Finance Approver queue alert dispatched (`ST-002c`).

### 3.3 Stage 3: Finance & Budget Authorization (`FR-007`)
- **Intent:** Confirms cost centers, departmental budget caps, and delegation-of-authority (DOA) limits under SOX 404.
- **Contract:**
  - **Inputs:** `campaign_id`, `version_token`, `reviewer_id`, `doa_tier_confirmed`.
  - **Preconditions:** `campaign.state == 'PENDING_REVIEW' AND campaign.stage_index == 3 AND Stages 1 & 2 Approved`.
  - **State Result:** Transitions to **`APPROVED`**.
  - **Payload Binding:** Emits `CampaignApprovedEvent`. Cryptographically binds all three signatures to `snapshot_vN.hash`.
  - **Downstream Effect:** Unlocks the campaign for the Scheduling Gate (`FR-012`).

### 3.4 Request Changes Decision (Any Stage) (`FR-009`)
- **Intent:** The proposal requires modifications (e.g., disclaimer update, targeting adjustment, budget reduction).
- **Contract:**
  - **Inputs:** `campaign_id`, `version_token`, `reviewer_id`, `stage_index`, `feedback_comments` *(Required, min 10 characters)*.
  - **State Result:** Transitions to `CHANGES REQUESTED`.
  - **Payload Binding:** Comments tagged with `stage_index` are saved to snapshot history `vN`.
  - **Downstream Effect:** Revision loop activates; marketer is notified (`FR-010`).

### 3.5 Rejection Decision (Any Stage) (`FR-008`)
- **Intent:** The proposal is fundamentally unviable or violates non-negotiable legal/financial standards.
- **Contract:**
  - **Inputs:** `campaign_id`, `version_token`, `reviewer_id`, `stage_index`, `rejection_reason` *(Required)*.
  - **State Result:** Transitions to `REJECTED`.
  - **Downstream Effect:** Review cycle terminates. Proposal may only restart as a fresh `DRAFT`.

---

## 4. Submission Withdrawal Policy (`FR-005`)

A marketer may withdraw a submitted campaign proposal under strict conditions:
1. **Allowed Window:** A campaign can only be withdrawn while in `PENDING REVIEW [Stage 1]` **before** the Stage 1 reviewer has recorded formal feedback or an approval action.
2. **Post-Review Blocking:** Once Stage 1 approval is granted or formal feedback is submitted, withdrawal is blocked to protect audit integrity.
3. **State Result:** Reverts to `DRAFT`.
4. **Audit Requirement:** The withdrawal action and timestamp are logged to the audit trail (`CampaignWithdrawnEvent`).

---

## 5. Concurrency & Idempotency in Multi-Stage Review Operations

### 5.1 Race Condition: Simultaneous Stage Reviews
- **Scenario:** Two reviewers attempt conflicting actions at Stage 1, or a reviewer approves while a marketer submits a revision.
- **Resolution via Optimistic Locking (`NFR-001`, `NFR-003`):**
  1. Reviewer A's request arrives with `version = 1, stage_index = 1`.
  2. The database executes:
     ```sql
     UPDATE campaigns 
     SET stage_index = 2, version = version + 1, updated_at = NOW()
     WHERE id = :campaign_id AND version = 1 AND stage_index = 1 AND state = 'PENDING_REVIEW';
     ```
  3. Reviewer A's write succeeds: campaign enters `stage_index = 2, version = 2`.
  4. Reviewer B's concurrent request arrives with `version = 1`. The database check fails (`version` is now `2`).
  5. The platform rejects Reviewer B's write with `409 Conflict`.
  6. Reviewer B's mobile app automatically refreshes, displaying the current stage.

### 5.2 Network Retry: Idempotent Execution (`NFR-004`)
- **Scenario:** Reviewer approves Stage 1 on mobile over an unstable network. The server processes the approval, but the HTTP response drops in transit. The mobile client retries the request.
- **Resolution:**
  1. Every review request carries a client-generated UUID `idempotency_key`.
  2. The server records the `idempotency_key` alongside the decision in a deduplication table within the transaction.
  3. When the duplicate request arrives, the server recognizes the key, skips re-executing the stage advance, and returns the cached `200 OK` response payload.
  4. **Guarantee:** Zero duplicate stage approvals or state corruption.

---

## 6. Architectural Defensible Positions for Multi-Stage Pipeline

### 6.1 Multi-Level Sequential Gates vs. Single Pool Gate
- **Chosen Approach:** Deterministic 3-stage sequential pipeline (`Creative` $\rightarrow$ `Compliance` $\rightarrow$ `Finance`).
- **Why Chosen (Defensible Rationale):** 
  - *Compliance & Segregation of Duties:* Fulfills SOX 404 Section 8 and FINRA 2210. A marketing creative cannot certify legal opt-in consent or warranty compliance; a compliance officer does not hold corporate DOA to sign off on six-figure expenditures.
  - *Cost Efficiency & Defect Filtering:* Staging creative review first filters out flawed or incomplete assets before consuming expensive legal and finance executive hours.
- **Why Not Single Pool Gate:** Conflates distinct corporate liabilities, creates severe compliance audit vulnerabilities, and increases operational error rates.

### 6.2 Hardcoded Deterministic Pipeline vs. Dynamic BPMN Engine
- **Chosen Approach:** Application-level deterministic state machine with relational database locking.
- **Why Chosen (Defensible Rationale):** For a well-defined 3-stage business workflow, an in-database state machine provides zero external dependencies, sub-millisecond execution latency, transactional simplicity, and bulletproof audit consistency.
- **Why Not BPMN Engines (Camunda/Temporal):** Heavy operational footprint, distributed transaction complexity, dual-state synchronization bugs, and excessive overhead for a deterministic sequential flow.

### 6.3 Material Change Invalidation & Pipeline Reset
- **Chosen Approach:** Automated material change detection (`FR-014`). Any modification to budget ($\ge \pm 10\%$), audience scope, content claims, or schedule dates invalidates approvals, generates version $vN+1$, and re-enters the review pipeline.
- **Why Chosen (Defensible Rationale):** Eliminates post-approval drift (the vulnerability where $v1$ is approved, but modified $v2$ is scheduled), guaranteeing that 100% of customer-facing messaging and spend commits carry valid executive sign-offs.
