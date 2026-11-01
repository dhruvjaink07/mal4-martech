# Non-Functional Requirements

> **Document Status:** Draft v1.0
> **Last Updated:** 2026-11-01
> **Owner:** Domain Research & Requirements Lead
> **Traces to:** [Problem Statement](problem-statement.md), [Functional Requirements](functional-requirements.md)

---

## Overview

Non-functional requirements (NFRs) define quality attributes that the system must exhibit. Each NFR is specified as a measurable scenario following the SEI quality attribute scenario template:

- **Source of stimulus** — Who or what triggers the scenario.
- **Stimulus** — The event or condition.
- **Environment** — The operating context when the stimulus occurs.
- **Response** — How the system must behave.
- **Response measure** — How we verify the system met the requirement.

Numerical thresholds are marked as **provisional** when not derived from confirmed workload data. They represent reasonable targets for a system serving small-to-medium marketing teams (5–50 users, assumption A-005).

---

## 1. Consistency

### NFR-001: Approval State Consistency (Multi-Stage Pipeline) — Critical

No campaign may exist in a state that contradicts its approval history or stage sequence. An approval decision at any stage (Stage 1 Creative, Stage 2 Compliance, Stage 3 Finance) must be durably recorded in the database before the campaign state or stage transition is visible to any user.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Two authorised Reviewers (or a Reviewer and Marketer concurrently) |
| **Stimulus** | Reviewer A attempts to approve Stage 1 while Reviewer B attempts to request changes on the same version, or Marketer attempts concurrent edit |
| **Environment** | Campaign is in `Pending Review [Stage 1]` at version snapshot $vN$ |
| **Response** | The system accepts the first write atomically via database-level optimistic locking (`WHERE id = :id AND version = :v AND stage_index = 1`). The second request fails with `409 Conflict`, notifying the user that the stage has already transitioned. No contradictory stage transitions can ever be committed |
| **Measure** | 100% atomic stage transitions. Zero contradictory approval records. Monotonically increasing stage index ($1 \rightarrow 2 \rightarrow 3$). Zero race condition state corruptions |

**Architectural Defensible Position:**
- *Chosen Approach:* Synchronous database-level optimistic locking (`version` counter) combined with unique client `Idempotency-Key` headers.
- *Why Chosen:* Guarantees strong consistency without blocking database threads. Perfectly suited for mobile clients experiencing network latencies and cellular reconnections.
- *Why Not Pessimistic Locking:* Locking database rows (`SELECT FOR UPDATE`) across mobile network roundtrips risks hanging database connections indefinitely when reviewers disconnect in transit.

---

### NFR-002: Version-Approval Binding Integrity & Material Change Invalidation — Critical

An approval decision must be immutably bound to the specific campaign version snapshot that was reviewed. The system must cryptographically verify this binding at the scheduling gate, and must automatically invalidate prior approvals when material changes occur.

**Scenario 1: Version Mismatch at Scheduling Gate**

| Aspect | Detail |
|---|---|
| **Source** | Marketer (`ST-001`) or Scheduling Adapter |
| **Stimulus** | Attempts to schedule a campaign when the current campaign digest does not match the approved snapshot |
| **Environment** | Campaign was Approved at version $N$ with snapshot hash `0x9f1a`; current working state or draft is version $N+1$ with hash `0x4c2b` |
| **Response** | The system detects the cryptographic digest divergence, blocks the transition to `Scheduled`, returns `412 Precondition Failed`, and logs a security audit event |
| **Measure** | 100% of scheduling operations verify SHA-256 digest match against all 3 stage approvals. Zero unapproved or drifted versions are ever scheduled |

**Scenario 2: Material Change Invalidation**

| Aspect | Detail |
|---|---|
| **Source** | Marketer (`ST-001`) |
| **Stimulus** | Modifies budget by $+15\%$, alters target audience geography, or changes legal disclaimer copy on an approved campaign |
| **Environment** | Campaign is in `Approved` state (or in-review at Stage 2/3) |
| **Response** | The platform classifies the modification as **Material** (`FR-014`), revokes existing stage approvals, bumps version ($vN \rightarrow vN+1$), transitions state to `Changes Requested` (or `Draft`), and requires a fresh pass through the sequential review pipeline |
| **Measure** | 100% of material mutations trigger approval revocation and stage pipeline re-entry. Zero post-approval drift leakage |

**Architectural Defensible Position:**
- *Chosen Approach:* Cryptographic SHA-256 snapshot binding and automated material change detection.
- *Why Chosen:* Guarantees mathematical non-repudiation for regulatory audits (GDPR, FINRA, SOX 404). Eliminates post-approval drift where an unvetted revision is published.
- *Why Not Delta Diffs:* Reconstructing point-in-time state from event logs introduces projection lag and potential reconstruction drift on mobile clients. Immutable full snapshots guarantee instant $O(1)$ verification.

