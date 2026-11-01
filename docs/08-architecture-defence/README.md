# Architecture Defence Package — Index

> **Owner:** Architecture & Engineering Lead
> **Last Updated:** 2026-11-01
> **Purpose:** Preparation material for defending the MAL4 Campaign Review & Approval architecture before judges and technical reviewers — grounded in the actual Solution Design (`docs/02-solution-design/`) and Architecture Decision Records (`docs/03-architecture-decisions/`), not a repetition of either.

## Contents

| File | Covers |
|---|---|
| [`architecture-overview.md`](architecture-overview.md) | The system explained from scratch — problem, boundary, components, interactions, fit. A 2–3 minute presentation in document form. |
| [`adr-defence.md`](adr-defence.md) | Each ADR's decision, rejected alternatives, trade-offs, and limitations, condensed for live defence. |
| [`critical-design-decisions.md`](critical-design-decisions.md) | Deep defence material for the ten most scrutinized design topics — lifecycle, versioning, stale approvals, concurrency, audit, authorization, scheduling, persistence, notifications, offline/multi-device. |
| [`trade-offs.md`](trade-offs.md) | Structured comparison of the major architectural alternatives actually considered, plus broader comparisons (microservices, layering style, state management). |
| [`risks-and-limitations.md`](risks-and-limitations.md) | The complete, honest accounting of what this architecture does not guarantee — led by the most significant open item in the project. |
| [`anticipated-questions.md`](anticipated-questions.md) | A 12-category judge question bank with direct answers, technical detail, and references. |
| [`failure-scenarios.md`](failure-scenarios.md) | The spoken, narrative version of the project's failure-mode handling, for live Q&A. |
| [`presentation-notes.md`](presentation-notes.md) | A section-by-section speaking guide for the live presentation. |
| [`master-presentation-guide.md`](master-presentation-guide.md) | The master 10-minute presentation & defense script covering the One-Pager, HLD, LLD, ADRs, 2-speaker hand-offs, and top 6 jury trap responses. |

## The One Thing to Read First

Before anything else in this package, read `risks-and-limitations.md` §0 and `docs/03-architecture-decisions/ADR-006-multistage-approval-backend-reconciliation.md`. The requirements documentation (owned by the Domain Research & Requirements Lead) was expanded, after the Solution Design was built, to specify a three-stage sequential approval pipeline with server-side enforcement — a materially different architecture from what was actually implemented. This was discovered while preparing this documentation and has not been resolved. Every other document in this package is written with that context in view, and several of them reference it directly rather than presenting a falsely unified picture.

## Scope and Ownership Note

This folder, and `docs/03-architecture-decisions/`, are owned and maintained by the Architecture & Engineering Lead. `docs/01-problem-understanding/`, `docs/04-workflows/`, and `docs/06-data-design/` — referenced throughout this package, especially in the context of ADR-006 — are owned by the Domain Research & Requirements Lead and have not been modified in the preparation of this defence package.
