# MAL4 MarTech: One-Page Solution Brief & Architecture Defence

> **Event:** Mobile Architecture Lab 4 (MAL4) — *"Architects in AI Era"*
> **Track:** MarTech (Marketing Technology)
> **Problem Area:** Campaign Review & Approval Platform
> **Visual Theme:** Red, Green, and Black Executive Architecture Palette
> **Document:** Executive One-Page Solution Brief & Architecture Defence (Draft v1.0 • 01 November 2026)
> **HTML Visual Artifact:** [`assets/diagrams/one-page-solution-brief.html`](../../assets/diagrams/one-page-solution-brief.html)
> **Strictly Single-Page PDF (A4):** [`assets/diagrams/one-page-solution-brief.pdf`](../../assets/diagrams/one-page-solution-brief.pdf)
> **Strictly Single-Page Word (`.docx`):** [`assets/diagrams/one-page-solution-brief.docx`](../../assets/diagrams/one-page-solution-brief.docx)

---

## 1. The Problem (🔴 Red Accent)

Marketing campaign proposals move across marketers, reviewers, and approvers before scheduling. When coordinated through disconnected tools or chats, teams lose state visibility, approve one version and schedule another, miss required revisions, or lack proof of who approved what. Concurrent edits and uncontrolled post-approval changes further undermine brand compliance, budget authorization, and auditability.

---

## 2. Proposed Solution (🟢 Green Accent)

A mobile-first, workflow-driven platform that manages campaign proposals from draft through review, revision, and approval, enforcing an automated scheduling gate. Every review decision is cryptographically bound to an immutable campaign version; only the approved version may be scheduled. Provides role-based actions, version history, and an append-only audit trail.

---

## 3. Core User Journey (⚫ Black & 🟢 Green)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   1 CREATE   │ ──▶ │   2 SUBMIT   │ ──▶ │   3 REVIEW   │
│   (Draft)    │     │  (Snapshot)  │     │   (Inspect)  │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                 │
       ┌─────────────────────────────────────────┼──────────────────┐
       │ (Changes Requested)                     │ (Approved)       │
       ▼                                         ▼                  ▼
┌──────────────┐                          ┌──────────────┐   ┌──────────────┐
│   4 REVISE   │ ──(Re-submit)──▶ [2]     │  5 APPROVE   │   │  REJECTED    │
│  (vN+1 Loop) │                          │ (vN Binding) │   │ (Terminated) │
└──────────────┘                          └──────┬───────┘   └──────────────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │6 SCHED. GATE │
                                          │(Ver. Match)  │
                                          └──────────────┘
```

| Step | Phase | Role | Operational Description |
|:---:|:---|:---|:---|
| **1** | **CREATE** | Marketer | Marketer defines objective, audience, budget, schedule, and assets. |
| **2** | **SUBMIT** | Marketer / System | Validates required fields; locks immutable snapshot `vN` for review. |
| **3** | **REVIEW** | Reviewer | Reviewer inspects `vN`; approves, rejects, or requests changes. |
| **4** | **REVISE** | Marketer | Marketer updates draft based on feedback; resubmits as `vN+1`. |
| **5** | **APPROVE** | Reviewer / System | 🟢 Explicit approval sign-off permanently bound to snapshot `vN`. |
| **6** | **SCHEDULE GATE** | System Gate | 🟢 Gate verifies proposal matches approved version before release. |

---

## 4. Architectural Approaches & Defensive Rationale (Chosen 🟢 vs. Rejected Alternatives 🔴)

| # | Architectural Pillar | Chosen Design Pattern (🟢 Green) | Rejected Alternative & Defensive Rationale (🔴 Red) |
|:---:|:---|:---|:---|
| **1** | **State Management** | **Explicit State Machine**<br/>Deterministic finite state machine across 6 strict states. | **Why Not BPMN Engines (Camunda/Temporal):** Overkill for 6 states. External workflow engines add runtime latency, external failure points, and state desync. |
| **2** | **Version Governance** | **Immutable Version Snapshots**<br/>Full payload snapshot locked at submission (`vN`). | **Why Not In-Place Edits / Diffs:** In-place mutation causes post-approval drift. Event diffs add projection latency on mobile. |
| **3** | **Concurrency & Conflicts** | **Optimistic Concurrency**<br/>Version-token / ETag verification (`version == current`). | **Why Not Pessimistic Locks / 2PC:** Network drops holding locks freeze mobile clients. 2PC creates distributed deadlocks. |
| **4** | **Side-Effect Resilience** | **Decoupled Async Outbox**<br/>Atomic local state change + async retryable notifications. | **Why Not Sync Inline Calls:** Downstream push/email outages (FCM/SendGrid 500) would block legitimate approvals. |
| **5** | **Security & Integrity** | **Server-Side RBAC & SoD**<br/>Server-enforced role tokens with strict check (`creator != reviewer`). | **Why Not Client Checks / Self-Review:** Bypassed via cURL/API. Self-approval violates SOX 404 & FINRA 2210 compliance. |
| **6** | **Audit & Diagnostics** | **Append-Only Audit Log**<br/>Chronological event ledger + structured JSON diagnostic logs. | **Why Not In-Place Overwrites:** Overwriting records destroys forensic audit proof needed for regulatory compliance. |

---

## 5. Scope & Boundaries

| 🟢 In Scope (System Core) | 🔴 Out of Scope (External Ecosystem) |
|:---|:---|
| Campaign metadata, validation, submission, review gates, revision loop, immutable version snapshots, scheduling gate, RBAC, separation of duties, append-only audit trail. | Creative authoring tools, audience segmentation engine, actual email/ad delivery execution, multi-touch attribution analytics, A/B testing, external CRM/DAM sync. |

---

## 6. Core Architectural Principle (🟢 Green Callout)

> **An approval belongs to one immutable campaign version; scheduling must verify that exact version.**
> *Architecture-led design for MAL4.*
