# ADR-002: Campaign Versioning, Approval-Version Binding, and Optimistic Concurrency

## Status

Accepted

## Decision Date

2026-11-01

## Context and Problem

A campaign proposal is edited, submitted, reviewed, possibly revised, and eventually scheduled. Three failure modes must be architecturally prevented, not merely discouraged:

1. **Post-approval drift** — a reviewer approves one version of a campaign, but a different, later-modified version is the one that gets scheduled.
2. **Stale approval** — a reviewer acts on a version of the campaign that is no longer current, without realizing it has changed underneath them.
3. **Lost updates** — two concurrent writers (two sessions, or a marketer and an in-flight review decision) overwrite each other's changes silently.

A decision was required on how campaign state is versioned, how an approval decision is bound to the exact content it evaluated, and how concurrent writes are detected and resolved.

## Decision Drivers

- Approval decisions must be defensible — "which exact version was approved" must be an unambiguous, machine-checked fact, not a convention.
- The confirmed non-functional requirements set (durability, concurrent-edit safety, version-approval binding) are explicit and critical-priority.
- Team size and timeline rule out heavyweight distributed-transaction machinery.
- The approval model assumed at the time this decision was made is single-reviewer (see ADR-006 for the later, unresolved multi-stage requirement).

## Considered Alternatives

### Versioning

| Alternative | Description |
|---|---|
| In-place mutation | A campaign's current fields are edited directly; no separate version record exists. |
| Event-sourcing delta diffs | Each edit is stored as a diff; current state is reconstructed by replaying diffs. |
| Immutable full-snapshot versions (selected) | Each submission or revision creates a complete, immutable snapshot of campaign content; the aggregate's "current version" is a pointer, not the editable record itself. |

### Concurrency Control

| Alternative | Description |
|---|---|
| Pessimistic locking | A reviewer or marketer acquires an exclusive lock on the campaign row while evaluating or editing it. |
| Two-phase commit / distributed transaction coordination | A distributed transaction protocol coordinates writers across nodes. |
| Optimistic concurrency via a version token (selected) | Every write includes the version the writer believes is current; the write is rejected if the stored version has advanced. |

## Evaluation and Comparison

| Criterion | In-place mutation | Event-sourcing diffs | Immutable snapshots (selected) |
|---|---|---|---|
| Prevents post-approval drift | No — nothing stops the "current" record from changing after approval | Yes, in principle | Yes — an approval is bound to a specific, permanently fixed snapshot |
| Implementation complexity | Low | High (replay/projection logic, snapshot reconstruction) | Low–Medium |
| Storage cost | Lowest | Medium | Higher (full copies), accepted — payloads are small |
| Auditability | Weak — history is not naturally preserved | Strong | Strong — every version is a permanent, queryable record |

| Criterion | Pessimistic locking | Distributed 2PC | Optimistic concurrency (selected) |
|---|---|---|---|
| Fit for a single-device, low-write-contention mobile app | Poor — holding a lock across a reviewer's "thinking time" is impractical | Not applicable — no distributed nodes exist to coordinate | Good |
| Operational complexity | Medium (lock timeout/deadlock handling) | High | Low |
| User experience on conflict | Blocked until lock released | N/A | Immediate, explicit conflict signal; caller reloads and retries |

## Selected Decision

**Immutable full-snapshot versioning** — a `CampaignVersion` is created only at two trigger points (submission, revision-resubmission), never on every edit. **Optimistic concurrency** via a `currentVersion` integer token compared at every write (`CampaignRepository.save(campaign, expectedVersion)`), and a **separate, second check** inside the domain aggregate (`approve`/`reject`/`requestChanges`) that compares the reviewer's believed-current version against the aggregate's actual current version before any `ApprovalRecord` is created — distinct from the repository-level write check, because the two answer different questions ("is this review stale" vs. "did someone else write first") and warrant different user-facing messages.

## Rationale

Immutable snapshots make "which version was approved" a structural fact rather than a convention that can be silently violated. Optimistic concurrency fits the access pattern (infrequent conflicts, a single device, reviewers taking minutes-to-hours to decide) far better than pessimistic locking, which would have to hold a lock across exactly the kind of long "thinking time" this workflow involves.

## Positive Consequences

- An `ApprovalRecord.versionReviewed` field, once written, can never retroactively apply to a different version — enforced by always deriving it from the aggregate's own current version, never from caller-supplied input.
- Concurrent-write conflicts fail loudly and immediately (a typed `ConcurrentModificationError` or `StaleReviewError`), never silently.
- No lock-timeout tuning, deadlock detection, or distributed coordinator is required.

## Negative Consequences and Trade-offs

- A true race — two conflicting writes arriving within the same instant, before either has completed — is not fully closed by this mechanism alone; it only guarantees the *second* write to complete detects the conflict. A formal idempotency-key scheme for retried network requests is a related but distinct concern, not yet designed (see Risks below).
- Rejected writes require the caller to reload and resubmit — there is no automatic merge. This is a deliberate choice (silent merging of campaign fields is not safe), but it is a real UX cost under contention.
- Storing full snapshots rather than diffs costs more storage per version; accepted because campaign payloads are small and the simplicity/auditability gain outweighs it.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| No idempotency-key scheme exists yet for retried network/client requests (distinct from the version-conflict mechanism above) | Flagged explicitly as an open item in the Solution Design; not claimed as solved |
| The requirements baseline now describes a 3-stage sequential approval pipeline with per-stage approval records bound to a cryptographic snapshot hash (SHA-256) — a materially different binding model than the single `ApprovalRecord` this ADR describes | See ADR-006 — this is an unresolved reconciliation, not silently absorbed into this ADR |

## Requirement Traceability

| Requirement | How this decision addresses it |
|---|---|
| Approval state consistency, version-approval binding (critical-priority, non-functional requirements) | Immutable snapshots + version-token binding on `ApprovalRecord` |
| Concurrent-edit safety (high-priority, non-functional requirements) | Optimistic concurrency at the repository boundary |
| Campaign versioning and revision functional requirements | Two version-creation trigger points, never on plain edits |
| Material-change re-approval functional requirement | Any edit to an Approved campaign routes through an explicit invalidation step before the edit is applied, producing its own audit entry |

## Assumptions and Open Risks

This ADR assumes a single `ApprovalRecord` per version (single-reviewer model). The requirements baseline's multi-stage pipeline would require this data model to extend to per-stage approval records bound to the same snapshot — an extension, not a contradiction, of the immutable-snapshot principle, but not yet designed. See ADR-006.

## Related ADRs and Design Sections

- Solution Design (HLD) §4.11 (Data Architecture), §4.14 (Reliability).
- Low-Level Design (LLD) §5.2.3–§5.2.4, §6.1–§6.4.
- ADR-001 (architecture style — domain layer owns these invariants).
- ADR-005 (persistence strategy — where the atomic state+audit commit is implemented).
- ADR-006 (multi-stage approval reconciliation — the open question of whether this single-`ApprovalRecord` model extends or is superseded).
