# Risks and Limitations

> **Purpose:** A complete, honest accounting of what this architecture does not guarantee, cannot do, or has not yet resolved. Nothing here is hidden elsewhere and omitted from this list.

---

## 0. The Most Significant Open Item: Requirements/Architecture Divergence

**This is listed first because it is the most consequential finding in this entire documentation effort.**

The requirements baseline (`docs/01-problem-understanding/`, `docs/04-workflows/`, `docs/06-data-design/`) was expanded, after the Solution Design (`docs/02-solution-design/`) was built, to specify a three-stage sequential approval pipeline (Creative → Compliance → Finance) with cryptographic snapshot binding and a server-side, database-backed enforcement model. The implemented Solution Design is a single-approval, local-first, no-backend architecture. The two were never reconciled.

This is documented in full in `docs/03-architecture-decisions/ADR-006-multistage-approval-backend-reconciliation.md`, with three explicit resolution options and a non-binding recommendation. **It is not resolved as of this writing.** Every other item in this document should be read with this context: several of the limitations below (no backend, single-reviewer model, no durable outbox) are consequences of decisions that may be revisited depending on how ADR-006 is resolved.

## 1. Architectural Limitations

- **Single-reviewer approval model.** Only one `ApprovalRecord` exists per campaign version. The requirements baseline's three-stage pipeline, with per-stage approval records and three distinct reviewer roles, is not implemented.
- **No multi-stage state sub-structure.** `Pending Review` is one state, not three sequential sub-stages.
- **No idempotency-key scheme.** A true race between two writes arriving near-simultaneously (as opposed to a retry after a successful write) is not fully closed by the optimistic-concurrency mechanism alone. This is named explicitly in ADR-002 as an open item, not claimed as solved.
- **No durable outbox for notifications.** If the application process terminates after a state commit but before a queued notification is delivered, that notification can be lost. There is no `outbox_events`-style durable table in the current design.

## 2. Security Limitations

- **No backend — authorization is enforced on-device.** Role checks and self-review prevention happen in Application and Domain code running in the same process as the UI. A modified client binary could, in principle, bypass these checks; there is no separate server process a client cannot alter. This is the architecture's single most significant security limitation, and it directly fails a literal reading of the non-functional requirement that authorization be enforced "server-side, not only in the client." (ADR-004)
- **No real Identity Provider integration.** `AuthProvider` is an interface with no live implementation for this deliverable.
- **Cryptographic snapshot hashing is not implemented.** The requirements baseline specifies SHA-256 digests binding approvals to exact snapshot content; the current design relies on a version-number token, which is sufficient for detecting staleness and conflicts within this architecture but does not provide the same tamper-evidence guarantee a cryptographic hash would.

## 3. Persistence and Synchronization Limitations

- **No cross-device synchronization.** Two installations of the app on two devices cannot see each other's data. This is a hard limitation of the local-first design (ADR-005), not an edge case handled imperfectly.
- **No backup/disaster-recovery infrastructure.** SQLite's write-ahead-log mode protects against application crashes on a single device; it does not protect against loss of the device itself.
- **No multi-tenancy.** Single-tenant only, consistent with the project's scope assumption — not evaluated against a multi-organization requirement.

## 4. Scalability Boundaries

- Sized for the confirmed scale (5–50 users, 10–200 active campaigns). Not load-tested, because there is no deployed instance to load-test — this is stated as an architecture-defense discussion point, not a benchmarked claim.
- A Modular Monolith does not independently scale its parts — if this ever became a real constraint, it would require moving toward the kind of distributed architecture explicitly avoided in ADR-001, which would be a significant redesign, not a configuration change.

## 5. External Dependency Risks

- `AuthProvider` and `NotificationGateway` are both unimplemented adapters over external systems (an Identity Provider and a Notification Service, respectively) that do not exist for this deliverable. Any claim about their behavior is a claim about the interface contract, not about observed behavior of a real integration.
- The Scheduling System hand-off (actual campaign delivery/execution) is entirely out of scope — the architecture enforces only the *gate*, not the downstream execution.

## 6. Team and Implementation Constraints

- Two engineers, hackathon timeline. Every architectural decision in ADR-001 through ADR-005 cites this constraint as a driver — the architecture is deliberately proportionate to this team size, which is also why it falls short of the requirements baseline's larger, backend-inclusive vision (ADR-006).
- **No Flutter/Dart code exists yet.** Every class signature, pseudocode block, and test scenario across the Solution Design is a design artifact. Nothing in this project should be presented as already built, running, or tested.

## 7. Future Architectural Evolution Opportunities

These are not commitments — they are the specific seams this architecture was deliberately built to support, should the team decide to extend it:

| Evolution | What already supports it | What would still need to be built |
|---|---|---|
| A real backend | `AuthProvider`/`NotificationGateway` are already interfaces; `CampaignRepository` is already a dependency-inverted seam | The backend itself, an API contract, deployment infrastructure, and a sync/conflict-resolution strategy for multi-device use |
| Multi-stage approval pipeline | The Review & Approval Workflow module is already isolated from Campaign Management, Audit, and Notification | A redesigned `ApprovalRecord` model (one per stage), stage-role authorization, and the pipeline-reset rules the requirements baseline specifies |
| Durable notification delivery | Domain events are already a clean seam between "something happened" and "something was sent" | An outbox table and a background dispatcher with retry/backoff |
| Idempotency keys | The optimistic-concurrency mechanism already distinguishes stale-review from write-conflict errors | A request-level deduplication mechanism, keyed on something the client supplies |

## What This Document Deliberately Does Not Do

It does not minimize any of the above by pairing it with reassurance that it "doesn't matter." Several of these limitations matter a great deal for a production deployment. They are listed because a defensible architecture is one whose limits are known precisely, not one that claims to have none.
