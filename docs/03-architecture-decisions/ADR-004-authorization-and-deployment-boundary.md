# ADR-004: Authorization Enforcement Boundary and No-Backend Deployment Model

## Status

Accepted (for the current Solution Design) — **see ADR-006 for an unresolved conflict with the requirements baseline**

## Decision Date

2026-11-01

## Context and Problem

Role-based access control (only a Marketer may create/edit/submit; only a Reviewer, and never the submitter, may approve/reject/request changes) must be enforced somewhere that cannot be bypassed by a modified or malicious client. The confirmed non-functional requirements state this in explicit client-server terms: authentication must reject unauthenticated requests, and "authorisation must be enforced server-side, not only in the client." No backend process exists or is planned for the current Solution Design. A decision was required on where enforcement actually happens, and how to be honest about what that does and does not guarantee.

## Decision Drivers

- The requirement is phrased in literal server-side terms; the architecture has no server.
- A 2-person team and hackathon timeline make standing up and operating a real backend a significant, separate undertaking.
- No prior decision in this project (ADR-001 or otherwise) establishes that a backend exists — it must not be silently assumed.
- Judges and reviewers will reasonably ask how authorization can be trusted without a server.

## Considered Alternatives

| Alternative | Description |
|---|---|
| Build a minimal real backend for the hackathon deliverable | Stand up an actual server process (even a thin one) that performs authentication/authorization independently of the mobile client. |
| On-device enforcement, presented as equivalent to server-side | Enforce checks in application/domain code on-device, without acknowledging the gap against the literal requirement. |
| On-device enforcement, gap stated explicitly (selected) | Enforce checks in application/domain code on-device; explicitly document that this does not satisfy a literal production security reading of "server-side," as an accepted, stated limitation. |

## Evaluation and Comparison

| Criterion | Real backend | On-device, gap hidden | On-device, gap stated (selected) |
|---|---|---|---|
| Literally satisfies NFR-008/009 | Yes | No (same as the left column — the gap doesn't disappear by not mentioning it) | No, and says so |
| Proportionate to a 2-person hackathon team | No — materially increases scope (hosting, auth infrastructure, API design, deployment) | Same engineering cost as the selected option | Same engineering cost — the only difference is honesty |
| Defensible under judge cross-examination | Strong, if actually built | Weak — an unstated gap discovered by a reviewer reads as an oversight | Stronger than "hidden" — demonstrates the team understands the boundary and made a conscious, reasoned trade-off |
| Prevents a modified client from bypassing checks that *are* enforced (self-review, role, version) | N/A (not selected) | Only as strong as the on-device checks, regardless of framing | Same technical strength; difference is only in disclosure |

## Selected Decision

Authorization and self-review checks are enforced in the **Application and Domain layers**, on-device, in the same process as the UI — never relying on the UI merely hiding a button. This is explicitly documented as satisfying the *intent* of the requirement (checks cannot be bypassed by skipping client-side validation alone) but **not** a literal production security reading of "server-side enforcement," because there is no separate process boundary between "client" and "server" for a modified client binary to be unable to cross.

## Rationale

Given no backend exists in this deliverable, the only real choice is whether to state the resulting gap plainly or not — the technical strength of the enforcement is identical either way. Stating it plainly is the only choice consistent with this project's standard of not claiming guarantees that don't hold, and it is also the more defensible position in an architecture review: it demonstrates the team identified the exact boundary of what their design can and cannot guarantee, rather than having it discovered by a reviewer.

## Positive Consequences

- Self-review prevention, role checks, and version-binding checks are enforced in domain code that a UI cannot be coerced into skipping — a materially stronger guarantee than UI-only validation, even without a server.
- The gap against the literal requirement is recorded once, precisely, and consistently, rather than being implicitly re-discovered (and possibly mischaracterized) in multiple places.
- The `AuthProvider` interface already exists as a seam; introducing a real Identity Provider behind it later does not require rewriting use cases.

## Negative Consequences and Trade-offs

- A sufficiently motivated attacker with a modified client binary could, in principle, bypass on-device checks — there is no process boundary preventing it. This is the core accepted limitation.
- "Enforced in the domain layer" is not equivalent to "enforced server-side" for any production deployment with real adversarial users; this architecture, as currently designed, is not production-ready from a security standpoint without a backend.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A judge or reviewer treats this as disqualifying rather than as a scoped, disclosed trade-off | The limitation is stated consistently across the Solution Design, this ADR, and the Architecture Defence package — never hidden, always paired with the specific architectural reason (team size, timeline, proportionality) |
| The requirements baseline explicitly and repeatedly assumes a server-side API (HTTP status codes, a `Campaign API Gateway`, database-level `UPDATE ... WHERE version = :expected_version` enforcement) | This is the central subject of ADR-006 — not resolved by this ADR, which documents only what the current Solution Design actually built |

## Requirement Traceability

| Requirement | How this decision addresses it |
|---|---|
| Authentication (must reject unauthenticated requests) | `AuthProvider.currentUser()` gate before any use case proceeds |
| Authorization enforcement, self-review prevention (must not rely on the client alone) | Checked in Application layer and defensively again in the Domain aggregate — never only in Presentation |
| "Server-side" enforcement (literal requirement) | **Not fully satisfied** — explicitly documented as the accepted gap this ADR records |

## Assumptions and Open Risks

This ADR assumes the hackathon deliverable's threat model does not require defending against a malicious, modified client — an assumption that would not hold in a production deployment. It assumes no backend will be introduced for the current deliverable; if that assumption changes (ADR-006), this ADR would be superseded, not silently reinterpreted.

## Related ADRs and Design Sections

- Solution Design (HLD) §4.13 (Security Architecture), §4.15 (Deployment and Runtime Architecture — "The NFR-008/009 Gap, Stated Plainly").
- Low-Level Design (LLD) §5.2.1 (Authentication & Authorization module).
- ADR-001 (architecture style — the Application/Domain layering this decision relies on).
- ADR-005 (persistence strategy — the companion decision on where data lives).
- ADR-006 (multi-stage approval & server-side enforcement reconciliation) — the requirements baseline's server-side RBAC expectation is not met by this ADR and is tracked there as unresolved.
