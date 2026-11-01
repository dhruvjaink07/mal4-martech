# Critical Design Decisions — Defence Material

> **Purpose:** Deep, project-specific defence for the design decisions most likely to be probed in detail — the problem each one solves, how it's solved, what happens when it fails, and what the trade-off was.

---

## 1. Campaign Lifecycle and State Transitions

**Problem:** Without an enforced lifecycle, a campaign's status becomes whatever the last person who touched it says it is — no reliable single source of truth.

**Design:** Exactly six states (`Draft`, `Pending Review`, `Changes Requested`, `Approved`, `Rejected`, `Scheduled`), with every transition expressed as a guarded method on the `Campaign` aggregate. A transition not in the explicit allow-list throws `InvalidTransitionError` before any persistence call — it never silently no-ops and never reaches the database in an invalid attempt.

**Failure case:** A caller (UI bug, or a deliberately crafted request) attempts an illegal transition, e.g. approving a Draft campaign. The guard inside the aggregate rejects it, independent of whatever the UI did or didn't allow.

**Trade-off:** The state machine is intentionally minimal — six states, no sub-states — matching the single-approval model actually implemented. A richer state model (the requirements baseline's per-stage sub-states within Pending Review) is not implemented; see ADR-006.

---

## 2. Immutable Campaign Versions

**Problem:** If "the current campaign" is one mutable record, nothing stops it from being approved at one point in time and scheduled in a different state later.

**Design:** A `CampaignVersion` is created at exactly two points — submission and revision-resubmission — and is never mutated after creation. There is no `updateVersion()` method anywhere in the domain or repository interfaces; this is a structural guarantee (the capability doesn't exist), not a runtime check that could be forgotten.

**Failure case:** A marketer edits a Draft before first submission — this mutates an unversioned working copy, never an existing version. Once submitted, any further edit either is rejected outright (Pending Review state) or triggers an explicit, audited invalidation step (Approved state) before a new version is created.

**Trade-off:** Full snapshots, not diffs — simpler and more auditable, at the cost of more storage per version. Accepted because campaign payloads are small.

---

## 3. Approval Validity and Stale Approvals

**Problem:** A reviewer can load a campaign, take time to evaluate it, and submit a decision after the campaign has already changed underneath them — without realizing it.

**Design:** Every review-decision use case loads the campaign fresh from the repository at execution time — never from a client-held cache, however recently fetched — and compares the version the reviewer believes they are acting on against the aggregate's actual current version. A mismatch raises a distinct `StaleReviewError` before any `ApprovalRecord` is created.

**Concrete scenario:** A marketer submits version 1. A reviewer opens it. The marketer withdraws the submission (permitted — no decision exists yet), edits, and resubmits as version 2. The reviewer, unaware, attempts to approve "version 1." The system detects `1 != 2` and rejects with `StaleReviewError`, surfaced to the reviewer as "this campaign has changed since you opened it."

**Failure case:** Without this check, the reviewer's stale decision would either silently apply to the wrong content or be accepted against content the reviewer never actually saw. Both are unacceptable for an approval system.

**Trade-off:** The reviewer must explicitly reload and re-evaluate — no automatic re-application of a stale decision is attempted, because that would be guessing at intent.

---

## 4. Optimistic Concurrency

**Problem:** Two writers (two sessions, or a marketer editing while a review decision is in flight) can overwrite each other's work if nothing detects the conflict.

**Design:** Every mutating repository call requires the `expectedVersion` the caller loaded. The write is rejected, atomically, if the stored version has already advanced. See `critical-design-decisions.md` §3 above for the related but distinct stale-review check.

**Failure case:** Actor A loads version 1, submits, and succeeds — stored version becomes 2. Actor B, who also loaded version 1, attempts to save with `expectedVersion: 1` — the write fails with `ConcurrentModificationError`, since the stored version no longer matches. No merge is attempted.

**Trade-off:** No automatic conflict resolution — correctness over convenience. The user experience cost (reload and retry) is accepted because silent merging of campaign fields is not safe to do automatically.

---

## 5. Audit Integrity

**Problem:** Without a trustworthy audit trail, there is no way to answer "who approved what, when, and under which version" after the fact — the central requirement of a governance system.

**Design:** Every lifecycle action produces an `AuditEntry`, written in the **same local transaction** as the state change it records. `AuditLogRepository` exposes `append()` and `queryBy()` only — no update or delete method exists anywhere in the interface, by construction, not by policy.

**Failure case:** If the local database write fails partway through, the entire transaction (state change and audit entry together) rolls back — there is no scenario where a state change is recorded without its audit entry, or vice versa.

**Trade-off:** This guarantees audit entries can never be lost or desynchronized from the state they describe, at the cost of coupling every write to a (small, local) transaction — an acceptable cost given the transaction never crosses a network boundary.

---

## 6. Role-Based Authorization

**Problem:** Marketers must not be able to approve their own campaigns; Reviewers' actions must be gated by role.

**Design:** Every state-transitioning use case checks the actor's role and, for review decisions, explicitly checks that the reviewer is not the original submitter — checked in the Application layer before any domain mutation, and defensively a second time inside the `Campaign` aggregate itself (defense in depth, since the two checks answer slightly different questions).

**Failure case:** A user holding both roles submits a campaign, then attempts to approve it. The self-review check rejects the action with `SelfReviewError`, regardless of what the UI would have allowed.

**Trade-off — stated honestly, not hidden:** this enforcement happens on-device, in the same process as the UI it protects. See §9 (Persistence and Data Consistency) and `risks-and-limitations.md` for the full statement of what this does and does not guarantee.

---

## 7. Scheduling Restrictions

**Problem:** A campaign could be approved, then modified, then scheduled — releasing content nobody actually approved.

**Design:** `ScheduleCampaign` does not trust that "Approved" alone is sufficient — it re-verifies, at the moment of scheduling, that the approved version is still the campaign's current version. This is a deliberate re-check, not an assumption carried over from the time of approval, closing a time-of-check/time-of-use gap.

**Failure case:** If a material change to an Approved campaign were somehow not caught by the invalidation path, the scheduling re-check would still catch it — defense in depth, the same principle as the self-review check.

**Trade-off:** None significant — this is a pure safety check with negligible cost.

---

## 8. Persistence and Data Consistency

**Problem:** State and its audit record must never diverge, even across app restarts or crashes.

**Design:** Local-first Drift/SQLite, with the campaign-state write and its audit entry committed in one transaction (see §5). SQLite's write-ahead-log mode guarantees a committed transaction survives a crash and an uncommitted one leaves no trace — no explicit application-level recovery logic is required beyond reading the persisted state as-is.

**Limitation stated honestly:** This guarantees consistency only within a single local database on a single device. There is no cross-device consistency story — two installations of the app have no way to see each other's data. See `risks-and-limitations.md`.

---

## 9. Notification Failures

**Problem:** An external notification service outage must not be allowed to compromise a legitimate, already-decided business transaction.

**Design:** Domain events are emitted strictly after the triggering transaction commits (ADR-003). `NotificationGateway` absorbs every failure internally — logs it, schedules a retry — and never propagates a failure back to the use case or the user. The use case's success response is already determined before the notification is even attempted.

**Failure case:** The external service is unreachable. The approval still succeeds; the campaign's new state is visible immediately; the notification is retried in the background, best-effort.

**Trade-off:** No durable outbox table exists yet — an in-flight notification can be lost if the app process terminates before delivery completes. Stated as an open item, not claimed as solved.

---

## 10. Offline and Multi-Device Limitations

**Problem/Scope:** The architecture is local-first by construction, which makes offline operation the baseline mode rather than a special case — but this comes with a cost that must be named precisely.

**Design:** No network dependency exists in the core workflow. There is, correspondingly, **no multi-device capability** — this is not an edge case the architecture handles imperfectly, it is a capability that does not exist in the current design, by direct consequence of having no backend (ADR-004, ADR-005).

**When this would need to change:** Any requirement for two people on two devices to see the same campaign's live state requires introducing a backend and a sync/conflict-resolution strategy that does not currently exist — tracked as part of the broader reconciliation in ADR-006.