---

### NFR-003: Concurrent Edit Safety — High

The system must prevent lost updates when multiple users attempt to modify the same campaign simultaneously.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Two Marketers (or a Marketer and the system) |
| **Stimulus** | Both submit edits to the same campaign Draft at the same time |
| **Environment** | Campaign is in Draft state, being edited |
| **Response** | The system detects the conflict. The first write succeeds; the second write is rejected with a conflict error indicating the campaign has been modified since it was loaded |
| **Measure** | Zero silent data loss from concurrent edits. Every rejected edit returns a clear conflict response |

**Architectural implication:** Optimistic concurrency control using version numbers or ETags on the campaign entity.

---

## 2. Reliability

### NFR-004: Operation Idempotency — High

All state-transition operations must be idempotent. Retrying an operation (due to network timeout, client retry, or duplicate event delivery) must not produce incorrect state or duplicate records.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Mobile client with unreliable network |
| **Stimulus** | Submits an approval request; receives a network timeout; retries the same request |
| **Environment** | Normal operation; campaign is in Pending Review state |
| **Response** | If the first request succeeded, the retry returns the same successful result without creating a duplicate approval record. If the first request failed, the retry succeeds normally |
| **Measure** | Zero duplicate approval records from retried operations. Every operation that can be retried carries an idempotency key |

---

### NFR-005: Partial Failure Recovery — High

The system must handle partial operation failures gracefully. If a multi-step operation (e.g., record approval + send notification + update state) fails partway through, the system must either complete it or roll back to a consistent state.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | System internal failure |
| **Stimulus** | Approval is recorded in the database, but the subsequent notification to the Marketer fails |
| **Environment** | Normal operation |
| **Response** | The approval state transition is NOT rolled back (the durable business state is correct). The notification failure is logged and retried asynchronously. The system does not block on notification success |
| **Measure** | Zero cases where a successful approval is rolled back due to a notification failure. Notification retries are logged and observable |

**Architectural implication:** Core state transitions (write path) must be separated from side effects (notifications, analytics events). Side effects should be processed asynchronously with retry logic.

---

### NFR-006: System Availability — Medium

The system should target high availability for the core campaign workflow during business hours.

**Provisional targets:**

| Metric | Target | Basis |
|---|---|---|
| Availability (business hours) | 99.5% | Provisional — small team, non-revenue-critical path |
| Planned downtime | < 1 hour/month, outside business hours | Standard for internal tooling |
| Recovery Time Objective (RTO) | < 30 minutes | Data recovery from backup |
| Recovery Point Objective (RPO) | < 5 minutes | Minimal data loss on failure |

> **Note:** These are provisional. For a MAL4 deliverable, demonstrating awareness of availability design (not achieving five-nines) is sufficient. The architecture should explain what availability strategy it uses and why.

---

### NFR-007: Duplicate Scheduling Prevention — Critical

The system must guarantee that a campaign cannot be scheduled more than once from the same approved version.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Marketer or automated scheduler |
| **Stimulus** | Two scheduling requests for the same campaign arrive within a short window |
| **Environment** | Campaign is in Approved state |
| **Response** | The first request succeeds and transitions the campaign to Scheduled. The second request is rejected because the campaign is no longer in Approved state |
| **Measure** | Zero duplicate scheduling events per campaign version |

---

## 3. Security

### NFR-008: Authentication — Must

Every user interaction with the system must be authenticated. Unauthenticated requests must be rejected.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Unknown network client |
| **Stimulus** | Sends an API request without valid authentication credentials |
| **Environment** | Normal operation |
| **Response** | The system rejects the request with an appropriate error (401 Unauthorized) without processing it |
| **Measure** | Zero unauthenticated requests reach business logic |

---

### NFR-009: Authorisation Enforcement — Must

Every state-transition action must verify that the authenticated user has the required role and permissions for that action. Authorisation must be enforced server-side, not only in the client.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Authenticated user with Marketer role |
| **Stimulus** | Attempts to approve a campaign (an action restricted to the Reviewer role) |
| **Environment** | Normal operation |
| **Response** | The system rejects the request with a 403 Forbidden response |
| **Measure** | Zero successful operations performed by users without the required role |

---

### NFR-010: Self-Review Enforcement — Must

The system must prevent a user from reviewing (approving, rejecting, or requesting changes on) a campaign they submitted.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | User holding both Marketer and Reviewer roles |
| **Stimulus** | Submits a campaign, then attempts to approve it |
| **Environment** | Normal operation |
| **Response** | The approval attempt is rejected with a clear error explaining that self-review is not permitted |
| **Measure** | Zero self-approvals in the audit trail |

