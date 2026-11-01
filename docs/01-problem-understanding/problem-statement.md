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

2. **A formal multi-level review and approval workflow** where campaigns must clear sequential domain gates (Stage 1: Creative/Brand → Stage 2: Compliance/Legal → Stage 3: Finance/Budget) with strict separation of duties before they can proceed to scheduling.

3. **Version-aware approvals** where approval decisions are bound to specific, immutable campaign versions — not to mutable, in-progress drafts.

4. **Revision tracking** that links reviewer feedback to specific versions and enables re-submission for review after revisions are made.

5. **Concurrency safety** ensuring that simultaneous edits and review actions do not produce inconsistent campaign states.

6. **Change-detection-driven re-approval** where material modifications (budget shifts, audience expansions, disclaimer/claims changes, date shifts) to an approved or pending campaign automatically invalidate existing approvals and trigger re-review.

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
| A-003 | The system implements a **multi-level sequential approval pipeline** (Stage 1: Creative/Brand → Stage 2: Compliance/Legal → Stage 3: Finance/Budget), guaranteeing strict separation of duties and regulatory compliance before scheduling. | High (Resolved) | State machine and review progression logic |
| A-004 | Campaign content is referenced, not stored (e.g., links to assets), keeping the campaign entity lightweight. | Medium | Storing large content blobs changes storage design |
| A-005 | The system is used by small-to-medium marketing teams (5–50 users, tens to hundreds of campaigns). | Medium | Higher scale changes consistency and performance assumptions |
| A-006 | Mobile-first interaction is required for the MAL4 deliverable. | High (confirmed by MAL4 rules) | Changes the client architecture |
| A-011 | **Material changes** to a campaign (budget shifts, audience pivots, disclaimer modifications, date extensions) automatically invalidate previous approvals, reverting the campaign to Changes Requested/Draft and requiring re-approval. | High (Resolved) | Invalidation hooks and scheduling gate enforcement |

---

## Open Questions

| ID | Question | Status | Impact / Resolution |
|---|---|---|---|
| OQ-001 | Should the system support multi-level (sequential) approval stages in the initial design, or is a single approval gate sufficient? | **Resolved** | **Multi-Level Sequential Pipeline Adopted.** (Creative → Legal/Compliance → Finance). Prevents SOX/regulatory non-compliance. See Defensible Approaches below. |
| OQ-002 | What constitutes a "material change" that triggers re-approval? Should this be configurable per organisation? | **Resolved** | **Material Change Detection Adopted.** Modifications to budget (±10% or DOA tier), audience scope, legal claims, and dates invalidate approvals. Non-material metadata edits do not. |
| OQ-003 | Is multi-tenancy a requirement, or is the system single-organisation? | Open (Bonus Scope) | Single-tenant core domain model with clean tenant_id discriminator on boundary. |
| OQ-004 | Should campaign scheduling be modelled as an internal state transition or as a handoff to an external scheduling system? | **Resolved** | **Decoupled Handoff Gate.** System enforces the gate transition to Scheduled; execution dispatch is handled asynchronously via Transactional Outbox. |
| OQ-005 | What is the expected team size and campaign volume? | Open | Baseline: 5–50 concurrent users, 10–200 active campaigns, 10–100 review actions/day. |
| OQ-006 | Does the team want to build the mobile user journey, and if so, in which technology? | Open — requires team decision | Flutter / Native mobile user journey demonstrating core review & recovery. |

---

## Defensible Architectural Approaches to Core Decisions

To prepare for hackathon jury defense and establish architectural integrity upfront, the following architectural choices have been defended against their rejected alternatives:

### 1. Multi-Level Sequential Approval Pipeline vs. Single-Stage Gate vs. Dynamic BPMN Engine
* **Chosen Approach:** Deterministic 3-stage sequential approval pipeline (**Stage 1: Creative & Brand Review** $\rightarrow$ **Stage 2: Legal & Compliance Audit** $\rightarrow$ **Stage 3: Finance & Budget Authorization**). Each stage is bound to specific role authorizations and an immutable version snapshot.
* **Why Chosen (Defensible Rationale):** 
  - *Regulatory & Governance Mandate:* Real-world marketing campaigns face legal liability (GDPR, CAN-SPAM, FINRA Rule 2210) and corporate governance mandates (SOX 404). Conflating creative, legal, and budgetary approvals into a single generalist gate violates strict separation of duties (SoD).
  - *Early Defect Detection:* Staging creative review before legal prevents high-cost legal counsel from reviewing non-final creative copy; staging finance last ensures spend is authorized only on legally approved commitments.
