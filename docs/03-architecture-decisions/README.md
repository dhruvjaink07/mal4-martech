# Architecture Decision Records — Index

> **Owner:** Architecture & Engineering Lead
> **Last Updated:** 2026-11-01

This index lists every ADR for the MAL4 Campaign Review & Approval project, its status, and its relationships to the other ADRs and to the Solution Design (`docs/02-solution-design/`).

## Status Summary

| ADR | Title | Status |
|---|---|---|
| [ADR-001](ADR-001-architecture-style.md) | Overall Architecture Style — Modular Monolith, Feature-First, Clean-Architecture-Lite | Accepted |
| [ADR-002](ADR-002-data-consistency.md) | Campaign Versioning, Approval-Version Binding, and Optimistic Concurrency | Accepted |
| [ADR-003](ADR-003-event-processing.md) | In-Process Domain Events for Side-Effect Decoupling | Accepted |
| [ADR-004](ADR-004-authorization-and-deployment-boundary.md) | Authorization Enforcement Boundary and No-Backend Deployment Model | Accepted (for the current Solution Design) |
| [ADR-005](ADR-005-persistence-strategy.md) | Local-First Persistence Strategy (Drift over SQLite) | Accepted (for the current Solution Design) |
| [ADR-006](ADR-006-multistage-approval-backend-reconciliation.md) | Reconciliation of Multi-Stage Sequential Approval and Server-Side Enforcement with the Current Solution Design | **Proposed — Unresolved, requires a team decision** |

## How to Read This Collection

ADR-001 through ADR-005 document decisions that are genuinely reflected in the current, reviewed Solution Design (`docs/02-solution-design/HLD/MAL4-HLD.md`, `docs/02-solution-design/LLD/MAL4-LLD.md`). They are marked **Accepted** because that is an accurate description of what was decided and built into that design — not because every open question in the wider project is settled.

ADR-004 and ADR-005 carry a qualifier because they are the two decisions most directly implicated by ADR-006: inspection of the requirements baseline (`docs/01-problem-understanding/`, `docs/04-workflows/`, `docs/06-data-design/`) found that it now specifies a 3-stage sequential approval pipeline with server-side, database-backed enforcement — materially different from what ADR-002 through ADR-005 describe. This was discovered during preparation of this ADR collection and is **not** a pre-existing, already-resolved part of the project; it is recorded as ADR-006, with status **Proposed**, precisely because it has not been resolved, and because silently rewriting ADR-002/004/005 to match the newer requirements would misrepresent the HLD/LLD as containing a decision it does not implement.

## Relationships Between ADRs

```
ADR-001 (architecture style)
   ├── establishes the layering ADR-002, ADR-003, ADR-004, ADR-005 operate within
   │
   ├── ADR-002 (data consistency: versioning, approval binding, optimistic concurrency)
   │      └── implemented via the persistence mechanism in ADR-005
   │
   ├── ADR-003 (event processing: in-process domain events)
   │      └── exists because of the no-backend decision in ADR-004
   │
   ├── ADR-004 (authorization boundary, no backend)
   │      └── directly drives ADR-005's local-first choice
   │
   └── ADR-005 (local-first persistence)

ADR-006 (unresolved reconciliation)
   └── contradicts ADR-002, ADR-003, ADR-004, and ADR-005 simultaneously —
       tracks the conflict between the Solution Design and the current
       requirements baseline; does not select a resolution
```

## Scope and Ownership Note

This index and all ADRs in this folder are owned and maintained by the Architecture & Engineering Lead. The requirements documentation referenced in ADR-006 (`docs/01-problem-understanding/`, `docs/04-workflows/`, `docs/06-data-design/`) is owned by the Domain Research & Requirements Lead and has not been modified as part of producing this ADR collection.
