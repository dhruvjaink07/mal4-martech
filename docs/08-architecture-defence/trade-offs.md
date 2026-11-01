# Architectural Trade-Offs & Defensive Rationale

> **Document Status:** Draft v1.1 (revised to reconcile with the implemented Solution Design and ADR collection)
> **Last Updated:** 2026-11-01
> **Owner:** Architecture & Engineering Lead
> **Traces to:** `docs/02-solution-design/` (HLD/LLD), `docs/03-architecture-decisions/` (ADR-001 through ADR-006)

---

## Overview

Every architectural choice in this project represents an explicit, conscious trade-off. Rather than defaulting to popular enterprise patterns by habit, each decision is grounded in the project's actual requirements, failure tolerance, and defensibility under technical cross-examination. Full reasoning, alternatives comparisons, and consequences for each decision are recorded formally in `docs/03-architecture-decisions/`; this document is the condensed, defence-oriented presentation of that reasoning.

**Revision note:** this table originally described the "Security & Integrity" row as **Server-Side RBAC**. Inspection against the implemented Solution Design (`docs/02-solution-design/`) found this does not match what was actually built — the current architecture has no backend and enforces authorization on-device (ADR-004). The row below has been corrected to describe the implemented decision accurately, with the discrepancy against the original framing (and against the requirements baseline's later server-side expectation) addressed explicitly rather than silently, per `ADR-006`.

---

## 1. Key Architectural Decisions & Defensive Rationale

| # | Architecture Dimension | Option Chosen (as implemented) | Alternative Rejected | Defensive Rationale & Why Not? |
|:---:|:---|:---|:---|:---|
| **1** | **State Management** | **Explicit Finite State Machine** | Dynamic BPMN / Workflow Engines (Camunda, Temporal, Zeebe) | A 6-state lifecycle (`Draft`, `Pending Review`, `Changes Requested`, `Approved`, `Rejected`, `Scheduled`) is strictly bounded. Embedding external BPMN engines introduces runtime latency, an external failure point, state-desynchronization risk, and deployment overhead disproportionate to a bounded, well-understood state set. |
| **2** | **Version Governance** | **Immutable Version Snapshots (`vN`)** | In-Place Mutation / Event-Sourcing Delta Diffs | In-place mutation causes silent post-approval drift (approving v1 but scheduling modified v2). Event-sourcing diffs introduce projection-reconstruction complexity not justified at this scale. Snapshots give a direct, structural guarantee of point-in-time certainty — no reconstruction, no replay. |
| **3** | **Concurrency & Conflicts** | **Optimistic Concurrency Control (Version Tokens)** | Pessimistic Locking / Distributed Two-Phase Commit (2PC) | Reviewers evaluate campaigns over minutes or hours. Pessimistic locks held across that window would block the single device running this app for no benefit. 2PC has no distributed nodes to coordinate in a local-first, no-backend architecture (ADR-005) — it is not merely rejected, it is inapplicable. |
| **4** | **Side-Effect Resilience** | **In-Process Domain Events, Emitted After Commit** | Synchronous In-Line Notification Dispatch; External Message Broker | In-line dispatch risks coupling a notification-service outage to the success of a core business transaction. A broker is disproportionate — there is exactly one in-process consumer. Events are emitted only after the write commits, so a failure downstream of that point structurally cannot roll back the transaction (ADR-003). |
| **5** | **Security & Integrity** | **On-Device RBAC & Self-Review Prevention, No Backend** (ADR-004) | Server-Side RBAC via a Backend API; Client-Side-Only Checks (No Domain-Layer Enforcement) | A real backend was not built, given team size and timeline (ADR-004, ADR-005) — this is a disclosed limitation, not a hidden one. What *is* enforced — role checks and self-review prevention in Application/Domain code, never only in the UI — cannot be bypassed by skipping client-side validation, which is the main risk client-only checks would leave open. It does **not** fully satisfy a literal server-side-enforcement reading of the non-functional requirements, and the team states this openly rather than claiming a guarantee the architecture does not provide. |
| **6** | **Audit & Diagnostics** | **Append-Only Audit Log, Committed Atomically with State** | In-Place Overwrites (`updated_at`-style mutation) / Full Distributed APM Tracing | Overwriting audit records destroys the forensic trail a governance system exists to provide. Full distributed tracing infrastructure has no corresponding distributed system to trace in this architecture, and adds cost without addressing client-side failure recovery. |

---

## 2. Constraints Accepted

1. **Storage overhead for full snapshots.** Storing a full payload per campaign version costs more than incremental diffs. *Accepted because:* campaign payloads are small, and the simplicity and auditability gain outweighs the storage cost.
2. **First-writer-wins collision semantics.** Under optimistic concurrency, a second concurrent writer is rejected and must reload. *Accepted because:* simultaneous conflicting writes are a low-probability event at this scale, and preventing silent state corruption outweighs the inconvenience of an occasional reload.
3. **Best-effort, eventually-delivered notifications.** A notification may arrive with delay, or in rare cases (process termination before delivery) not at all, since no durable outbox exists yet. *Accepted because:* durability of the approval state itself takes precedence over notification delivery, and this is stated as an open item rather than a solved guarantee (ADR-003).
4. **No backend, and the authorization-enforcement gap this implies.** *Accepted because:* building and operating a real backend was judged disproportionate to a two-person team and hackathon timeline. This is the single largest trade-off in the project and is treated as such throughout this defence package, not minimized — see `risks-and-limitations.md` and ADR-004/ADR-006.

---

## 3. Structured Trade-Off Analysis — Broader Architectural Alternatives

### 3.1 Modular Monolith vs. Microservices

| Criterion | Modular Monolith (selected) | Microservices |
|---|---|---|
| Operational footprint for a 2-person team | One deployable, no inter-service infrastructure | Multiple deployables, service discovery, network resilience concerns |
| Fit for current scale (single mobile app, 5–50 users) | Appropriate | Significant over-engineering — no independent-scaling need exists |
| Internal modularity still achievable | Yes — module boundaries (Campaign Management, Review & Approval Workflow, Audit, Notification, etc.) are enforced by code organization, not process boundaries | Yes, by definition, at much higher operational cost |

**When microservices would become appropriate:** If multiple independent teams needed to deploy different parts of the system on separate schedules, or if distinct components had genuinely divergent scaling needs — neither applies here.

### 3.2 Feature-First vs. Classic Layered Organization

| Criterion | Feature-First (selected) | Classic Layered (global UI/business-logic/data layers) |
|---|---|---|
| Coupling between unrelated features | Low — this project has one feature, so the benefit is latent but real for future growth | High — a global "business logic" layer tends to accumulate cross-feature dependencies over time |
| Familiarity / onboarding speed | High for modern Flutter practice | High for teams from a traditional enterprise background |

**When classic layering would become appropriate:** It would not, for this project's trajectory — Feature-First is strictly better once a second feature is anticipated, which this project's module boundaries already assume.

### 3.3 State Management: Riverpod (candidate) vs. Bloc vs. Provider

This remains an **open, not-yet-finalized** implementation choice — listed here for completeness of the trade-off record, not as an accepted decision.

| Criterion | Riverpod (leading candidate) | Bloc/Cubit | Provider |
|---|---|---|---|
| Compile-time safety | Strong | Strong | Weaker |
| Boilerplate for this scale | Lower | Higher (explicit event/state classes) | Lowest, but at the cost of safety |
| Fit with `Result`-returning use cases | Natural (async-notifier pattern) | Requires more adaptation | Workable |

No code exists yet; this choice will be finalized during implementation, not retroactively declared decided here.

