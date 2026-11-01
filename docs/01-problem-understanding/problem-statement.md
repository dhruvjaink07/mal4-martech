# Problem Statement

> **Document Status:** Draft v1.0
> **Last Updated:** 2026-11-01
> **Owner:** Domain Research & Requirements Lead

---

## Context

Marketing campaigns in enterprise and mid-market organisations pass through multiple stages before reaching their target audience: ideation, content creation, audience selection, budget allocation, compliance review, approval, scheduling, and execution.

In practice, campaign approval is one of the most operationally critical and error-prone stages. Research into real-world marketing platforms (HubSpot, Adobe Marketo, Salesforce Marketing Cloud, Braze, Mailchimp) confirms that every major MarTech platform has invested in structured approval workflows — ranging from simple binary draft/approved models (Marketo) to multi-stage sequential review pipelines (HubSpot Enterprise, Salesforce Content Builder Approvals, Adobe Campaign).

The reason is straightforward: a campaign that goes live without proper review can cause brand damage, regulatory violations (GDPR, CAN-SPAM), wasted budget, or legal liability. In regulated industries (financial services, healthcare, pharmaceuticals), unapproved promotional materials can trigger regulatory action.

---

## Problem

Marketing teams lack a reliable, structured system to manage the lifecycle of campaign proposals through review and approval. Without such a system, the following problems occur:

1. **No single source of truth for campaign state.** Teams rely on email threads, spreadsheets, or verbal confirmations to track whether a campaign is draft, under review, approved, or rejected. This leads to confusion about the current status of any given campaign.

2. **No enforcement of approval policies.** Without a system-enforced workflow, campaigns can be published without required sign-offs. There is no guarantee that the version reviewed is the same version scheduled for delivery.

3. **No traceability.** When questions arise about who approved a campaign, when, and which version was approved, there is no reliable audit trail. This is a compliance risk in regulated environments and a governance risk in all organisations.

4. **Revision cycles are unstructured.** When a reviewer requests changes, feedback may be lost, revisions may not be re-submitted for review, or the wrong version may be approved. There is no systematic link between review feedback and the resulting revision.

5. **Concurrent access is unmanaged.** Multiple team members may edit a campaign simultaneously, or a reviewer may approve a campaign while the marketer is still modifying it. Without concurrency controls, the system can enter inconsistent states.

6. **Post-approval changes are uncontrolled.** Critical modifications to an already-approved campaign (budget increase, audience change, content revision) may proceed without triggering re-approval, undermining the governance process.

---

## Impact

| Impact Area | Consequence |
|---|---|
| **Brand integrity** | Unapproved or outdated messaging reaches customers |
| **Regulatory compliance** | Campaigns violating GDPR, CAN-SPAM, or industry-specific regulations are published |
| **Budget governance** | Spend commitments are made without proper financial authorisation |
| **Operational efficiency** | Manual tracking of approvals wastes team time and introduces errors |
| **Auditability** | Inability to reconstruct who approved what, when, and which version |
| **Team coordination** | Miscommunication between marketers, reviewers, and approvers causes delays and rework |

---

## Desired Outcome

A system that provides:

1. **A structured campaign lifecycle** with well-defined states, transitions, and business rules governing movement between states.

2. **A formal review and approval workflow** where campaigns must be explicitly approved by authorised reviewers before they can proceed to scheduling.

3. **Version-aware approvals** where approval decisions are bound to specific, immutable campaign versions — not to mutable, in-progress drafts.

4. **Revision tracking** that links reviewer feedback to specific versions and enables re-submission for review after revisions are made.

5. **Concurrency safety** ensuring that simultaneous edits and review actions do not produce inconsistent campaign states.

6. **Change-detection-driven re-approval** where material modifications to an approved campaign automatically invalidate the existing approval and require re-review.

7. **A complete audit trail** recording every significant action (creation, submission, review decision, revision, approval, scheduling) with the actor, timestamp, and affected campaign version.

8. **Failure resilience** ensuring that partially completed operations (e.g., approval recorded but notification fails) are recoverable and do not leave the system in an inconsistent state.