---

### NFR-011: Tenant Isolation — Conditional

If the system supports multiple organisations (multi-tenancy), data from one tenant must be completely invisible and inaccessible to users of another tenant.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Authenticated user in Organisation A |
| **Stimulus** | Attempts to access campaigns belonging to Organisation B (via API manipulation, URL guessing, etc.) |
| **Environment** | Multi-tenant deployment |
| **Response** | The system returns 404 Not Found (not 403 Forbidden, to avoid confirming the resource exists) |
| **Measure** | Zero cross-tenant data leaks. All database queries include tenant scoping |

> **Status:** Conditional on OQ-003 (Is multi-tenancy a requirement?). If single-tenant, this NFR is deferred. The architecture should document the multi-tenancy decision and its implications.

---

## 4. Auditability

### NFR-012: Immutable Audit Trail — Must

All significant lifecycle events must be recorded in an append-only audit log that cannot be modified or deleted, even by administrators.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Compliance auditor or System Administrator (ST-003) |
| **Stimulus** | Requests the complete approval history for a campaign that was published 6 months ago |
| **Environment** | Post-campaign analysis |
| **Response** | The system returns a complete, tamper-evident chronological record of every action taken on the campaign, including: who, what, when, which version, and any associated feedback |
| **Measure** | 100% of lifecycle events are present in the audit log. Audit entries have monotonically increasing timestamps. No gaps or modifications are possible |

**Architectural implication:** The audit log should be a separate, append-only data store (or append-only table). It must not share transactional writes with the campaign state in a way that allows rollback of audit entries.

---

### NFR-013: Audit Retention — Should

Audit records should be retained for a minimum period appropriate to the organisation's compliance requirements.

**Provisional targets:**

| Context | Retention Period | Basis |
|---|---|---|
| Default (non-regulated) | 12 months minimum | Business best practice |
| Financial services (FINRA/SEC) | 3+ years, first 2 years readily accessible | FINRA Rule 4511, SEC Rule 17a-4 |
| Healthcare (HIPAA) | 6 years | HIPAA record retention |

> **Note:** Retention periods are domain-specific. The architecture should separate audit storage from operational data to enable independent retention policies.

---

## 5. Performance

### NFR-014: Response Time — Medium

The system should provide responsive interaction for campaign management operations.

**Provisional targets (single-user perspective):**

| Operation | Target Response Time (p95) | Basis |
|---|---|---|
| Load campaign details | < 500ms | Standard web/mobile UX expectation |
| Submit campaign for review | < 1 second | Write operation with validation |
| Record approval decision | < 1 second | Critical path — must feel instantaneous |
| Load campaign list (paginated) | < 1 second | List view with filtering |
| Load audit history | < 2 seconds | Read-heavy, possibly large dataset |

> **Note:** These are provisional and assume small-to-medium workloads (A-005). The MAL4 deliverable should demonstrate responsive UX, not benchmark against these numbers.

---

## 6. Scalability

### NFR-015: Workload Scalability — Low Priority (for MAL4)

The architecture should identify which components are potential bottlenecks and explain how they could be scaled if workload increases.

**Provisional workload assumptions (A-005):**

| Dimension | Initial Scale | Notes |
|---|---|---|
| Concurrent users | 5–50 | Marketing team size |
| Active campaigns | 10–200 | Campaigns in non-terminal states |
| Campaign versions per campaign | 1–10 | Revision cycles |
| Review actions per day | 10–100 | Approvals, rejections, change requests |
| Audit events per day | 50–500 | All lifecycle events |

**Architectural implication:** At this scale, a single-instance architecture is sufficient. The architecture should identify where scaling would be needed and how it would be achieved, but does not need to implement distributed scaling for the MAL4 deliverable.

> **This is an architecture defence point:** Judges may ask "What happens if the workload grows 100x?" The answer should explain which components scale independently and which are bottlenecks, not claim the system already handles it.

---

## 7. Observability

### NFR-016: Diagnostic Logging — Must (MAL4: 15%)

The system must produce structured diagnostic logs that enable troubleshooting of campaign workflow issues.

**Requirements:**
- Every state transition must produce a log entry with: timestamp, campaign ID, version, actor, previous state, new state, and result (success/failure).
- Failed operations must log: error details, request context, and sufficient information to reproduce the issue.
- Log entries must be structured (JSON preferred) for programmatic analysis.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Developer / operations team |
| **Stimulus** | A campaign appears stuck in Pending Review with no visible reviewer action |
| **Environment** | Production or demo environment |
| **Response** | Diagnostic logs show: when the campaign was submitted, which notification was sent, whether the notification succeeded/failed, and whether any reviewer attempted to act |
| **Measure** | Every workflow path (happy path and error path) produces sufficient log entries to reconstruct what happened |

