# ADR-003: In-Process Domain Events for Side-Effect Decoupling

## Status

Accepted

## Decision Date

2026-11-01

## Context and Problem

A successful campaign state transition (e.g. an approval) should trigger a notification to the affected marketer. Notification delivery depends on an external service and can fail, time out, or be slow. A decision was required on how to connect "the state transition happened" to "a notification should be attempted" without letting the second concern compromise the first.

## Decision Drivers

- A confirmed, critical reliability requirement: a notification failure must never block or roll back an already-committed, authoritative state transition.
- The architecture has no backend and no message broker (see ADR-004) — any mechanism must work in a single process.
- Team size and timeline rule out operating external messaging infrastructure.

## Considered Alternatives

| Alternative | Description |
|---|---|
| Synchronous inline dispatch | The use case calls the notification service directly, in the same call path as the state transition, before returning to the caller. |
| External message broker / queue | State transitions publish to a broker (e.g. a managed queue service); a separate consumer processes notifications. |
| In-process domain events (selected) | The use case emits a plain in-memory event object after its transaction commits; a subscriber (`NotificationGateway`) consumes it asynchronously within the same process. |

## Evaluation and Comparison

| Criterion | Synchronous inline | External broker | In-process domain events (selected) |
|---|---|---|---|
| Isolates notification failure from the core transaction | No — a failure or timeout in the inline call can delay or fail the user-facing response | Yes | Yes |
| Operational footprint | None extra | A managed broker/queue to provision, configure, and monitor | None extra — plain in-process objects |
| Fit for a single-device, no-backend architecture | Workable but risky | Disproportionate — no distributed consumers exist to justify it | Good fit |
| Delivery guarantee sophistication | None beyond "it happened or it didn't" | Strong (broker-managed retries, dead-lettering) | Weaker — retry/backoff must be hand-built; acceptable at this scale |

## Selected Decision

Use cases emit a typed, in-process domain event (e.g. `CampaignApproved`) only **after** their database transaction has committed. `NotificationGateway` subscribes to these events and attempts delivery asynchronously; any failure is logged and retried internally, and is never surfaced back to the use case or the end user as a transaction failure.

## Rationale

The ordering is the entire point: emitting the event after commit, not before or as part of the same transaction, is what structurally guarantees a notification failure cannot roll back state that has already been durably recorded. A broker is not justified — there is exactly one consumer (`NotificationGateway`) and no distributed producers/consumers to coordinate.

## Positive Consequences

- The reliability requirement (notification failure never blocks the write path) is satisfied by construction, not by convention — the event literally does not exist until after the write has succeeded.
- No additional infrastructure to operate, monitor, or pay for.
- The event types form a natural, compiler-checked (sealed-class) catalog of "things that happen" in the domain, useful for future consumers beyond notifications (e.g. analytics) without touching use-case code.

## Negative Consequences and Trade-offs

- Retry/backoff logic for failed notification delivery must be hand-built rather than inherited from broker infrastructure; the exact backoff policy is not yet finalized.
- If the application process terminates between commit and successful notification delivery, an in-flight notification may be lost — there is no durable outbox table in the current design. This is a known, stated limitation, not a hidden one.
- This mechanism only works because everything runs in one process; it does not generalize if a real backend is introduced (see ADR-004/ADR-006) without further design work.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A notification can be lost if the process dies before delivery (no durable outbox) | Stated explicitly as an open implementation detail in the Solution Design; an outbox table is a candidate future addition, not yet designed |
| The requirements baseline describes a durable, database-backed Transactional Outbox pattern (an `outbox_events` table with status tracking and exponential backoff) — a stronger durability guarantee than this ADR's in-memory event bus provides | This is part of the broader backend/architecture reconciliation tracked in ADR-006, not silently adopted here |

## Requirement Traceability

| Requirement | How this decision addresses it |
|---|---|
| Partial-failure recovery (notification failure isolation — high-priority, non-functional requirement) | Event emission strictly after commit; failures absorbed entirely within `NotificationGateway` |
| Lifecycle notifications functional requirement | Domain events map 1:1 to the notification triggers the requirement specifies |

## Assumptions and Open Risks

This ADR assumes in-memory delivery loss on process termination is an acceptable risk for the current deliverable scope. If the requirements baseline's durable-outbox model (ADR-006) is adopted, this ADR would need to be superseded, not silently reinterpreted.

## Related ADRs and Design Sections

- Solution Design (HLD) §4.10 (Interface and Communication Architecture), §4.14 (Reliability).
- Low-Level Design (LLD) §5.2.6 (Notification Management), Figure 3 (Error Recovery Sequence).
- ADR-001 (architecture style — this is the one sanctioned use of event-driven communication, narrowly scoped).
- ADR-004 (no-backend deployment boundary — why a broker was not considered viable).
- ADR-006 (the requirements baseline's durable outbox pattern is a stronger guarantee than this ADR provides — unresolved).
