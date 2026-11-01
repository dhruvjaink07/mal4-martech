# Stakeholders

> **Document Status:** Draft v1.0
> **Last Updated:** 2026-11-01
> **Owner:** Domain Research & Requirements Lead
> **Traces to:** [Problem Statement](problem-statement.md)

---

## Overview

Stakeholder identification is based on research into real-world campaign management platforms (HubSpot, Marketo, Salesforce Marketing Cloud, Braze, Mailchimp) and enterprise marketing team structures. Roles are scoped to the Campaign Review & Approval domain — not a full MarTech stack.

For the MAL4 challenge, we distinguish between:

- **Primary stakeholders:** Direct users of the system who interact with the campaign lifecycle.
- **Secondary stakeholders:** People or systems that are affected by or influence the campaign workflow but do not directly operate it.
- **System actors:** External systems that integrate with the campaign management system at its boundary.

---

## Primary Stakeholders

### ST-001: Marketer (Campaign Creator)

**Also known as:** Campaign Manager, Content Creator, Digital Marketer

**Description:** The person who creates, edits, and submits campaigns for review. In smaller teams, one person may handle all content and campaign setup. In larger teams, this may be split between a Campaign Manager (strategy/setup) and Content Creators (copy/creative).

**Responsibilities:**
- Create new campaign proposals with required metadata (name, objective, audience, budget, schedule, content).
- Edit campaigns in Draft state.
- Submit campaigns for review when ready.
- Respond to reviewer feedback by revising the campaign.
- Re-submit revised campaigns for another review cycle.
- View the current status of their campaigns.

**Key concerns:**
- Fast, intuitive workflow for creating and submitting campaigns.
- Clear visibility into where a campaign is in the approval process.
- Specific, actionable feedback when changes are requested.
- Assurance that approved campaigns proceed to scheduling without delays.
- Ability to track revision history and understand what changed between versions.

**Interaction frequency:** Daily to multiple times per day.

---

### ST-002: Reviewer (Multi-Level Approval Gatekeepers)

**Also known as:** Campaign Approver, Stage Reviewer

**Description:** Authorised domain specialists who evaluate submitted campaigns and execute approval decisions within a structured sequential approval pipeline. Rather than conflating creative, legal, and financial decisions into a single generalist gatekeeper, the platform models three distinct sequential review gatekeepers:

#### ST-002a: Creative & Brand Reviewer (Stage 1 Gatekeeper)
* **Also known as:** Brand Manager, Creative Director, Marketing Lead
* **Scope of Review:** Evaluates creative messaging, tone of voice, visual assets, target audience alignment, and channel-specific promotional strategy.
* **Responsibilities:**
  - Verify that visual assets and copy adhere to organizational brand guidelines.
  - Confirm that marketing objectives match the selected channels and audience.
  - Approve (advancing campaign to Stage 2), Reject, or Request Changes with creative feedback.

#### ST-002b: Legal & Compliance Officer (Stage 2 Gatekeeper)
* **Also known as:** Compliance Manager, Privacy Officer, Regulatory Counsel
* **Scope of Review:** Reviews campaigns for regulatory compliance (GDPR consent rules, CAN-SPAM opt-out mechanisms, truth-in-advertising standards, FINRA Rule 2210 retail claims).
* **Responsibilities:**
  - Verify mandatory legal disclaimers, terms, and privacy disclosures.
  - Inspect targeting criteria to prevent prohibited audience segmenting (e.g., restricted demographics, geo-fencing).
  - Approve (advancing campaign to Stage 3), Reject, or Request Changes with regulatory remediation requirements.

#### ST-002c: Finance & Budget Approver (Stage 3 Gatekeeper)
* **Also known as:** Budget Owner, Finance Director, Commercial Controller
* **Scope of Review:** Inspects campaign spend allocations, cost centers, and delegation-of-authority (DOA) financial thresholds under Sarbanes-Oxley (SOX 404).
* **Responsibilities:**
  - Verify that budget amounts are allocated from authorized cost centers.
  - Confirm spend commits stay within designated quarterly or departmental budget limits.
  - Final Approval (clearing the campaign for the Scheduling Gate), Reject, or Request Changes.