**MAL4 relevance:** Testing & observability is 15% of the MAL4 score. Diagnostic logs are an explicit deliverable.

---

### NFR-017: Health Monitoring — Should

The system should expose a health check endpoint indicating whether core dependencies (database, message queue if used) are available.

---

## NFR Summary and Prioritisation

| ID | Category | Requirement | Priority | MAL4 Relevance |
|---|---|---|---|---|
| NFR-001 | Consistency | Approval state consistency | Critical | Data & state management (15%) |
| NFR-002 | Consistency | Version-approval binding | Critical | Data & state management (15%) |
| NFR-003 | Consistency | Concurrent edit safety | High | Data & state management (15%) |
| NFR-004 | Reliability | Operation idempotency | High | Failure & recovery (10%) |
| NFR-005 | Reliability | Partial failure recovery | High | Failure & recovery (10%) |
| NFR-006 | Reliability | System availability | Medium | Trade-offs & adaptability (10%) |
| NFR-007 | Reliability | Duplicate scheduling prevention | Critical | Data & state management (15%) |
| NFR-008 | Security | Authentication | Must | Structure & boundaries (15%) |
| NFR-009 | Security | Authorisation enforcement | Must | Structure & boundaries (15%) |
| NFR-010 | Security | Self-review prevention | Must | Structure & boundaries (15%) |
| NFR-011 | Security | Tenant isolation | Conditional | Depends on OQ-003 |
| NFR-012 | Auditability | Immutable audit trail | Must | Testing & observability (15%) |
| NFR-013 | Auditability | Audit retention | Should | Trade-offs & adaptability (10%) |
| NFR-014 | Performance | Response time | Medium | Working user journey (15%) |
| NFR-015 | Scalability | Workload scalability | Low | Trade-offs & adaptability (10%) |
| NFR-016 | Observability | Diagnostic logging | Must | Testing & observability (15%) |
| NFR-017 | Observability | Health monitoring | Should | Testing & observability (15%) |

---

## Assumptions

| ID | Assumption | Traces to | Status |
|---|---|---|---|
| A-003 | The system implements a **multi-level sequential approval pipeline** (Stage 1: Creative → Stage 2: Compliance/Legal → Stage 3: Finance/Budget). All 3 must approve for the campaign to clear the scheduling gate. | NFR-001 | High (Resolved) |
| A-005 | Small-to-medium marketing teams (5–50 users, tens to hundreds of campaigns) | NFR-014, NFR-015 | High |
| A-011 | Material changes (budget $\ge \pm 10\%$, audience scope, claims/disclaimers, dates) automatically invalidate prior approvals and trigger re-approval. | NFR-002 | High (Resolved) |
| A-012 | Campaign state transitions are synchronous and strongly consistent via optimistic concurrency control (`WHERE id = :id AND version = :v`). | NFR-001 | High (Resolved) |
| A-013 | The system does not need to handle more than ~50 concurrent users for the initial architecture | NFR-015 | High |
| A-014 | Notification delivery is asynchronous and decoupled via Transactional Outbox; failures do not block core workflow | NFR-005 | High (Resolved) |

---

## Open Questions

| ID | Question | Traces to | Status | Defensible Resolution |
|---|---|---|---|---|
| OQ-001 | Multi-level approval vs. single-gate model? | NFR-001 | **Resolved** | **Multi-Level Sequential Pipeline Adopted.** Enforces strict segregation of duties (SOX 404, FINRA 2210) across Creative, Compliance, and Finance gates. |
| OQ-002 | What constitutes a material change triggering re-approval? | NFR-002 | **Resolved** | **Material Change Classification Adopted.** Changes to budget, audience scope, claims, or dates invalidate approvals; operational UTM tags do not. |
| OQ-003 | Is multi-tenancy a requirement? Determines whether NFR-011 is in scope. | NFR-011 | Bonus Scope | Single-tenant core domain model with clean tenant_id discriminator on boundary. |
| OQ-014 | What consistency model does the team prefer? Strong consistency vs. eventual consistency? | NFR-001 | **Resolved** | **Strong Consistency for State Changes.** Optimistic concurrency control serializes state transitions; asynchronous eventual consistency for notifications. |
| OQ-015 | Are there specific regulatory compliance requirements (GDPR, FINRA, HIPAA) that affect audit retention? | NFR-013 | Scoped | Standard append-only immutable audit trail with 12-month retention and WORM-compatible schema design. |
| OQ-016 | Should the system support offline-capable operations on mobile? | NFR-004, NFR-005 | **Resolved** | Offline drafting and local cached inspection supported; state-transition actions require server roundtrip with client `Idempotency-Key`. |
