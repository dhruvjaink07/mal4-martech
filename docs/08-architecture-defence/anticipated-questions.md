# Anticipated Questions — Judge Question Bank

> **Purpose:** A comprehensive, organized set of technical questions a judge or reviewer could reasonably ask, with direct and detailed answers grounded in the actual design. Where the architecture cannot fully guarantee something, the answer says so.

---

## 1. Architecture Fundamentals

### Q1.1 — What problem does this architecture actually solve?
**Short answer:** It makes campaign approval trustworthy and auditable — an approval applies to one exact version, concurrent edits can't silently corrupt state, and every lifecycle action is permanently recorded.

**Detail:** The core risk this replaces is informal, tool-fragmented campaign governance where teams lose track of state, approve one version and release another, or have no record of who approved what. The architecture enforces a finite state machine, immutable version snapshots, version-bound approvals, and an append-only audit trail as structural guarantees, not conventions.

**Reference:** `docs/08-architecture-defence/architecture-overview.md`; HLD §4.2 (Executive Summary).

**Follow-up:** *What specifically would go wrong without this architecture?* — A campaign could be approved at version 1 and silently scheduled at version 2; there would be no reliable record of which reviewer approved what, or when.

---

### Q1.2 — Why is this architecture appropriate for a two-person team?
**Short answer:** Every structural decision was explicitly evaluated against team size and timeline, and the team deliberately avoided ceremony or infrastructure that didn't pay for itself in testability or correctness.

**Detail:** ADR-001 rejects full Clean Architecture's ring/mapper ceremony in favor of a lighter layering that keeps the one property that matters (a testable, isolated domain) without the overhead. ADR-004/ADR-005 reject a backend specifically because standing one up is a materially larger, separate engineering effort disproportionate to two people in a hackathon timeline. The architecture is not under-engineered by accident — every simplification is named and justified.

**Reference:** ADR-001, ADR-004, ADR-005.

**Follow-up:** *Doesn't that mean the architecture is incomplete?* — Yes, explicitly — see ADR-006 and `risks-and-limitations.md`. The team chose to build a smaller, defensible thing correctly rather than a larger thing partially.

---

### Q1.3 — What does "the domain has zero outward dependencies" actually mean, and why does it matter?
**Short answer:** The `Campaign` aggregate and its business rules don't import Flutter, a database driver, or a network client — they can be unit-tested with plain Dart.

**Detail:** This is what makes the lifecycle/approval invariants testable without standing up a UI or a database for every test, which is both a software-quality practice and a named MAL4 evaluation criterion (Testing & Observability).

**Reference:** ADR-001; LLD §5.2.4.C (`Campaign` class).

---

## 2. Architecture Style and Module Boundaries

### Q2.1 — Why did you choose this architecture instead of microservices?
**Short answer:** Microservices solve problems this project doesn't have — independent team deployment cadence and divergent per-component scaling needs — at an operational cost (service discovery, network resilience, distributed data consistency) this project can't absorb.

**Detail:** This is a single mobile application with one feature, used by 5–50 people. There is no component that needs to scale independently of another, and no second team that needs to deploy on a different schedule. Modular Monolith gives internal modularity (separate, enforced module boundaries for Campaign Management, Review & Approval Workflow, Audit, Notification, Scheduling) without the distributed-systems cost.

**Reference:** ADR-001; `trade-offs.md` §3.1.

**Follow-up:** *What would make microservices the right call?* — Multiple independent teams needing separate deploy schedules, or genuinely divergent scaling requirements between components — neither applies here.

---

### Q2.2 — How are module boundaries enforced, not just documented?
**Short answer:** By dependency direction — Presentation depends on Application only, Application depends on Domain only, Infrastructure implements interfaces Domain/Application own. No code exists yet to point to as proof it's never violated, which is stated honestly.

**Detail:** The intended enforcement mechanism is a Dart lint rule forbidding `domain/` from importing Flutter or persistence packages — this is a recommendation for implementation time, not yet configured, since no implementation exists.

**Reference:** LLD §5.2 package architecture; ADR-001.

---