**Key concerns across all Reviewers:**
- Seeing only campaigns that require their specific domain attention (Stage 1 sees pending creative; Stage 2 sees brand-approved campaigns; Stage 3 sees legally cleared campaigns).
- Cryptographic confidence that the campaign has not been modified since submission (immutable version snapshot binding).
- Ability to inspect side-by-side structured diffs when reviewing revisions ($vN$ vs $vN+1$).
- Clear audit trail of decisions for compliance and personal accountability.
- Strict anti-self-approval enforcement (`submitted_by_id != reviewer_id`).

**Interaction frequency:** Daily; review queues processed via mobile alerts or batch dashboard.

---

### ST-003: System Administrator

**Also known as:** Marketing Operations Lead, MarTech Admin, Platform Admin

**Description:** The person responsible for configuring and maintaining the campaign management system. Sets up approval workflows, manages user roles and permissions, configures notification rules, and monitors system health.

**Responsibilities:**
- Configure approval workflow rules (stage definitions, reviewer role bindings, DOA spend thresholds).
- Manage user accounts, role assignments, and authentication policies.
- Define and adjust material change detection thresholds.
- Monitor system activity, outbox dispatch queues, and audit logs.
- Troubleshoot workflow exceptions (stuck campaigns, DLQ notifications).

**Key concerns:**
- Ability to configure workflows and reviewer assignments without code deployments.
- Visibility into system health, queue latencies, and review bottlenecks.
- Access to immutable audit logs for governance, internal controls, and regulatory reporting.
- High platform availability and reliable failure recovery.

**Interaction frequency:** Weekly for configuration; ad hoc for operational maintenance.

---

## Secondary Stakeholders

### ST-004: Marketing Leadership (CMO / VP / Director)

**Description:** Senior executives who oversee marketing strategy and organizational governance. They do not typically interact with individual campaign approvals directly but rely on platform telemetry and governance guarantees.

**Concerns:**
- Strict governance: 100% assurance that unapproved or unreviewed campaigns can never be scheduled or published.
- Budget oversight: spend commitments strictly enforce delegation-of-authority limits.
- Risk management: protection against brand erosion and regulatory fines.
- Campaign throughput: visibility into pipeline velocity and approval bottlenecks.

**Interaction:** Indirect — executive reporting, milestone summaries, and high-threshold escalation overrides.

---

### ST-005: External Auditors & Regulatory Inspectors

**Description:** Third-party regulatory authorities (e.g., GDPR data protection authorities, FTC, FINRA) or internal corporate governance auditors (SOX 404 compliance teams) examining campaign history.

**Concerns:**
- Immutable, tamper-evident audit trails linking scheduled campaigns to the exact version reviewed by compliance and finance.
- Mathematically verifiable proof that the marketer who created the campaign did not approve their own budget or disclaimers.
- Complete lifecycle lineage reconstructing every review decision, timestamp, and feedback comment.

**Interaction:** Read-only ad-hoc audits and compliance export inspections.

---

## System Actors (External Systems at the Boundary)

These are not human stakeholders but systems that interact with the campaign management system. They are listed here to define the system boundary.

| Actor | Interaction | Direction |
|---|---|---|
| **Notification Service** | Sends alerts when campaigns are submitted, approved, rejected, or when changes are requested | Outbound |
| **Scheduling System** | Receives approved campaigns for time-based delivery scheduling | Outbound |
| **Identity Provider** | Authenticates users and provides role/permission claims | Inbound |
| **Asset/Content Storage** | Stores and retrieves campaign content assets (images, copy, documents) | Bidirectional |
| **Analytics/Reporting** | Consumes campaign lifecycle events for dashboards and reporting | Outbound |

> **Architecture Lead input needed:** The system boundary and integration contracts with these actors will be defined in the System Context document (02-solution-design/system-context.md).

---

## Stakeholder Concerns Matrix

| ID | Stakeholder | Approval Stage / Role | Key Concerns | Priority |
|---|---|---|---|---|
| **ST-001** | Marketer | Campaign Creator / Submitter | Usability, transparent stage tracking, structured revision feedback, offline drafting | **High** |
| **ST-002a** | Creative & Brand Reviewer | Stage 1 Approver | Brand identity integrity, asset quality, tone of voice, objective-audience alignment | **High** |
| **ST-002b** | Legal & Compliance Officer | Stage 2 Approver | GDPR/CAN-SPAM compliance, disclaimer accuracy, prohibited targeting avoidance | **High** |
| **ST-002c** | Finance & Budget Approver | Stage 3 Approver | SOX 404 DOA spend authorization, cost center verification, ROI budget caps | **High** |
| **ST-003** | System Administrator | Platform Operations & Config | Stage rule configuration, user role provisioning, outbox queue health, audit queryability | **High** |
| **ST-004** | Marketing Leadership | Executive Governance | Pipeline velocity, zero unapproved campaign leakage, risk mitigation, audit compliance | **Medium** |
| **ST-005** | External Auditors / Regulators | Independent Governance | Tamper-evident audit lineage, mathematical snapshot verification, anti-self-approval proof | **Medium** |

