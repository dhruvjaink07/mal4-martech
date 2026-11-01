# ADR-006: Reconciliation of Multi-Stage Sequential Approval and Server-Side Enforcement with the Current Solution Design

## Status

**Proposed — Unresolved Conflict, Requires Team Decision Before Final Submission**

This ADR does not select an option. It exists to document a significant discrepancy discovered during architecture-decision documentation, so it is tracked explicitly rather than silently resolved in either direction.

## Decision Date

Discovered 2026-11-01. Not yet resolved.

## Context and Problem

The Solution Design (`docs/02-solution-design/`, HLD/LLD) implements: a **single-reviewer approval model** (one Reviewer role, one `ApprovalRecord` per version), **on-device, no-backend enforcement** (ADR-004), and **local-first persistence** with no server-backed schema (ADR-005).

During preparation of this ADR collection, inspection of `docs/01-problem-understanding/`, `docs/04-workflows/`, and `docs/06-data-design/` found that these documents — marked **"Document Status: Approved v1.0"** and with the relevant open questions marked **"Resolved"** — now specify a materially different architecture:

- A **3-stage sequential approval pipeline**: Stage 1 (Creative, role `ST-002a`) → Stage 2 (Compliance, role `ST-002b`) → Stage 3 (Finance, role `ST-002c`), each a distinct reviewer role with its own `StageApproval` record, all three required before a campaign reaches `Approved`.
- **Cryptographic snapshot binding**: a SHA-256 digest (`snapshot_hash`) of each campaign version, referenced by every stage approval record.
- **Server-side enforcement via a relational backend**: SQL `UPDATE ... WHERE version = :expected_version` optimistic-concurrency statements, HTTP status codes (`400`, `409`), a "Campaign API Gateway," and a full physical schema (`campaigns`, `campaign_snapshots`, `stage_approvals`, `review_decisions`, `audit_log`, `outbox_events`, `idempotency_records`, with partitioning and indexing strategy).
- A **Transactional Outbox pattern with a durable `outbox_events` table and exponential-backoff worker**, rather than this project's in-process event bus (ADR-003).
- An **HTTP-header-based idempotency-key scheme** (`Idempotency-Key` header, a dedicated `idempotency_records` table), which ADR-002 explicitly flagged as not yet designed in the current Solution Design.

This is traceable directly to the functional requirements, non-functional requirements, and stakeholders documentation (e.g. functional-requirements.md's OQ-009, originally "Open" with an "Initial recommendation: single-approval model," now marked "Resolved" in favor of the 3-stage pipeline). The requirements baseline changed after the Solution Design was built against its earlier version, and the two were never reconciled.

## Why This Matters

This is not a minor terminology mismatch. It affects:

- **The campaign state model** — `PENDING REVIEW` is a single state in the current HLD/LLD; the requirements baseline subdivides it into three sequential sub-stages with their own role gates and transition rules.
- **The data model** — a single `ApprovalRecord` per version (ADR-002) versus up to three `StageApproval` records per version, each independently bound to a snapshot hash.
- **The deployment model** — no backend (ADR-004) versus an explicit, detailed server-side API and relational database design.
- **The concurrency mechanism** — in-process optimistic concurrency (ADR-002) versus the same principle expressed as SQL against a networked database, plus an HTTP-level idempotency-key scheme ADR-002 explicitly marks as not yet designed.
- **The side-effect mechanism** — an in-process event bus (ADR-003) versus a durable, database-backed Transactional Outbox.

Every ADR in this collection that touches these areas (ADR-002, ADR-003, ADR-004, ADR-005) has been written to accurately describe what the current Solution Design actually contains, with an explicit cross-reference to this ADR wherever the requirements baseline now diverges. None of them were silently rewritten to match the newer requirements, because doing so would misrepresent the HLD/LLD as already reflecting a decision it does not implement — and this task's scope does not permit modifying the HLD/LLD to make that true.

## Options for Resolution (Not Yet Decided)

| Option | Description | Implication |
|---|---|---|
| **A. Extend the Solution Design to the 3-stage/backend model** | Formally update `docs/02-solution-design/` (HLD/LLD) to adopt the sequential pipeline, cryptographic binding, and server-side architecture the requirements now specify. | Materially larger scope: a backend must be designed and built, not just the mobile client. Highest fidelity to current requirements; highest delivery risk for a 2-person team. |
| **B. Scope the requirements back to match the delivered architecture** | Formally revise the requirements baseline (with the Domain Research & Requirements Lead) to reduce to single-approval, local-first scope for the hackathon deliverable, with the 3-stage/backend model explicitly deferred as a documented future-evolution target. | Lowest delivery risk; requires the team to jointly agree the requirements update was premature or aspirational for this deliverable's actual scope. |
| **C. Present a two-tier story: MVP architecture now, target architecture documented separately** | Keep the current Solution Design as the implemented/defensible MVP, and keep the requirements baseline's 3-stage/backend model as an explicitly labeled "target production architecture" that the current design's extension points (module boundaries, repository interfaces) are built to support — without claiming it is built. | Requires discipline to keep the two framings clearly separated in every document and in the live defence; risks judges perceiving it as an excuse rather than a plan, if not presented carefully. |

No option is selected here. This ADR's purpose is to make the conflict visible and force a conscious choice, not to make that choice unilaterally within the scope of this ADR/defence documentation task.

## What Is Not In Scope for This ADR

- Modifying `docs/02-solution-design/` (HLD/LLD) — out of scope for the task that produced this ADR collection.
- Modifying `docs/01-problem-understanding/`, `docs/04-workflows/`, or `docs/06-data-design/` — teammate-owned.
- Silently picking Option A, B, or C and writing the rest of the ADR/defence package as if it had been decided.

## Recommendation (Non-Binding)

Given the explicit team-size and timeline constraints that motivated ADR-001, ADR-004, and ADR-005, **Option C** is the most defensible starting position for the hackathon presentation itself — it allows the team to present a working, reasoned, honestly-scoped architecture while demonstrating awareness of the full target requirement. However, **Option A or B must still be formally chosen** before the project's documentation set can be considered internally consistent; Option C is a presentation strategy, not a substitute for that decision.

## Requirement Traceability

| Requirement source | Status relative to current Solution Design |
|---|---|
| `01-problem-understanding/functional-requirements.md` OQ-009 ("Resolved": 3-stage pipeline) | Not implemented in the current HLD/LLD |
| `01-problem-understanding/non-functional-requirements.md` (server-side enforcement) | Acknowledged as unmet in ADR-004, not newly discovered here |
| `04-workflows/campaign-lifecycle.md`, `approval-workflow.md`, `revision-workflow.md`, `failure-recovery.md` (all "Approved v1.0") | Describe a server-backed, 3-stage architecture not reflected in the current Solution Design |
| `06-data-design/database-schema.md`, `domain-model.md` | Describe a relational backend schema with tables (`stage_approvals`, `outbox_events`, `idempotency_records`) that do not exist in the current persistence design (ADR-005) |

## Related ADRs and Design Sections

- ADR-001 (architecture style) — the module boundaries this ADR's resolution would extend or replace.
- ADR-002 (data consistency) — the single-`ApprovalRecord` model this would need to become multi-stage.
- ADR-003 (event processing) — the in-process event bus this would need to become a durable outbox.
- ADR-004 (authorization boundary) — the no-backend decision this directly contradicts.
- ADR-005 (persistence strategy) — the local-first decision this directly contradicts.
- Architecture Defence: `docs/08-architecture-defence/risks-and-limitations.md` and `docs/08-architecture-defence/anticipated-questions.md` present this conflict to judges honestly rather than concealing it.