### Q2.3 — Why merge "Review Management" and "Approval Workflow" into one module?
**Short answer:** Because a Reviewer's decision *is* the approval — there is no independent "review" activity with its own data or rules separate from the decision itself.

**Detail:** Splitting them would create a seam with nothing on either side of it to justify it. This was a deliberate consolidation decision, documented as such, not an oversight.

**Reference:** HLD §4.9 (Module Decomposition); LLD §5.2.4.

---

## 3. Campaign Lifecycle

### Q3.1 — Why exactly six states, and why not the three-stage sub-structure the requirements describe?
**Short answer:** Six states is what the Solution Design implements; the three-stage sub-structure within "Pending Review" is specified in the requirements baseline but was never built into the Solution Design — this is the central unresolved item tracked in ADR-006.

**Detail:** This question deserves a direct, non-evasive answer: the requirements documentation was expanded after the Solution Design was built, to specify a three-stage sequential pipeline (Creative → Compliance → Finance), and the two were never reconciled. The team is presenting the architecture as actually designed and is not claiming it already implements the newer requirement.

**Reference:** ADR-006 (full detail); `risks-and-limitations.md` §0.

**Follow-up:** *Which one is correct?* — Neither is "incorrect" in isolation; they are two states of the same project that diverged and need a conscious reconciliation decision, which ADR-006 frames as three explicit options.

---

### Q3.2 — What stops an illegal state transition, like approving a Draft campaign?
**Short answer:** The `Campaign` aggregate's own guard — every transition method checks the current state against an explicit allow-list and throws before any persistence call if the transition isn't legal.

**Detail:** This check exists in the domain layer, so it applies regardless of what the UI does or doesn't allow — a UI bug or a deliberately malformed request gets the same rejection.

**Reference:** LLD §5.2.4.C, §6.1 (formal transition table).

---

## 4. Approval and Version Management

### Q4.1 — How do you prevent a stale approval from being applied to a newer campaign version?
**Short answer:** Every review decision loads the campaign fresh and compares the reviewer's believed-current version against the aggregate's actual current version; a mismatch is rejected before any approval record is created.

**Detail:** Concretely: a reviewer opens version 1; the marketer withdraws, edits, and resubmits as version 2; the reviewer, unaware, attempts to approve "version 1." The system detects `1 != 2` and raises `StaleReviewError` — the reviewer is told to reload and review the current version. This check happens in the domain layer, never only in the UI.

**Reference:** LLD §6.1 (full reconciled scenario), ADR-002.

---

### Q4.2 — What happens to an approval if the campaign is edited after approval?
**Short answer:** Any edit to an Approved campaign is treated as a material change — it invalidates the existing approval (marked superseded, not deleted) and returns the campaign to Draft before the edit is applied.

**Detail:** Invalidation and the edit are two sequential, independently audited steps — never silently collapsed into one operation, so the audit trail shows exactly when and why an approval was superseded.

**Reference:** HLD §4.12 (material-change flow); LLD §6.2.

---

### Q4.3 — Why is version binding version-number-based rather than cryptographic hash-based, as the requirements baseline now specifies?
**Short answer:** The current implementation uses an integer version token, sufficient for detecting staleness and write conflicts within this architecture; it does not provide the same tamper-evidence a cryptographic hash would, and that gap is named explicitly rather than implied as equivalent.

**Reference:** ADR-002; `risks-and-limitations.md` §2.

---

## 5. Data Consistency and Concurrency

### Q5.1 — What happens when two users edit the same campaign?
**Short answer:** The first write to complete succeeds; the second is rejected with an explicit conflict error and must reload before retrying. No silent overwrite, no automatic merge.

**Detail:** Every write carries the version the caller loaded. If the stored version has advanced by the time the write is attempted, the write fails atomically at the repository boundary. This is deliberately not auto-resolved — merging campaign fields automatically is not safe to do without human judgment.

**Reference:** ADR-002 (full concurrency pseudocode); LLD §6.4.

---

### Q5.2 — Why optimistic concurrency instead of locking?
**Short answer:** Reviewers hold a campaign "open" for minutes to hours of evaluation time; a pessimistic lock held across that window would make the app unusable for anyone else during that time, for no real benefit at this scale.

