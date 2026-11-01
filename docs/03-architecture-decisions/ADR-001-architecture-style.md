# ADR-001: Overall Architecture Style — Modular Monolith, Feature-First, Clean-Architecture-Lite

## Status

Accepted

## Decision Date

2026-11-01

## Context and Problem

The MAL4 Campaign Review & Approval mobile application needs an internal architecture that (a) keeps campaign lifecycle and approval invariants testable without a UI or database, (b) stays proportionate to a two-person team and a hackathon timeline, and (c) does not foreclose future evolution (a real backend, multi-stage approval — see ADR-006) by hard-coding assumptions throughout the codebase.

Six candidate concepts were on the table — Layered Architecture, Clean Architecture, Feature-First organization, MVVM, the Repository pattern, and Event-Driven Architecture. Treating these as five or six competing "pick one" options would be a category error: each answers a different architectural question (deployment topology, code organization, internal dependency direction, presentation pattern, and inter-component communication, respectively). The real decision is which combination to adopt, and at what level of rigor.

## Decision Drivers

- Lifecycle and approval rules (campaign state transitions, version binding, self-review prevention) must be unit-testable in isolation — Testing & Observability is an explicitly weighted MAL4 evaluation criterion.
- Team size is two; any architecture with ceremony that doesn't pay for itself in testability or safety is a direct cost to delivery.
- No distributed infrastructure is justified at the confirmed scale (single mobile app, local-first).
- Persistence technology is not yet finalized (ADR-005) and the backend question is unresolved (ADR-006) — the internal architecture must not assume either answer.
- The solution must remain coherent if a feature boundary (e.g. multi-stage approval) is added later without a rewrite.

## Considered Alternatives

| Alternative | Description |
|---|---|
| Classic Layered Architecture (global UI / business-logic / data-access layers) | Partition the whole codebase by technical layer type, shared across all features. |
| Full Clean Architecture | Strict four-ring architecture (entities, use cases, interface adapters, frameworks) with DTOs and mappers at every boundary. |
| Feature-First + Clean-Architecture-lite (selected) | One feature module (`campaign`), internally layered (domain/application/infrastructure/presentation) by dependency direction only, without full Clean Architecture's ring ceremony. |
| Full Event-Driven Architecture | All inter-component communication via published events on a broker or event bus. |

## Evaluation and Comparison

Scored against this project's actual constraints (two-person team, hackathon timeline, Flutter/Dart, 5–50 users / 10–200 active campaigns per the confirmed non-functional requirements):

| Criterion | Classic Layered | Full Clean Architecture | Feature-First + Clean-lite (selected) | Full Event-Driven |
|---|---|---|---|---|
| Separation of concerns | Medium — by technical type, not business capability | High | High | High for decoupling, orthogonal to the others |
| Complexity | Low | High | Low–Medium | High if applied broadly |
| Testability | Medium — global layers tangle unrelated features | High | High | Medium — async flows are harder to test |
| Maintainability as the app grows | Low — unrelated features share layers | High, at a ceremony cost | High | Low if overused — hides control flow |
| Development speed for a 2-person team | High | Low | High | Low if applied broadly |
| Suitability for Flutter | Medium | Medium — common but often overbuilt | High — standard modern Flutter practice | Low for a single mobile app |

## Selected Decision

**Modular Monolith** (single deployable, no services) + **Feature-First** code organization (one `campaign` feature) + **Clean-Architecture-lite** internal layering (domain → application ← infrastructure, presentation depends on application only — dependency rule enforced, full ring/DTO ceremony not adopted) + **MVVM** in the presentation layer (state notifiers as the view-model) + **Repository pattern** as the persistence dependency-inversion seam + **narrow, in-process domain events** for decoupling side effects only.

## Rationale

Full Clean Architecture's ceremony (strict rings, mapper classes at every boundary) is disproportionate to one feature and two developers — the *principle* that is actually valuable (dependency inversion, a domain with zero outward dependencies) is retained without the ceremony that doesn't pay for itself at this scale. Feature-First avoids coupling the campaign feature to any future feature through shared global layers. MVVM is the natural shape for a Riverpod/Bloc-style notifier regardless of this choice, and operates one level below it. Narrow in-process events are justified by a specific, named requirement (notification failures must never block or roll back a committed state transition) rather than adopted as a general pattern.

## Positive Consequences

- The domain (`Campaign` aggregate and its invariants) has zero outward dependencies and is testable without Flutter, a database, or a network connection.
- Persistence technology remains swappable without touching domain or application code (dependency inversion via repository interfaces).
- The module boundary (`Review & Approval Workflow`) that would need to absorb multi-stage approval, if that becomes the adopted scope (see ADR-006), is already isolated from Campaign Management, Audit, and Notification modules.

## Negative Consequences and Trade-offs

- Some boilerplate (use-case classes, repository interfaces, typed `Result` returns) versus directly calling a database from a widget — accepted because it is what buys the testability property above.
- "Clean-lite" risks boundary ambiguity without a strict reference implementation to point to; mitigated by writing explicit layer responsibility tables in the Solution Design rather than relying on convention alone.
- A Feature-First, single-feature codebase does not by itself prove the module boundaries are right for a second feature that doesn't exist yet — this is accepted as a reasonable bet given the project has exactly one feature in scope.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Two developers interpret "Clean-lite" differently and the dependency rule erodes over time | Dependency-direction rules are stated explicitly per layer in the Solution Design, with a target lint rule to enforce `domain/` importing nothing from Flutter or the persistence library (not yet configured — no code exists yet) |
| The architecture is scoped to a single-approval, local-first assumption that the current requirements baseline no longer matches (see ADR-006) | This ADR records the style decision independent of that question — Feature-First + Clean-lite does not itself prevent the module from being extended to a multi-stage pipeline or a real backend; the reconciliation is tracked separately in ADR-006, not silently folded in here |

## Requirement Traceability

| Requirement | How this decision addresses it |
|---|---|
| Testing & Observability (MAL4 evaluation criterion) | Domain layer isolation is what makes lifecycle/approval logic unit-testable without a UI or database |
| NFR-015 (workload scalability, single-instance sufficient) | Modular Monolith matches the confirmed scale; no distributed infrastructure is introduced |
| Team-size constraint (2 engineers) | Feature-First + Clean-lite, not full Clean Architecture, keeps delivery cost proportionate |

## Assumptions and Open Risks

This decision assumes the project remains a single-feature mobile application for its hackathon deliverable scope. It does not resolve whether the requirements baseline's 3-stage approval pipeline and server-side enforcement model (ADR-006) will be adopted — that is a separate, currently unresolved decision.

## Related ADRs and Design Sections

- Solution Design (HLD): `docs/02-solution-design/HLD/MAL4-HLD.md` §4.6 (Architecture Style and Rationale), §4.8 (Logical Architecture).
- Low-Level Design (LLD): `docs/02-solution-design/LLD/MAL4-LLD.md` §5.2 (module packaging).
- ADR-002 (data consistency), ADR-003 (event processing), ADR-004 (authorization boundary), ADR-005 (persistence) all operate inside the layering this ADR establishes.
- ADR-006 (multi-stage approval & server-side enforcement reconciliation) — unresolved; this ADR's decision is scoped to the current Solution Design, not the expanded requirements baseline.
