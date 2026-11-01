# Architecture Defence — Presentation Speaking Notes

> **Purpose:** A natural, spoken-ready guide for presenting this architecture to MAL4 judges. Each section is a talking point, not a script to read verbatim — expand on what's relevant to the questions actually asked.

---

## 1. Problem and Architectural Goals (30–45 seconds)

"Campaign approval in most organizations happens over email and chat — teams lose track of what's actually been approved, sometimes approve one version of a campaign and release a different one, and have no reliable record of who signed off on what. We built a mobile app that makes that governance structural: an approval applies to exactly one version of a campaign, concurrent edits can't silently corrupt state, and every lifecycle action is permanently recorded."

## 2. System Architecture (45–60 seconds)

"It's a Flutter mobile app, deliberately built as a modular monolith, not microservices — one deployable, internally organized into a domain layer that owns every business rule, an application layer that orchestrates use cases, an infrastructure layer for persistence and external adapters, and a presentation layer that only ever issues commands, never touches business logic directly. The domain layer has zero outward dependencies — it doesn't know Flutter or a database exist — which is what makes the lifecycle rules testable in isolation."

## 3. Major Modules (30 seconds)

"Seven modules: authentication and authorization, campaign management, campaign version management, a merged review-and-approval workflow, audit management, notification management, and scheduling. They're organized by business capability, not technical layer, so each one's responsibility is self-contained."

## 4. Critical Design Decisions (60–90 seconds — pick 2–3 depending on time)

Choose from, depending on what the room seems most interested in:

- **Version binding:** "An approval is permanently bound to the exact version it reviewed. If a reviewer is looking at a stale version — say, the campaign was withdrawn and resubmitted while they were deciding — the system detects that and rejects the stale decision, rather than silently applying it to the wrong content."
- **Concurrency:** "We use optimistic concurrency, not locks — because a reviewer might hold a campaign open for an hour of evaluation, and locking for that long would make the app unusable for everyone else. The first writer to finish wins; the second gets an explicit conflict, not a silent overwrite."
- **Audit integrity:** "Every state change and its audit entry commit in one local transaction. There's no code path where one exists without the other."

## 5. Important Workflows (30 seconds)

"The core loop is: create, submit, review, and — if approved — schedule. If a reviewer requests changes, the marketer revises and resubmits as a new version, which resets to the top of the review flow. If an already-approved campaign is edited, that's treated as a material change: the approval is automatically invalidated and the campaign goes back to draft before the edit is applied."

## 6. Security and Data Consistency (45 seconds — be direct here, don't rush past it)

"Role checks and self-review prevention are enforced in application and domain code, never just the UI — so even a request that bypasses the interface entirely still has to pass those checks. What we do not have is a backend, so this enforcement happens on-device. That's a real, named limitation: a modified client could in principle bypass it. We made that trade-off deliberately, given a two-person team and the project timeline, and we're not going to pretend otherwise if asked."

## 7. Trade-offs (30–45 seconds)

"Every major decision in this project has a written ADR with the alternatives we rejected and why. The short version: we avoided distributed infrastructure everywhere it wasn't justified by actual scale, chose structural guarantees (immutable versions, optimistic concurrency, atomic audit commits) over conventions that rely on discipline, and we were explicit anywhere the trade-off cost something — no backend, no multi-device support, no durable notification outbox yet."

## 8. Limitations — Say This Part Plainly, Don't Soften It

"I want to be upfront about the biggest one: while preparing this architecture documentation, we found that our requirements documentation evolved, after the architecture was built, to describe a three-stage approval pipeline with a real backend — and our implemented design doesn't match that yet. We've documented that gap explicitly rather than quietly picking a side, because that's a decision the team needs to make consciously, not one that should get buried in inconsistent documentation. [If asked which way you're leaning, answer honestly based on the team's actual plan — don't guess here.]"

## 9. Future Improvements (20–30 seconds)

"The architecture was built with this evolution in mind even though it isn't built yet — the repository and adapter interfaces are already the seam a real backend would slot in behind, without rewriting the domain. The same is true for multi-stage approval: the review-and-approval module is already isolated from the rest of the system specifically so it could absorb that complexity without touching everything else."

## Delivery Notes

- When asked a question you don't have a confident, grounded answer for, say so and point to the open item rather than improvising a guess — every "not yet designed" and "open item" in this package is there for exactly this reason.
- The divergence between requirements and architecture (ADR-006) will very likely come up, directly or indirectly. Don't wait for it to be discovered — if there's a natural moment in the overview to mention it proactively, taking that initiative reads better than being caught by it.
- Keep the tone matter-of-fact about limitations. They are findings from a working review process, not confessions.