**Reference:** ADR-002 (alternatives comparison table).

---

### Q5.3 — What guarantees exist against a true race condition, not just a retry?
**Short answer:** None yet, fully — this is named explicitly as an open item. The optimistic-concurrency mechanism protects against a second write *after* a first write has already completed; closing the gap for two writes arriving in the same instant requires a formal idempotency-key scheme, which has not been designed.

**Reference:** ADR-002 "Negative Consequences"; `risks-and-limitations.md` §1.

---

## 6. Security and Authorization

### Q6.1 — What prevents an unauthorized user from approving a campaign?
**Short answer:** Every review-decision use case checks the actor's role, and separately checks that the reviewer is not the original submitter, before any domain mutation — enforced in Application and Domain code, not the UI.

**Detail:** The self-review check happens twice: once in the Application layer (identity vs. the request), and again defensively inside the `Campaign` aggregate itself (identity vs. the version's recorded submitter) — these answer slightly different questions, so neither is redundant.

**Reference:** ADR-004; LLD §5.2.1, §5.2.4.C.

---

### Q6.2 — How is the system protected if the UI is bypassed?
**Short answer:** It is protected to the extent that the Application and Domain layers, not the UI, perform every authorization and business-rule check — a request that skips the UI entirely still has to pass through the same use-case and aggregate guards.

**Detail:** What it does *not* protect against is a modified client binary making calls as if it were the legitimate app — there is no server process independent of that client to refuse the call. That is the architecture's named limitation, addressed directly in Q6.3.

**Reference:** HLD §4.13 (Security Architecture — Permission Enforcement).

---

### Q6.3 — What are the security implications of having no backend?
**Short answer:** Authorization is enforced on-device, in the same process as the UI. This satisfies the *intent* of the requirement (checks aren't bypassable by skipping client-side validation) but not a literal server-side-enforcement guarantee, because there's no process boundary a modified client can't cross.

**Detail:** This is the single most significant, explicitly disclosed limitation of the architecture. It was a conscious trade-off (ADR-004) given team size and timeline, not an oversight. It is not production-ready against an adversarial user without a real backend.

**Reference:** ADR-004 (full rationale); `risks-and-limitations.md` §2.

**Follow-up:** *Isn't that a disqualifying flaw?* — It is a real, named limitation of an MVP-scoped architecture presented honestly, not a silently hidden one — and the system still enforces every rule in code that a UI alone cannot be coerced into skipping, which is strictly stronger than client-only validation.

---

### Q6.4 — Why is self-review prevention checked twice, in two layers?
**Short answer:** Defense in depth — the Application-layer check and the Domain-layer check answer different questions (request identity vs. the specific version's recorded submitter) and either could, in principle, be reached independently of the other as the system evolves.

**Reference:** LLD §5.2.4.C.

---

## 7. Persistence

### Q7.1 — Why Drift over SQLite instead of a cloud database?
**Short answer:** Given the decision to not build a backend (ADR-004), a cloud database was never a live option; among local choices, Drift's relational, type-safe model fits the domain's actual shape better than a raw-SQL or object-store alternative.

**Reference:** ADR-005 (full alternatives comparison).

---

### Q7.2 — How is the audit log guaranteed to stay consistent with campaign state?
**Short answer:** They commit in the same local database transaction — there is no code path where one is written without the other.

**Reference:** ADR-002, ADR-005; LLD §5.2.5.

---

### Q7.3 — What would need to change to support multiple devices?
**Short answer:** A backend and a synchronization/conflict-resolution strategy, neither of which exists today — this architecture is explicitly local-first and single-device.

**Detail:** The repository and adapter interfaces (`CampaignRepository`, `AuthProvider`, `NotificationGateway`) already exist as seams that a networked implementation could be substituted behind without rewriting use cases or domain logic — but the networked implementation, and the conflict-resolution logic multi-device editing would require, have not been designed.

**Reference:** `risks-and-limitations.md` §3, §7; ADR-005, ADR-006.

---

## 8. Reliability and Error Handling

### Q8.1 — How do you ensure an audit entry is not lost when a state transition fails?
**Short answer:** They're written in one transaction — if the write fails, both the state change and its audit entry roll back together; there is no scenario where one exists without the other.

**Reference:** ADR-002, ADR-005; HLD §4.14.

---

### Q8.2 — What happens if notification delivery fails?
**Short answer:** Nothing happens to the already-committed state change. The failure is logged and retried in the background, and is never surfaced back to the use case or the user as a transaction failure.

**Detail:** This is guaranteed by ordering: the domain event that triggers notification dispatch is emitted strictly *after* the write commits, so a failure in the dispatch path happens causally after the point where it could have affected the transaction's outcome.

**Reference:** ADR-003; LLD Figure 3 (Error Recovery Sequence).

**Follow-up:** *Could a notification be lost permanently?* — Yes, if the process terminates before delivery completes — there is no durable outbox table yet. Named explicitly as an open item in ADR-003 and `risks-and-limitations.md`.

---

### Q8.3 — What happens if the app is killed mid-operation?
**Short answer:** On restart, the persisted state reflects only the last committed transaction — nothing to reconcile, because nothing partial was ever written.

**Reference:** HLD §4.14 (Reliability); LLD failure-scenario table (reliability architecture).

---

## 9. Testing and Maintainability

### Q9.1 — How would you test the lifecycle rules without a UI?
**Short answer:** Directly — the `Campaign` aggregate is plain Dart with no Flutter or database dependency, so every transition rule, version-binding check, and self-review guard can be unit-tested in isolation.

**Reference:** ADR-001; LLD §5.2 (test specifications per module).

---

### Q9.2 — What test coverage is claimed, and what evidence exists for it?
**Short answer:** None yet, honestly — no code has been written. The LLD catalogs intended test scenarios (e.g. the stale-review scenario, concurrent-write conflicts, self-review rejection) as a specification for what will be tested, not as evidence that it has been.

**Reference:** LLD §5.2.K (per-module test specifications).

---

## 10. Scalability and Future Evolution

### Q10.1 — How would the architecture evolve if the user base increased?
**Short answer:** Within the current local-first design, there's limited room — it's bounded by a single device's capacity. Meaningful growth in users or cross-device needs requires the backend extension path already named in ADR-006, not a configuration change.

**Reference:** `risks-and-limitations.md` §4, §7.

---

### Q10.2 — What's the actual extension path to a real backend?
**Short answer:** The repository and adapter interfaces already exist as the seam; a networked implementation can be substituted behind them without rewriting use cases or domain logic. What's missing is the backend itself, an API contract, and a sync/conflict strategy.

**Reference:** `risks-and-limitations.md` §7 (table); ADR-004, ADR-005.

---

## 11. Technology Choices

### Q11.1 — Why Flutter and Dart?
**Short answer:** Fixed by the MAL4 challenge's mobile-first requirement — not an evaluated choice.

**Reference:** HLD §4.7.

---

### Q11.2 — Is Riverpod a finalized choice?
**Short answer:** No — it's the leading candidate, evaluated against Bloc and Provider, but not yet implemented or finalized, since no code exists.

**Reference:** HLD §4.7; `trade-offs.md` §3.3.

---

## 12. Limitations and Trade-offs

### Q12.1 — Which decisions would you revisit before production deployment?
**Short answer:** Three, in priority order: introducing a real backend for genuine server-side enforcement (ADR-004); resolving the multi-stage approval question one way or the other (ADR-006); and designing a durable outbox plus a formal idempotency-key scheme (ADR-002, ADR-003).

**Detail:** None of these were accidental gaps — each is a named, deliberate trade-off against team size and timeline. Revisiting them is what moving from a hackathon MVP to a production system would require.

**Reference:** `risks-and-limitations.md` (complete); ADR-006.

---

### Q12.2 — If you had to defend one single decision as the most important in this project, which would it be, and why?
**Short answer:** The decision to disclose the requirements/architecture divergence (ADR-006) rather than resolve it silently in either direction.

**Detail:** Every other decision in this project is a standard, well-reasoned architectural trade-off. Choosing to surface — rather than paper over — a discovered conflict between what was built and what was later specified is the decision that makes the rest of this documentation trustworthy.

**Reference:** ADR-006.
