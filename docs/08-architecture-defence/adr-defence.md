# Architecture Decision Defence

> **Purpose:** For each ADR, the condensed defence material — why this and not the alternative, what it costs, and under what conditions the team would revisit it. Full reasoning and comparison tables live in the ADRs themselves (`docs/03-architecture-decisions/`); this document is the rehearsed, spoken-ready version.

---

## ADR-001 — Architecture Style

**Decision summary:** Modular Monolith, Feature-First organization, Clean-Architecture-lite internal layering, MVVM presentation, narrow in-process domain events.

**Why this approach:** The problem needs one property above all — business rules that can't be bypassed or silently violated — and that comes from isolating the domain, not from distributing the system. A single feature, two developers, and a hackathon timeline make every unit of architectural ceremony something that has to earn its cost in testability or safety.

**Alternatives rejected:** Full Clean Architecture (too much ring/mapper ceremony for one aggregate and two people); classic layered architecture (couples unrelated features through shared global layers — a problem this project doesn't have yet, but the style still has it); full event-driven architecture (no distributed producers/consumers exist to justify it).

**Technical trade-offs:** Some use-case and repository boilerplate versus calling the database straight from a widget — accepted because it is exactly what buys domain testability.

**Limitations:** "Clean-lite" is not a strict, named reference architecture — boundary discipline depends on the team, not a framework. No lint rule enforces the dependency direction yet.

**Reconsider when:** A second feature is added that would benefit from shared infrastructure across features, or the team grows past a size where informal boundary discipline holds.

---

## ADR-002 — Data Consistency, Versioning, and Concurrency

**Decision summary:** Immutable full-snapshot campaign versions; approval bound to the exact version reviewed; optimistic concurrency via a version token, checked twice (once for staleness, once for write conflicts).

**Why this approach:** Post-approval drift — approving v1, scheduling v2 — is the single most damaging failure mode this system must prevent, and it must be prevented structurally, not by discipline. Optimistic concurrency fits a workflow where a reviewer might hold a campaign open for minutes or hours; pessimistic locks would freeze the system for that entire window.

**Alternatives rejected:** In-place mutation (no protection against drift at all); event-sourcing diffs (reconstruction complexity not justified at this scale); pessimistic locking (impractical hold times); two-phase commit (no distributed nodes to coordinate).

**Technical trade-offs:** No automatic merge on conflict — the second writer must reload and resubmit. Full snapshots cost more storage than diffs; accepted because campaign payloads are small.

**Limitations:** A true simultaneous race (not a retry-after-success) is not fully closed by this mechanism alone; a formal idempotency-key scheme is a related, separate, and not-yet-designed concern.

**Reconsider when:** Write contention becomes frequent enough that "reload and retry" becomes a real user-experience problem, or if the requirements baseline's per-stage approval model (ADR-006) is adopted, which would extend this to multiple approval records per version.

---

## ADR-003 — Event Processing

**Decision summary:** In-process domain events, emitted only after a transaction commits, consumed asynchronously by a notification adapter whose failures are never surfaced back to the triggering operation.

**Why this approach:** The ordering — emit after commit, never before — is what structurally guarantees a notification outage cannot roll back an already-durable state change. No broker is justified: there is exactly one consumer in a single process.

**Alternatives rejected:** Synchronous inline notification dispatch (couples an external service's reliability to a core business transaction); external message broker (operational overhead with no distributed consumers to justify it).

**Technical trade-offs:** Retry/backoff logic is hand-built rather than broker-provided. No durable outbox table exists — an in-flight notification can be lost if the process terminates before delivery.

**Limitations:** This mechanism only works because everything runs in one process; it would need redesign if a real backend were introduced.

**Reconsider when:** The architecture gains a backend (ADR-006), at which point a durable, database-backed outbox becomes both possible and arguably necessary.

---

## ADR-004 — Authorization Boundary and No-Backend Deployment

**Decision summary:** Role and self-review checks enforced in Application and Domain code, on-device; explicitly documented as not satisfying a literal server-side-enforcement reading of the requirements, because there is no server.

**Why this approach:** Given no backend exists in this deliverable, the technical strength of on-device enforcement is the same whether or not the gap is disclosed — the only real choice was whether to state it. Stating it is both more honest and, in an architecture review, more defensible than having a reviewer discover an unstated gap.

**Alternatives rejected:** Building a minimal real backend for the hackathon deliverable (materially larger scope, disproportionate to team size and timeline — a decision this ADR does not reopen, but that ADR-006 revisits as one explicit resolution path).

**Technical trade-offs:** A modified client binary could, in principle, bypass on-device checks. This is the central, named limitation of the architecture as it stands.

**Limitations:** Not production-ready from a security standpoint against adversarial users without a backend.

**Reconsider when:** The project moves toward production deployment, or the team resolves ADR-006 in favor of introducing a real backend.

---

## ADR-005 — Persistence Strategy

**Decision summary:** Local-first persistence via Drift over SQLite; no remote database or backend API.

**Why this approach:** A direct consequence of ADR-004 — with no backend, a remote database was never a live option. Among local choices, Drift's relational model fits the domain's actual shape (campaign → versions → approvals → audit) better than an object-store, with meaningfully less defect risk than raw SQL for a two-person team.

**Alternatives rejected:** Raw SQLite (more hand-written SQL, more defect surface); Isar (weaker fit for relational joins); backend API + managed database (contradicts ADR-004).

**Technical trade-offs:** No cross-device synchronization — a hard limitation, not an oversight. No backup/restore infrastructure beyond on-device crash-safety.

**Limitations:** Single-tenant only; no disaster-recovery story beyond what SQLite's WAL mode provides.

**Reconsider when:** Multi-device support becomes a real requirement, or ADR-006 resolves toward a server-backed data model.

---

## ADR-006 — The Unresolved Reconciliation

**Decision summary:** Not a decision — a documented conflict. The requirements baseline (updated after the Solution Design was built) now specifies a three-stage sequential approval pipeline with server-side, database-backed enforcement; the current Solution Design implements a single-approval, local-first, no-backend architecture. Neither has been changed to match the other.

**Why this is presented, not hidden:** Discovering and disclosing this during architecture-decision documentation is itself evidence of a working review process. The alternative — silently picking one side while writing the rest of the documentation as if it were already resolved — would be a materially worse failure than the discrepancy itself.

**What it costs to acknowledge:** It invites the hardest questions a judge can ask. `anticipated-questions.md` prepares direct, non-evasive answers for exactly that.

**Reconsider when:** Immediately — before final submission, ADR-006 recommends the team explicitly choose one of its three documented resolution paths (extend the architecture, re-scope the requirements, or present a clearly-separated MVP/target-state narrative).
