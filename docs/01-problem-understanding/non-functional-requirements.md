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

### NFR-001: Approval State Consistency — Critical

No campaign may exist in a state that contradicts its approval history. An approval decision must be durably recorded before the campaign state transition is visible to any user.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Two authorised Reviewers (ST-002) |
| **Stimulus** | Both attempt to approve the same campaign version simultaneously |
| **Environment** | Campaign is in Pending Review state; single-approval model is configured |
| **Response** | The system accepts the first valid approval and transitions the campaign to Approved. The second request either succeeds idempotently (same outcome) or is rejected with a clear message that the campaign is no longer in Pending Review state |
| **Measure** | No campaign version receives contradictory final state transitions. The campaign is in exactly one state at any point in time. Zero data anomalies in approval records |

**Architectural implication:** State transitions must be atomic. Optimistic concurrency control (version-based) or pessimistic locking is required on the campaign aggregate.

---

### NFR-002: Version-Approval Binding Integrity — Critical

An approval decision must be immutably bound to the specific campaign version that was reviewed. The system must never allow scheduling of a campaign version different from the approved version.

**Scenario:**

| Aspect | Detail |
|---|---|
| **Source** | Marketer (ST-001) |
| **Stimulus** | Attempts to schedule a campaign after modifying it post-approval |
| **Environment** | Campaign was Approved at version N; Marketer edited it, creating version N+1 |
| **Response** | The system detects the version mismatch, invalidates the approval, and prevents scheduling. The campaign returns to Draft state requiring re-submission |
| **Measure** | 100% of scheduling operations verify version match with the approval record. No campaign is ever scheduled with an unapproved version |

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

| ID | Assumption | Traces to |
|---|---|---|
| A-005 | Small-to-medium marketing teams (5–50 users, tens to hundreds of campaigns) | NFR-014, NFR-015 |
| A-012 | Campaign state transitions are synchronous and strongly consistent | NFR-001 |
| A-013 | The system does not need to handle more than ~50 concurrent users for the initial architecture | NFR-015 |
| A-014 | Notification delivery is asynchronous and best-effort; failures do not block core workflow | NFR-005 |

---

## Open Questions

| ID | Question | Traces to |
|---|---|---|
| OQ-003 | Is multi-tenancy a requirement? Determines whether NFR-011 is in scope. | NFR-011 |
| OQ-014 | What consistency model does the team prefer? Strong consistency (simplest to reason about) vs. eventual consistency (better availability)? | NFR-001 |
| OQ-015 | Are there specific regulatory compliance requirements (GDPR, FINRA, HIPAA) that affect audit retention? | NFR-013 |
| OQ-016 | Should the system support offline-capable operations on mobile (e.g., draft creation while offline, sync when connected)? | NFR-004, NFR-005 |