---

## RACI Governance Matrix Across Lifecycle Stages

| Lifecycle Stage | Marketer (`ST-001`) | Creative Reviewer (`ST-002a`) | Legal/Compliance (`ST-002b`) | Finance Approver (`ST-002c`) | System Admin (`ST-003`) |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Drafting & Editing** | **A / R** | I | I | I | I |
| **Submission (`FR-004`)** | **A / R** | C | I | I | I |
| **Stage 1: Creative Review (`FR-006`)** | I | **A / R** | I | I | I |
| **Stage 2: Compliance Review (`FR-006`)** | I | I | **A / R** | I | I |
| **Stage 3: Finance Authorization (`FR-007`)** | I | I | I | **A / R** | I |
| **Revision & Resubmission (`FR-010`)** | **A / R** | C / R | C / R | C / R | I |
| **Material Change Invalidation (`FR-014`)** | R | C | C | C | **A** (System) |
| **Scheduling Gate (`FR-012`)** | R | I | I | I | **A** (System) |

*(Legend: **A** = Accountable, **R** = Responsible, **C** = Consulted, **I** = Informed)*

---

## Stakeholder Interaction Model (Multi-Stage Sequential Pipeline)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Campaign Review & Approval System                               │
│                                                                                        │
│  ┌──────────┐   Submits vN   ┌────────────────┐   Configures Policies  ┌─────────────┐ │
│  │ Marketer │───────────────▶│    Campaign    │◀───────────────────────│  Sys Admin  │ │
│  │ (ST-001) │◀───────────────│     Engine     │                        │  (ST-003)   │ │
│  └────┬─────┘   Revisions    └───────┬────────┘                        └─────────────┘ │
│       │                              │                                                 │
│       │      ┌───────────────────────┴────────────────────────┐                         │
│       │      │         SEQUENTIAL REVIEW PIPELINE             │                         │
│       │      │                                                │                         │
│       │      │  ┌──────────────┐   Pass    ┌──────────────┐   │                         │
│       │      │  │   Stage 1:   │──────────▶│   Stage 2:   │   │                         │
│       │      │  │Creative Rev. │           │ Legal/Compl. │   │                         │
│       │      │  │  (ST-002a)   │           │  (ST-002b)   │   │                         │
│       │      │  └──────┬───────┘           └──────┬───────┘   │                         │
│       │      │         │ Changes                  │ Changes   │                         │
│       │      │         │ Req.                     │ Req.      │                         │
│       │      │         ▼                          ▼           │                         │
│       │      │  ┌─────────────────────────────────────────┐   │                         │
│       └──────┼─▶│      Revision Loop (FR-009 / FR-010)     │   │                         │
│              │  └─────────────────────────────────────────┘   │                         │
│              │                                    │ Pass      │                         │
│              │                                    ▼           │                         │
│              │                             ┌──────────────┐   │                         │
│              │                             │   Stage 3:   │   │                         │
│              │                             │ Finance/DOA  │   │                         │
│              │                             │  (ST-002c)   │   │                         │
│              │                             └──────┬───────┘   │                         │
│              │                                    │ Final     │                         │
│              │                                    │ Approval  │                         │
│              │                                    ▼           │                         │
│              │                             ┌──────────────┐   │                         │
│              │                             │   APPROVED   │   │                         │
│              │                             │  FOR SCHED.  │   │                         │
│              │                             └──────┬───────┘   │                         │
│              └────────────────────────────────────┼───────────┘                         │
└───────────────────────────────────────────────────┼─────────────────────────────────────┘
                                                    │
                                                    ▼ (Clears Gate)
                                             ┌──────────────┐
                                             │  Scheduling  │
                                             │    System    │
                                             └──────────────┘
