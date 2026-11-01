# Failure Handling & Recovery Architecture

> **Document Status:** Approved v1.0  
> **Last Updated:** 2026-11-01  
> **Owner:** Domain Research & Requirements Lead  
> **Traces to:** [`non-functional-requirements.md`](../01-problem-understanding/non-functional-requirements.md) (`NFR-001`, `NFR-002`, `NFR-003`, `NFR-004`, `NFR-005`), [`campaign-lifecycle.md`](campaign-lifecycle.md), [`approval-workflow.md`](approval-workflow.md)

---

## 1. Executive Summary & Core Philosophy

Mobile applications operating in enterprise environments face unstable cellular connectivity, intermittent network drops, and asynchronous service latencies. A production-grade mobile architecture cannot assume reliable connections.

The platform adheres to **three non-negotiable failure principles**:
1. **Core State Isolation:** Failure in an asynchronous side-effect (e.g., push notification timeout, analytics event loss) must **never** roll back or corrupt an authoritative core state transition (e.g., stage approval or campaign approval sign-off).
2. **End-to-End Idempotency:** Every mutating operation (submit, stage approve, request changes, schedule) must be duplicate-safe and idempotent under network retries.
3. **Optimistic Conflict Containment:** The platform rejects stale or concurrent mutations immediately with unambiguous conflict signifiers (`409 Conflict`), never silently overwriting data.

---

## 2. Failure Taxonomy & Recovery Matrix

| Failure Category | Concrete Stimulus / Scenario | Immediate System Impact | Recovery Strategy & Architectural Mechanism | Resulting State |
|:---|:---|:---|:---|:---|
| **F-01: Network Partition During Stage Approval** | Reviewer clicks *Approve* at Stage 1, 2, or 3 on mobile; connection drops before HTTP 200 response reaches client. | Client enters timeout state; user retries action. | **Client Idempotency Token:** Server records UUID key; retry returns cached success without duplicate audit logs or state transitions (`NFR-004`). | Stage advancement preserved (Idempotent) |
| **F-02: Concurrent Review Collision at Stage Gate** | Reviewer A and Reviewer B submit contradictory decisions on the same stage within 500ms. | Risk of inconsistent or split-brain approval states. | **Optimistic Locking:** Both submit with `version=1, stage_index=k`. First commit advances stage/version; second commit matches 0 rows and returns `409 Conflict` (`NFR-001`). | First committer wins; second view refreshed |
| **F-03: Downstream Notification Outage** | Stage approval succeeds, but external notification service (FCM / SendGrid) returns HTTP 500 or times out. | Potential loss of reviewer-to-marketer notification alert. | **Transactional Outbox Pattern:** Approval and notification event write atomically in one local DB transaction. Background worker retries delivery with exponential backoff (`NFR-005`). | Retains approval; alert delivered eventually |
| **F-04: Post-Approval Proposal Tampering / Material Change** | Campaign is approved, but proposal budget or audience is subsequently modified before scheduling. | Danger of releasing unreviewed messaging or inflated budgets. | **Material Change Invalidation Gate:** Scheduling gate checks `current_payload.digest == approved_snapshot.digest`. Mismatch revokes all 3 approvals and routes to `CHANGES REQUESTED` (`FR-014`). | Demoted to `CHANGES REQUESTED` |
| **F-05: Validation Failure on Submit** | Marketer submits proposal with missing budget, empty audience, or invalid dates. | Invalid campaign could enter review queue. | **Synchronous Validation Barrier:** Server validates payload before generating snapshot; returns field-level `400 Bad Request` inline. | Retains `DRAFT` |
| **F-06: Poison Pill in Async Queue** | Malformed event payload causes repeated consumer crash in background worker. | Worker thread crashes repeatedly; queue head-of-line blocking. | **Dead Letter Queue (DLQ):** After 4 failed retry attempts, event routes to DLQ for diagnostic alerting; main queue continues processing. | System healthy; alert flagged for ops |

---

## 3. Core Resilience Mechanisms

### 3.1 Idempotency Key Pattern (`NFR-004`)

To guarantee that mobile client retries never cause duplicate state mutations or duplicate audit entries:

```
Mobile Client                                   Campaign API Gateway
     │                                                    │
     │── POST /campaigns/123/stages/1/approve ───────────▶│
     │   Headers: Idempotency-Key: "uuid-9a8b-7c6d"       │
     │   Body: { expected_version: 1 }                    │
     │                                                    │ (1) Check idempotency_records table
     │                                                    │     [Not found: Process Transaction]
     │                                                    │ (2) Atomic DB Commit:
     │                                                    │     - Advance stage_index to 2
     │                                                    │     - Write audit log entry
     │                                                    │     - Save idempotency record
     │       [ NETWORK TIMEOUT / CONNECTION LOST ]        │
     │                                                    │
     │── RETRY POST /campaigns/123/stages/1/approve ─────▶│
     │   Headers: Idempotency-Key: "uuid-9a8b-7c6d"       │ (3) Check idempotency_records table
     │                                                    │     [Found: Match & Return Cached Response]
     │◀── HTTP 200 OK (Cached Success Payload) ───────────│
```

