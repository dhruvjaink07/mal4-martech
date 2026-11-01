# Architectural Trade-Offs & Defensive Rationale

> **Document Status:** Draft v1.0
> **Last Updated:** 2026-11-01
> **Owner:** Domain Research & Requirements Lead
> **Traces to:** [One-Page Solution Brief](../one-page-solution-brief.md), [Functional Requirements](../01-problem-understanding/functional-requirements.md), [Non-Functional Requirements](../01-problem-understanding/non-functional-requirements.md)

---

## Overview

In evaluating the architecture for the **MAL4 MarTech Campaign Review & Approval Platform**, every architectural choice represents an explicit, conscious trade-off. Rather than defaulting to popular enterprise buzzwords (Microservices, Kafka, Camunda, Event Sourcing, 2PC), each decision is grounded in measurable requirements, failure tolerance, and defensibility under technical cross-examination.

---

## 1. Key Architectural Decisions & Defensive Rationale

| # | Architecture Dimension | Option Chosen | Alternative Rejected | Defensive Rationale & Why Not? |
|:---:|:---|:---|:---|:---|
| **1** | **State Management** | **Explicit Finite State Machine** | Dynamic BPMN / Workflow Engines (Camunda, Temporal, Zeebe) | A 6-state lifecycle (`Draft`, `Pending`, `Changes`, `Approved`, `Rejected`, `Scheduled`) is strictly bounded. Embedding external BPMN engines introduces severe runtime latency, an external single point of failure, complex state desynchronization, and massive deployment overhead. |
| **2** | **Version Governance** | **Immutable Version Snapshots (`vN`)** | In-Place Mutation / Event Sourcing Delta Diffs | In-place entity mutation causes silent post-approval drift (approving v1 but executing modified v2). Event Sourcing delta diffs introduce projection rebuild latency, snapshot reconstruction overhead, and schema evolution friction for mobile inspection. Snapshots provide cryptographic point-in-time certainty. |
| **3** | **Concurrency & Conflicts** | **Optimistic Concurrency Control (Version Tokens / ETags)** | Pessimistic DB Row Locking / Distributed Two-Phase Commit (2PC) | Reviewers read and evaluate campaigns over minutes or hours on mobile devices. Pessimistic database locks held over mobile network latency or disconnections would lock entire tables and freeze the platform. 2PC introduces distributed deadlocks and high write latency. |
| **4** | **Side-Effect Resilience** | **Decoupled Asynchronous Outbox Pattern** | Synchronous In-Line Notification Dispatch | Third-party push and email delivery (FCM, APNs, SendGrid) suffers from 2–5 second latencies, rate-limits, and transient outages. In-line synchronous calls mean an external notification timeout rolls back or aborts a legitimate business approval transaction. |
| **5** | **Security & Integrity** | **Server-Side RBAC & Separation of Duties (SoD)** | Client-Side Role Gates / Permissive Self-Signoff | Mobile client-side checks can be bypassed via direct REST API calls or cURL requests. Permitting marketers to self-approve violates core internal controls mandated by SOX 404 (budget commitments) and FINRA Rule 2210 (promotional material principal review). |
| **6** | **Audit & Diagnostics** | **Append-Only Chronological Event Ledger + Structured Telemetry** | In-Place Overwrites (`updated_at`) / Full APM Tracing | Overwriting records in-place destroys forensic audit evidence required during compliance investigations. Heavy distributed APM tracing adds high infrastructure cost and cloud dependency without directly aiding client-side failure recovery. |

---

## 2. Constraints Accepted

1. **Storage Overhead for Full Snapshots:** Storing full campaign payload snapshots for each submitted version (`v1`, `v2`, `v3`) consumes more database storage than incremental delta diffs. *Accepted because:* Campaign payloads are lightweight JSON documents (<50 KB), making storage costs negligible compared to the operational simplicity and immutability guarantees.
2. **First-Committer-Wins Collision Semantics:** With optimistic concurrency control, when two reviewers act simultaneously on the same pending campaign, the second reviewer receives a `409 Conflict` error and must refresh their view. *Accepted because:* Simultaneous reviews on the same marketing campaign are low-probability events, and preventing conflicting state transitions is mathematically paramount.
3. **Eventual Delivery for Notifications:** Downstream notifications (push/email) arrive with slight asynchronous latency (typically <2 seconds) rather than instantly in the HTTP response. *Accepted because:* Transactional durability of the approval state takes absolute precedence over ephemeral alerts.