```

---

## Defensible Architectural Positions for Stakeholders & Approval Roles

### 1. Multi-Level Specialized Gatekeepers vs. Single Generalist Reviewer
- **Chosen Approach:** Explicit multi-level sequential pipeline with three dedicated role profiles: Stage 1 (`ST-002a` Creative), Stage 2 (`ST-002b` Legal/Compliance), and Stage 3 (`ST-002c` Finance/DOA).
- **Why Chosen (Defensible Rationale):** Real-world enterprise marketing demands distinct domains of expertise. A creative director cannot legally certify GDPR consent compliance or warranty disclaimers; a compliance officer does not hold corporate delegation of authority (DOA) to commit \$100,000 ad spends. Multi-stage separation ensures each gatekeeper is held accountable solely for their legal and fiduciary remit.
- **Why Not Single Generalist Gatekeeper:** While simpler, allowing any single reviewer to approve campaigns conflates distinct corporate liabilities, creates severe compliance audit vulnerabilities (failing SOX 404 Section 8), and increases error rates.

### 2. Sequential Staging vs. Parallel All-At-Once Consensus ($N$-of-$N$)
- **Chosen Approach:** Sequential execution ($Stage_1 \rightarrow Stage_2 \rightarrow Stage_3$).
- **Why Chosen (Defensible Rationale):** Resource efficiency and cost minimization. Legal counsel and finance directors are expensive, high-demand stakeholders. Submitting incomplete or creatively substandard campaigns to legal and finance simultaneously wastes valuable executive time. Stage 1 acts as a quality filter: if creative issues exist, the proposal is returned to the marketer before legal or finance spend time on it.
- **Why Not Parallel Consensus?** In a parallel model, legal might spend hours redlining copy that creative subsequently rejects and completely rewrites, doubling review overhead and creating confusing, contradictory feedback loops.

### 3. Strict Separation of Duties (Anti-Self-Approval Enforcement)
- **Chosen Approach:** Hard application and database constraints enforcing `campaign.submitted_by_id != reviewer.id` across all three stages.
- **Why Chosen (Defensible Rationale):** Mandatory for regulatory compliance (FINRA 2210, SOX 404). Even if a user holds both Marketer and Reviewer role credentials, the platform structurally blocks them from reviewing or approving their own campaign submissions.
- **Why Not Configurable Self-Approval Policy:** Making self-approval toggleable creates audit loop-holes and invites governance circumvention under tight deadlines.

---

## Assumptions

| ID | Assumption | Traces to | Status |
|---|---|---|---|
| A-003 | The system implements a **multi-level sequential approval pipeline** (Stage 1: Creative → Stage 2: Compliance/Legal → Stage 3: Finance/Budget), guaranteeing strict separation of duties and regulatory compliance before scheduling. | OQ-001 | High (Resolved) |
| A-007 | All primary stakeholders authenticate through a shared identity provider with role-based access control. | — | High |
| A-008 | The Marketer and Reviewer roles are strictly distinct per campaign — a user cannot review their own submissions (`submitted_by_id != reviewer_id`). | Industry best practice (SOX 404, FINRA 2210) | High (Non-negotiable) |
| A-009 | Notification delivery is decoupled via Transactional Outbox; notification failures never block the approval workflow. | Failure Recovery | High (Resolved) |
| A-011 | Material changes made to an approved or in-review campaign automatically invalidate approvals and re-route the proposal for re-approval. | FR-014, Revision Workflow | High (Resolved) |

---

## Open Questions

| ID | Question | Traces to | Status | Defensible Resolution |
|---|---|---|---|---|
| OQ-001 | Should the system support multi-stage approvals in the initial design? | Problem Statement | **Resolved** | **Adopted.** 3-stage sequential pipeline (Creative → Legal → Finance) enforced to eliminate regulatory liability and SoD breaches. |
| OQ-007 | Can a reviewer delegate their review to another authorised person? | Escalation Policy | Scoped Out | Reviewer delegation deferred to v2. Initial system requires designated role-holders. |
| OQ-008 | Should the system enforce that a submitter cannot approve their own campaign? | Separation of duties | **Resolved** | **Hard Enforced.** Invariant `submitted_by_id != reviewer_id` enforced in code and database constraints. |
| OQ-009 | In multi-stage review, does each stage require single authorized approval or consensus? | Approval Policy | **Resolved** | **Sequential Stage Gate.** Each stage requires exactly 1 authorized domain specialist for that stage; all 3 stages must sequentially pass. |