---

## Scope Boundaries

### In Scope

- Campaign creation, editing, and metadata management (proposal-level).
- Campaign submission for review.
- Review workflow: approve, reject, request changes.
- Campaign revision and re-submission.
- Version management tied to approval decisions.
- Scheduling gate (only approved campaigns can be scheduled).
- Audit trail for all significant lifecycle actions.
- Role-based access control for campaign operations.

### Out of Scope (for initial architecture)

- Campaign content creation tooling (rich text editors, creative design tools).
- Actual campaign delivery or execution (email sending, ad placement, push notifications).
- Audience segmentation engine.
- Analytics and performance reporting.
- Integration with specific ad platforms, CRM, or DAM systems.
- A/B testing or experimentation framework.

> **Note:** Integration points with external systems (CRM, DAM, analytics, scheduling/publishing platforms) are acknowledged as important in a production MarTech system and should be modelled at the system boundary, even though their implementation is out of scope.

---

## Alignment with MAL4 Challenge

This problem maps directly to the MAL4 MarTech track: **Campaign Review & Approvals**.

The MAL4 evaluation criteria emphasise:

| Criterion | Weight | Relevance to This Problem |
|---|---|---|
| Problem framing & scope | 10% | This document establishes the problem boundary |
| Structure & boundaries | 15% | Campaign lifecycle states and component boundaries |
| Data & state management | 15% | Campaign versioning, approval state, concurrency |
| Failure & recovery handling | 10% | Partial operation recovery, idempotent operations |
| Trade-offs & adaptability | 10% | Architecture decisions with explicit trade-offs |
| Testing & observability | 15% | Meaningful tests and diagnostic logs |
| Working user journey | 15% | Functional core approval flow |
| Architecture defence | 10% | Prepared to explain and justify every decision |

> **Conflict Note:** The project context states that prototyping is optional. However, MAL4 hackathon rules require a "runnable mobile application" demonstrating a functional core flow (15% of score). This conflict must be resolved with the team. The architecture work remains the top priority (60% of score), but a minimal working user journey must be planned.

---

## Assumptions

| ID | Assumption | Confidence | Impact if Wrong |
|---|---|---|---|
| A-001 | The system serves a single organisation (single-tenant) for the initial architecture. Multi-tenancy is a future concern. | Medium | Would require tenant isolation design upfront |
| A-002 | Campaigns are the primary entity; a campaign consists of metadata, content references, audience definition, budget, and schedule. | High | Fundamental domain model change |
| A-003 | The approval workflow is configurable but initially supports a single approval stage (one or more reviewers). | Medium | Multi-stage approval adds state machine complexity |
| A-004 | Campaign content is referenced, not stored (e.g., links to assets), keeping the campaign entity lightweight. | Medium | Storing large content blobs changes storage design |
| A-005 | The system is used by small-to-medium marketing teams (5–50 users, tens to hundreds of campaigns). | Medium | Higher scale changes consistency and performance assumptions |
| A-006 | Mobile-first interaction is required for the MAL4 deliverable. | High (confirmed by MAL4 rules) | Changes the client architecture |

---

## Open Questions

| ID | Question | Status | Impact |
|---|---|---|---|
| OQ-001 | Should the system support multi-level (sequential) approval stages in the initial design, or is a single approval gate sufficient? | Open | State machine complexity, workflow engine design |
| OQ-002 | What constitutes a "material change" that triggers re-approval? Should this be configurable per organisation? | Open | Change detection logic, approval invalidation rules |
| OQ-003 | Is multi-tenancy a requirement, or is the system single-organisation? | Open | Data isolation, authentication, authorisation model |
| OQ-004 | Should campaign scheduling be modelled as an internal state transition or as a handoff to an external scheduling system? | Open | System boundary definition |
| OQ-005 | What is the expected team size and campaign volume? | Open | Influences consistency model and scaling assumptions |
| OQ-006 | Does the team want to build the mobile user journey, and if so, in which technology? | Open — requires team decision | Time allocation during hackathon |
