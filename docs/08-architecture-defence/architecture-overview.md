# Architecture Overview

> **Purpose:** The core explanation of the system — what it does, how it's built, and why — written to be read in full or delivered as a 2–3 minute spoken introduction before deeper questioning begins.

---

## The Problem

Marketing campaign proposals move between marketers, reviewers, and approvers before they can be scheduled. When this happens over disconnected tools and chat threads, teams lose visibility into a campaign's real status, approve one version of a proposal and then schedule a different, later-edited one, miss required revisions, or have no reliable record of who approved what and when. Concurrent edits and uncontrolled post-approval changes make brand, regulatory, and budget governance unenforceable.

## System Boundary

The system is a Flutter/Dart mobile application covering exactly the campaign review-and-approval capability: creating and editing a campaign, submitting it for review, a Reviewer's decision (approve, reject, request changes), revision and resubmission, version management tied to approvals, a scheduling gate, an audit trail, and role-based access control. Content creation tooling, actual campaign delivery, audience segmentation, analytics, and external platform integrations are explicitly out of scope — acknowledged as named boundary actors, not built.

## Major Architectural Components

- **Domain layer** — the `Campaign` aggregate, which owns the lifecycle state machine and every invariant (valid transitions, approval bound to the exact version reviewed, self-review prevention). This layer has zero outward dependencies: no Flutter, no database, no network.
- **Application layer** — one use case per operation (`SubmitCampaign`, `ReviewCampaign`, `ScheduleCampaign`, and so on), each responsible for authorizing the actor, checking for conflicting concurrent writes, delegating the actual decision to the domain, persisting the result, and emitting a domain event on success.
- **Infrastructure layer** — repository implementations (local Drift/SQLite persistence) and adapters (`AuthProvider`, `NotificationGateway`) that implement interfaces the domain and application layers own, never the other way around.
- **Presentation layer** — Flutter screens and state notifiers, which only ever issue commands to the application layer; they never touch the domain or persistence directly.

## How Components Interact

A user action becomes a command dispatched from Presentation to a single Application-layer use case. That use case authorizes the actor, loads the current `Campaign` aggregate fresh from the repository, delegates the actual business decision to the aggregate (which enforces every invariant), persists the result with an optimistic-concurrency check, and — only after that write commits — emits a domain event that a notification adapter consumes asynchronously and best-effort. Nothing downstream of the commit can affect whether the commit succeeded.

## Why This Architecture Fits the Problem

The problem is fundamentally about **state integrity under review**: an approval must mean something specific and verifiable, versions must not silently drift, and concurrent actors must not corrupt each other's work. A modular monolith with a dependency-inverted domain directly serves that: the rules that make an approval trustworthy live in one place, are enforced regardless of what the UI does, and are testable without any infrastructure. This is deliberately **not** a distributed or microservice architecture — nothing about this problem, at this scale (a single mobile app, tens to low hundreds of campaigns, a handful of users), benefits from that complexity, and a two-person team cannot responsibly operate it within a hackathon timeline.

## How the Architecture Satisfies Important Requirements

| Requirement | Architectural response |
|---|---|
| An approval must apply to one exact version, never a later edit | Immutable version snapshots; approval record bound to the version it was reviewed against (ADR-002) |
| Concurrent edits must not silently overwrite each other | Optimistic concurrency with an explicit, typed conflict error (ADR-002) |
| A notification outage must never block an approval | In-process domain events emitted strictly after commit (ADR-003) |
| Lifecycle rules must be testable and auditable | Domain layer isolated with zero outward dependencies (ADR-001) |
| Role checks must not depend on the UI alone | Enforced in Application and Domain layers (ADR-004) |

## What This Document Does Not Claim

This architecture has a significant, honestly-documented limitation: it has no backend, and therefore cannot literally satisfy a server-side-enforcement reading of the authorization requirements (ADR-004). It also diverges from a later expansion of the project's requirements baseline calling for a three-stage sequential approval pipeline and a server-backed data model — a conflict tracked explicitly in `docs/03-architecture-decisions/ADR-006-multistage-approval-backend-reconciliation.md` and not yet resolved. Both points are addressed directly, not glossed over, in `risks-and-limitations.md` and `anticipated-questions.md`.