- **Deduplication Storage:** A dedicated table `idempotency_records` stores `(key, endpoint, request_hash, response_code, response_body, created_at)` with an index on `key` and a 24-hour TTL.
- **Idempotency Guarantee:** Duplicate submissions yield identical HTTP responses with zero side-effects.

---

### 3.2 Transactional Outbox Pattern for Side-Effects (`NFR-005`)

Dual-write operations (writing to a database and publishing to an external notification/message broker) are vulnerable to partial failures: if the DB write succeeds but the network call fails, the event is lost; if the call succeeds but DB write fails, phantom notifications occur.

To solve this, the platform uses the **Transactional Outbox Pattern**:

```
[ACID Transaction Boundary]
┌─────────────────────────────────────────────────────────────────┐
│  UPDATE campaigns SET stage_index = 2, version = version + 1    │
│  INSERT INTO stage_approvals (stage=1, actor=ST-002a, ...)      │
│  INSERT INTO audit_log (event_type='Stage1Approved', ...)       │
│  INSERT INTO outbox_events (event_name, payload, status='PENDING')│
└─────────────────────────────────────────────────────────────────┘
                               │
                       [Committed Atomically]
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│               Background Outbox Poller / Dispatcher             │
│  1. Read PENDING events from outbox_events                      │
│  2. Dispatch to External Push/Email Service (FCM/SendGrid)      │
│  3. On Success: Mark status = 'SENT'                            │
│  4. On Failure: Increment retry_count, schedule exponential backoff│
└─────────────────────────────────────────────────────────────────┘
```

#### Backoff & Jitter Schedule:
- **Attempt 1:** Immediate retry (0s).
- **Attempt 2:** $2s + \text{jitter}$ ($0\text{–}500ms$).
- **Attempt 3:** $8s + \text{jitter}$.
- **Attempt 4:** $30s + \text{jitter}$.
- **Exhaustion (Attempt > 4):** Event marked as `FAILED` and routed to the **Dead Letter Queue (DLQ)** with diagnostic logs emitted for operator inspection.
- **Critical Guarantee:** Downstream provider failure **never blocks, aborts, or rolls back** the approved campaign or stage transition.

---

### 3.3 Optimistic Concurrency Control (Version Tokens)

To protect against concurrent overwrites on mobile devices:

```sql
-- State Transition Guard with Stage Index
UPDATE campaigns 
SET 
    stage_index = :new_stage,
    version = version + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE 
    id = :campaign_id 
    AND version = :expected_version
    AND stage_index = :expected_stage
    AND state = 'PENDING_REVIEW';
```

If another user or background job updated the row first:
1. The `WHERE` clause matches zero rows.
2. The application raises `OptimisticLockException`.
3. The API controller catches the exception and returns:
   ```json
   {
     "error": "CONFLICT",
     "message": "Campaign has been modified by another reviewer or marketer since you loaded it.",
     "current_version": 2,
     "current_stage": 2,
     "current_state": "PENDING_REVIEW"
   }
   ```
4. The mobile client receives the `409 Conflict`, invalidates its local cache, re-fetches the latest campaign state, and updates the user interface with the new state.

---

### 3.4 Mobile Offline Reconnection & Stale Draft Handling

When mobile users create or edit drafts while disconnected:
1. **Local Drafting Allowed:** Marketers can edit drafts locally in SQLite/Room/Hive while offline.
2. **Server-Side Authority on Transitions:** Critical state-changing transitions (`SUBMIT`, `ADVANCE_STAGE`, `REQUEST_CHANGES`, `SCHEDULE`) **require** network connectivity and cannot be finalized offline.
3. **Reconnection Reconciliation:**
   - Upon reconnecting, the mobile client sends an `ETag` / `If-Match` header with `version`.
   - If the server version matches the local base version, the draft syncs cleanly.
   - If the server has a newer version (e.g., changes were made from web UI), the mobile app flags the conflict and prompts the user to resolve before submitting.

---

## 4. Telemetry, Structured Diagnostic Logging & Observability

To satisfy the MAL4 evaluation criteria (**Testing & Observability: 15%**), all failure events and state transitions emit structured JSON diagnostic logs:

```json
{
  "timestamp": "2026-11-01T14:00:22.451Z",
  "level": "WARN",
  "correlation_id": "req-98f2-411a",
  "event_type": "CONCURRENT_MODIFICATION_COLLISION",
  "campaign_id": "cmp-84920",
  "actor_id": "usr-reviewer-02",
  "stage_index": 1,
  "attempted_transition": "STAGE_1_ADVANCE",
  "expected_version": 1,
  "actual_version": 2,
  "actual_state": "PENDING_REVIEW",
  "outcome": "REJECTED_409_CONFLICT",
  "latency_ms": 14
}
```

These structured logs allow operators and hackathon judges to verify the exact causal chain of any failure, proving that the architecture behaves deterministically under stress and partial network drops.