* **Defensive Comparison (Why Not the Alternatives):**
  - *Why Not a Single-Stage Pool Gate?* While a single gate is simpler to code, it allows a creative marketer to approve legal disclaimers or a junior manager to commit executive-level budgets, creating severe compliance vulnerability.
  - *Why Not a Dynamic External BPMN Engine (e.g., Camunda, Temporal)?* Overkill for a deterministic 3-stage workflow. BPMN engines introduce significant operational complexity, distributed transaction overhead, external dependency failure modes, and synchronization lag between external process states and the application database.

### 2. Material Change Invalidation & Re-Approval Trigger vs. Any-Edit Invalidation vs. Silent Mutation
* **Chosen Approach:** Automated Material Change Detection. Any modification to high-risk campaign parameters (budget exceeding $\pm 10\%$ or DOA limits, target audience expansions, regulatory claims/disclaimers, or date shifts $> 72$ hours) invalidates prior approval sign-offs, increments the version snapshot ($vN \rightarrow vN+1$), and re-enters the review pipeline. Non-material metadata changes (e.g., internal campaign tags, administrative notes) are logged to the audit trail without invalidating approval.
* **Why Chosen (Defensible Rationale):**
  - *Eliminates Post-Approval Drift:* Prevents the critical vulnerability where version $v1$ is approved by reviewers, but an unauthorized or altered version $v2$ is scheduled and published to customers.
  - *Balanced Team Agility:* Enforcing re-approval strictly on *material* changes ensures regulatory safety without paralyzing marketing teams with re-approval cycles over harmless typo corrections in internal tags.
* **Defensive Comparison (Why Not the Alternatives):**
  - *Why Not "Any Edit Invalidates Approval"?* Excessively rigid. Forcing an executive compliance and finance re-approval cycle because a marketer corrected an internal tracking label damages marketing velocity and leads users to bypass the system.
  - *Why Not Silent In-Place Mutation (No Invalidation)?* Fatal governance vulnerability. Allows marketers to double ad budgets or alter legal disclaimers post-approval, directly causing financial waste and regulatory fines.

### 3. Immutable Snapshot Versioning ($vN$) vs. Incremental JSON Delta Diffs
* **Chosen Approach:** Immutable full-state snapshot on every submission ($v1, v2, \dots$), stored with a cryptographic SHA-256 digest (`snapshot_hash`). Approvals and audit logs are cryptographically bound to this digest.
* **Why Chosen (Defensible Rationale):**
  - *Deterministic Read Performance:* Mobile clients rendering campaign reviews achieve instant $O(1)$ read performance without replaying delta event logs over high-latency cellular connections.
  - *Cryptographic Non-Repudiation:* Proves mathematically to regulatory auditors that the exact content, disclaimer, and budget reviewed by the compliance officer matches what was scheduled.
* **Defensive Comparison (Why Not the Alternatives):**
  - *Why Not Incremental JSON Diffs / Event Sourcing Projections?* Delta diffs require sequential replay to reconstruct point-in-time state. If an intermediate event is corrupted or projection schema drifts, state reconstruction fails. In a mobile environment, snapshot reconstruction adds unnecessary client CPU and network latency.

### 4. Synchronous Optimistic Concurrency Control vs. Pessimistic Row Locking
* **Chosen Approach:** Database-level optimistic locking using monotonic version counters (`WHERE id = :id AND version = :v`) paired with client-generated `Idempotency-Key` headers on state transitions.
* **Why Chosen (Defensible Rationale):**
  - *Mobile-First Resilience:* Reviewers on mobile devices experience intermittent network connectivity and variable latency. Optimistic locking avoids holding database locks during human review pauses.
  - *Deadlock Elimination:* Multiple reviewers inspecting campaigns concurrently never trigger database deadlocks or transaction timeouts.
* **Defensive Comparison (Why Not the Alternatives):**
  - *Why Not Pessimistic Row Locks (`SELECT FOR UPDATE`)?* If a reviewer opens a campaign on mobile and boards a subway or loses cellular connection, the database row remains locked indefinitely, blocking other team members and starving the connection pool.

### 5. Decoupled Transactional Outbox for Notifications vs. Synchronous Outbound RPC
* **Chosen Approach:** Transactional Outbox pattern. State transitions and outbound notification events are committed atomically to the relational database in a single local transaction. An asynchronous background worker polls/streams the outbox and dispatches push notifications (FCM/APNS) and emails.
* **Why Chosen (Defensible Rationale):**
  - *Blast-Radius Isolation:* A third-party push notification outage (e.g., FCM 500 error or SendGrid timeout) never blocks, fails, or rolls back a business-critical approval transaction.
  - *Guaranteed At-Least-Once Delivery:* Outbox events survive server crashes and network partitions with automated retry and Dead Letter Queue (DLQ) support.
* **Defensive Comparison (Why Not the Alternatives):**
  - *Why Not Synchronous In-Line HTTP/RPC Notifications?* Synchronous external calls inside the approval transaction introduce 500–3000ms network latency to the user, deplete database connection pools, and risk rolling back valid business approvals if the notification service hiccups.
