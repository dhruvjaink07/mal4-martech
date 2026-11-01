# ADR-005: Local-First Persistence Strategy (Drift over SQLite)

## Status

Accepted (for the current Solution Design) — **see ADR-006 for an unresolved conflict with the requirements baseline**

## Decision Date

2026-11-01

## Context and Problem

Campaign state, version history, approval records, and an append-only audit trail must be durably persisted, with atomic commits across the state change and its audit entry. A persistence technology and topology (local-only vs. backend-synced) was required, consistent with the no-backend decision in ADR-004.

## Decision Drivers

- Durability and transactional atomicity requirements (a state change and its audit entry must commit together or not at all).
- No backend exists for the current deliverable (ADR-004) — ruling out a remote database as the primary store.
- FR-015's requirement that audit entries be queryable by campaign, actor, and time range favors a relational query model.
- Team size and timeline.

## Considered Alternatives

| Alternative | Description |
|---|---|
| Raw SQLite | Direct SQL against a local SQLite file, no type-safety layer. |
| Isar (NoSQL/object database) | Local object-store database, schema-less-leaning, optimized for object graphs rather than relational joins. |
| Backend API + managed database | A remote relational database (e.g. PostgreSQL) accessed via a backend API. |
| Drift over SQLite (selected) | A type-safe, code-generated query layer over local SQLite, with migrations and reactive streams. |

## Evaluation and Comparison

| Criterion | Raw SQLite | Isar | Backend API + DB | Drift over SQLite (selected) |
|---|---|---|---|---|
| Type safety at compile time | No | Partial | N/A (network boundary) | Yes |
| Fit for relational joins (campaign → versions → approvals → audit) | Workable, hand-written | Weaker — object-store model, not natively relational | Strong | Strong |
| Transactional atomicity for state+audit commit | Yes, manually | Yes | Yes, but across a network boundary | Yes, natively |
| Requires a backend to exist | No | No | Yes — contradicts ADR-004 | No |
| Engineering cost for a 2-person team | Medium (more hand-written SQL, more defect risk) | Low | High (hosting, API design, auth infra) | Low–Medium |
| Supports FR-015's query-by-campaign/actor/time-range requirement | Yes, manually indexed | Workable but less natural | Yes | Yes, with standard SQL indexes |

## Selected Decision

**Local-first persistence using Drift over SQLite.** The campaign-state write and its corresponding audit-entry write commit in a single local database transaction. No remote database or backend API is part of the current Solution Design.

## Rationale

Given ADR-004 already rules out a backend for this deliverable, the backend-API alternative is not actually available without reopening that decision — it is listed here for completeness of comparison, not as a live option. Between the remaining local options, Drift's relational model fits the domain's actual shape (one campaign has many versions, each may have one approval record, every transition has an audit entry) better than an object-store, and its type safety and migration support reduce defect risk for a 2-person team without materially increasing build complexity over raw SQLite.

## Positive Consequences

- Atomic state+audit commit is native to the chosen engine, not something the application has to coordinate by hand.
- Offline operation is the baseline mode, not a special case, because there is no network dependency in the core workflow.
- Drift's in-memory test database makes repository-level testing straightforward without a real file.

## Negative Consequences and Trade-offs

- **No cross-device synchronization.** Two installations of the app, on two devices, have no mechanism to see each other's data. This is a hard limitation, stated explicitly, not an oversight.
- No backup/restore or disaster-recovery infrastructure exists at this layer; SQLite's WAL-mode durability covers on-device crash-safety only, not loss of the device itself.
- Multi-tenancy is not addressed (consistent with the project's single-tenant scope assumption).

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A stakeholder expects multi-device support from "persistence" without reading the stated limitation | Stated consistently across the Solution Design, this ADR, and the Architecture Defence package |
| The requirements baseline's data design specifies a relational backend schema (PostgreSQL-style, with table partitioning, an `outbox_events` table, and an `idempotency_records` table) that assumes a server process this ADR does not provide | Tracked in ADR-006 as an unresolved reconciliation — this ADR documents only the current Solution Design's local-first decision |

## Requirement Traceability

| Requirement | How this decision addresses it |
|---|---|
| Durability, atomic audit/state commit (critical-priority, non-functional requirements) | Single local transaction per use-case execution |
| Audit queryability by campaign/actor/time range (functional requirement) | Relational schema with standard indexes |
| No distributed infrastructure disproportionate to team/timeline | Local-only engine, no hosting or network dependency |

## Assumptions and Open Risks

This ADR assumes multi-device synchronization is out of scope for the current deliverable. If the requirements baseline's server-backed data design (ADR-006) is adopted instead, this ADR would be superseded, not silently reinterpreted — the physical schema itself remains the responsibility of the data-design documentation regardless of outcome.

## Related ADRs and Design Sections

- Solution Design (HLD) §4.7 (Technology Architecture), §4.11 (Data Architecture), §4.15 (Deployment and Runtime Architecture).
- Low-Level Design (LLD) §5.2.3.G, §6.4 (Database Specifications, Concurrent Modification).
- ADR-002 (data consistency — the atomic commit this ADR implements).
- ADR-004 (no-backend decision — the direct driver of this choice).
- ADR-006 (the requirements baseline's server-backed data design — unresolved against this ADR).
