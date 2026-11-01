# MAL4 MarTech Campaign Review & Approval Architecture

[![Hackathon](https://img.shields.io/badge/Hackathon-MAL4%20(Mobile%20Architecture%20Lab)-blue)](https://mobilearchitecturelab.com/mal4#register)
[![Track](https://img.shields.io/badge/Track-MarTech-green)](#assigned-domain--problem-area)
[![Discipline](https://img.shields.io/badge/Discipline-Architecture--First-orange)](#architectural-philosophy)
[![Status](https://img.shields.io/badge/Phase-01%20Domain%20Discovery%20Complete-brightgreen)](#current-progress--status)

A production-grade system architecture study, documentation suite, and architectural defense for an enterprise **Marketing Technology (MarTech) Campaign Review and Approval System**, created for **Mobile Architecture Lab 4 (MAL4)**.

---

## Table of Contents

- [Project Introduction](#project-introduction)
- [Hackathon Context](#hackathon-context)
- [Assigned Domain & Problem Area](#assigned-domain--problem-area)
- [Project Objectives](#project-objectives)
- [Architectural Philosophy](#architectural-philosophy)
- [Documentation Structure](#documentation-structure)
- [Current Progress & Status](#current-progress--status)
- [Master Assumptions Register](#master-assumptions-register)
- [Master Open Questions Register](#master-open-questions-register)
- [Key Domain Research Insights](#key-domain-research-insights)

---

## Project Introduction

In enterprise and mid-market organizations, marketing campaigns (encompassing budgets, audiences, messaging, channels, and schedules) represent critical financial commitments and regulatory liabilities. Launching campaigns without rigorous multi-stakeholder governance risks severe regulatory fines (GDPR, CAN-SPAM, SEC/FINRA, FDA), brand dilution, and wasted ad spend.

This repository hosts the complete architectural artifacts for a **Campaign Lifecycle Management and Review & Approval System**. The system governs how campaign proposals progress through state transitions: from draft proposal to multi-party review, conditional revision, explicit approval, and scheduling gates, supported by version-bound immutability and an append-only audit trail.

---

## Hackathon Context

- **Hackathon:** Mobile Architecture Lab 4 (MAL4) — *"Architects in AI Era"*
- **Organizers:** Mobile Architecture Lab Community (Vivek Yadav & Yogesh Singh), Mumbai
- **Official Website:** [mobilearchitecturelab.com/mal4](https://mobilearchitecturelab.com/mal4#register)
- **Team Size:** Team of 2 (Operating roles: Domain Research & Requirements Lead, and Principal Software/Solution Architect)
- **Core Focus:** Production-grade architecture, boundary isolation, data/state consistency, resilience/recovery, and live architectural defense under technical cross-examination.

### Official MAL4 Evaluation Rubric

| Category | Evaluation Focus | Weight |
|:---|:---|:---:|
| **Architecture: Problem Framing & Scope** | Clarity of domain boundary, problem definition, and explicit scope limits | **10%** |
| **Architecture: Structure & Boundaries** | Component separation, interface definition, dependency management, loose coupling | **15%** |
| **Architecture: Data & State Management** | State machine validity, versioning, concurrency safety, data consistency guarantees | **15%** |
| **Architecture: Failure & Recovery Handling** | Network partitions, idempotency, retry safety, offline sync, partial failure handling | **10%** |
| **Architecture: Trade-offs & Adaptability** | Explicit ADRs, justified trade-offs, rejection of unnecessary complexity | **10%** |
| **Architecture Subtotal** | **Core Architecture Documents & Decisions** | **60%** |
| **Testing & Observability** | Diagnostic logging, telemetry, test strategy, verifiable evidence | **15%** |
| **Working User Journey** | Functional core flow demonstrating Proposal → Review → Revision → Approval → Schedule | **15%** |
| **Architecture Defence** | Live panel Q&A: defending design decisions, trade-offs, failure modes, and code alignment | **10%** |
| **Total** | | **100%** |

> [!IMPORTANT]
> **Prototype Requirement Reconciliation:** While early assumptions noted prototyping was optional, official MAL4 rules assign **15% of the score to a working user journey** and require code-to-architecture consistency. The project therefore employs an **Architecture-First** methodology: complete rigorous domain discovery and structural design before building the scoped mobile slice.

---

## Assigned Domain & Problem Area

- **Track:** MarTech (Marketing Technology)
- **Problem Area:** Campaign Review and Approval Workflows
- **Core Flow:**
  $$\text{Draft} \xrightarrow{\text{Submit}} \text{Pending Review} \xrightarrow[\text{Reject}]{\text{Approve / Request Changes}} \{\text{Approved}, \text{Changes Requested}, \text{Rejected}\} \xrightarrow[\text{Re-submit}]{\text{Revise}} \text{Pending Review} \xrightarrow{\text{Gate}} \text{Scheduled}$$

---

## Project Objectives

1. **Establish Domain Integrity:** Base design decisions on verified real-world patterns across enterprise MarTech solutions (HubSpot, Marketo, Salesforce Marketing Cloud, Braze).
2. **Deterministic State Machine:** Enforce strict, valid state transitions with zero tolerance for conflicting or stale states.
3. **Version-Bound Approvals:** Ensure that an approval sign-off is cryptographically or structurally bound to an immutable campaign snapshot, preventing post-approval drift.
4. **Resilience & Concurrency Safety:** Guarantee idempotent operations, conflict detection under concurrent reviews/edits, and safe recovery from partial failures.
5. **Auditable Lineage:** Maintain an append-only, tamper-evident audit record answering: *Who approved what, when, under which version, and with what rationale?*
6. **Defensibility:** Provide clear Architecture Decision Records (ADRs) with explicit trade-offs and rationale for all system choices.

---

## Architectural Philosophy

- **Simplicity before complexity:** Never adopt distributed microservices, event-sourcing, or heavy message brokers unless workload scale or hard boundaries mandate them.
- **Evidence before assumption:** Justify technology choices with measured requirements and domain constraints.
- **Traceability across all layers:** Maintain consistent IDs (`FR-xxx`, `NFR-xxx`, `A-xxx`, `OQ-xxx`, `ADR-xxx`) across problem understanding, solution design, schemas, diagrams, and codebase.
- **Defensible trade-offs:** Every architectural advantage comes at a cost; every decision must document what was sacrificed.

---

## Documentation Structure

```
.
├── README.md                                  # Master index, context, registers & status
├── DESIGN.md                                  # UI/UX design tokens & visual standards (ui-ux-pro-max + awesome-design-md)
├── assets/
│   ├── diagrams/                              # Visual exports, solution brief HTML, PDF & DOCX
│   │   ├── MAL4_MarTech_One_Page_Solution_Brief.pdf # Official 1-page solution brief PDF
│   │   ├── one-page-solution-brief.pdf        # Styled A4 vector PDF (single page)
│   │   ├── one-page-solution-brief.docx       # Microsoft Word formatted document (.docx)
│   │   └── one-page-solution-brief.html       # Print-ready & responsive executive solution brief
│   └── references/                            # Domain references, standards, regulatory docs
│
└── docs/
    ├── one-page-solution-brief.md             # Markdown version of 1-Page Solution Brief
    ├── 01-problem-understanding/              # Domain Discovery & Scope Foundation
    │   ├── problem-statement.md               # Context, problem, impact, boundaries, MAL4 alignment
    │   ├── stakeholders.md                    # Primary/secondary actors, concerns, RACI, interaction model
    │   ├── functional-requirements.md         # FR-001 to FR-019, state machine definitions, MoSCoW
    │   └── non-functional-requirements.md     # NFR-001 to NFR-017 in SEI scenario format
    │
    ├── 02-solution-design/                    # Architecture Specifications
    │   ├── solution-overview.md               # Architectural vision, high-level pattern, principles
    │   ├── system-context.md                  # C4 Context (system boundaries, integrations)
    │   ├── high-level-design.md               # Decomposition, communication models, subsystem responsibilities
    │   ├── low-level-design.md                # Internal contracts, state transition logic, APIs
    │   └── component-responsibilities.md      # Ownership matrices, dependencies, cohesion
    │
    ├── 03-architecture-decisions/             # Architecture Decision Records (ADRs)
    │   ├── ADR-001-architecture-style.md      # Modular Monolith vs Microservices vs Mobile-Local
    │   ├── ADR-002-data-consistency.md        # Concurrency control & version snapshot model
    │   └── ADR-003-event-processing.md        # Sync write-path vs async side-effects & notifications
    │
    ├── 04-workflows/                          # Detailed Workflow & Recovery Specs
    │   ├── user-journey-flow.mmd              # User journey swimlane flow diagram & operational spec
    │   ├── campaign-lifecycle.md              # Lifecycle state transitions & preconditions
    │   ├── approval-workflow.md               # Review routing, single/multi-stage policies
    │   ├── revision-workflow.md               # Change-detection, diffing, re-approval rules
    │   └── failure-recovery.md                # Idempotency, network drop recovery, retry policies
    │
    ├── 05-diagrams/                           # C4 & Flow Visualizations (Mermaid)
    │   ├── system-context.mmd                 # C4 Level 1 Context Diagram
    │   ├── container-architecture.mmd         # C4 Level 2 Container Diagram
    │   ├── campaign-state-machine.mmd         # Finite State Machine diagram
    │   ├── sequence-diagrams.mmd              # Review, Revision, and Scheduling sequences
    │   └── deployment-architecture.mmd        # Topology, deployment boundaries, data tier
    │
    ├── 06-data-design/                        # Data Architecture
    │   ├── domain-model.md                    # Aggregates, Entities, Value Objects, Invariants
    │   ├── database-schema.md                 # Relational schema, indexes, version tables, audit log
    │   └── event-catalog.md                   # Domain events, payload contracts, deduplication
    │
    ├── 07-quality-attributes/                 # Quality Engineering
    │   ├── scalability.md                     # Bottlenecks, capacity planning, workload projections
    │   ├── reliability.md                     # SLOs, failure containment, outbox patterns
    │   ├── security.md                        # RBAC, tenant isolation, self-review guards
    │   └── observability.md                   # Structured diagnostic logging, metrics, audit traces
    │
    └── 08-architecture-defence/               # Hackathon Defense Preparation
        ├── trade-offs.md                      # Systematic decision comparison matrix
        ├── failure-scenarios.md               # Fault injection, edge cases, mitigation walkthroughs
        └── anticipated-questions.md           # Anticipated jury questions with justified answers
```

---

## Current Progress & Status

| Phase | Milestone | Deliverables | Status |
|:---:|:---|:---|:---:|
| **01** | **Domain Discovery & Requirements** | `problem-statement.md`, `stakeholders.md`, `functional-requirements.md`, `non-functional-requirements.md`, `README.md` | **Completed** |
| **02** | **Core Domain Modelling & State Machine** | `user-journey-flow.mmd`, `campaign-lifecycle.md`, `domain-model.md` | **Completed** |
| **03** | **Solution Architecture & ADRs** | `solution-overview.md`, `system-context.md`, `ADR-001`, `ADR-002`, `ADR-003`, C4 Diagrams | *Pending* |
| **04** | **Data Architecture & Workflows** | Workflows (`approval-workflow.md`, `revision-workflow.md`, `failure-recovery.md`); Data Schemas (`database-schema.md`, `event-catalog.md`) | **Completed** |
| **05** | **Quality Attributes & Defense** | Quality Attributes Completed (`scalability.md`, `reliability.md`, `security.md`, `observability.md`, `traceability.md`, `trade-offs.md`); Defense scenarios pending (`failure-scenarios.md`, `anticipated-questions.md`) | *In Progress* |
| **06** | **Working User Journey (Mobile)** | Scoped Flutter / Native mobile user journey demonstrating core review & recovery | *Pending* |

---

## Master Assumptions Register

| ID | Assumption Description | Confidence | Traces To |
|:---:|:---|:---:|:---|
| **A-001** | Initial architecture is designed for a single organization (single-tenant). Multi-tenancy is modeled at the boundary for modular extensibility. | Medium | [Problem Statement](docs/01-problem-understanding/problem-statement.md) |
| **A-002** | Campaigns are the primary aggregate root; a campaign contains metadata, asset references, audience criteria, budget, and scheduling window. | High | [Problem Statement](docs/01-problem-understanding/problem-statement.md), `FR-001` |
| **A-003** | The system implements a **multi-level sequential approval pipeline** (Stage 1: Creative → Stage 2: Compliance/Legal → Stage 3: Finance/Budget), guaranteeing strict separation of duties and regulatory compliance before scheduling. | High | [Stakeholders](docs/01-problem-understanding/stakeholders.md), `FR-006`, `FR-007` |
| **A-004** | Campaign creative assets are referenced via external URI/storage pointers rather than stored directly as raw binary blobs in the campaign record. | High | [Problem Statement](docs/01-problem-understanding/problem-statement.md), `FR-001` |
| **A-005** | Baseline target workload: 5–50 concurrent users, 10–200 active campaigns, 10–100 review actions/day. | High | [NFR-014](docs/01-problem-understanding/non-functional-requirements.md), [NFR-015](docs/01-problem-understanding/non-functional-requirements.md) |
| **A-006** | Mobile-first client interaction is mandatory for the MAL4 live evaluation (iOS/Android/Flutter). | High | MAL4 Challenge Rules |
| **A-007** | Authenticated users receive role claims (Marketer, Reviewer, Admin) via standard Bearer tokens / session credentials. | High | [Stakeholders](docs/01-problem-understanding/stakeholders.md), `FR-017` |
| **A-008** | Separation of duties is non-negotiable: a submitter cannot approve their own campaign submission (`submitted_by_id != reviewer_id`). | High | `FR-018`, `NFR-010` |
| **A-009** | Core state updates and audit logging are synchronously guaranteed; downstream notifications and analytics dispatch are asynchronous and best-effort via Transactional Outbox. | High | `FR-019`, `NFR-005` |
| **A-010** | Campaign versions are stored as immutable full-snapshot records rather than incremental delta diffs. | High | `FR-013`, `NFR-002` |
| **A-011** | Any material edit made to an approved or in-review campaign invalidates its approval, generating a new version snapshot and re-entering the review pipeline. | High | `FR-014`, `NFR-002` |
| **A-012** | State transitions are strongly consistent; concurrent requests on the same campaign must serialize via optimistic locking. | High | `NFR-001`, `NFR-003` |
| **A-013** | Operations on mobile clients over intermittent networks must supply idempotency keys. | High | `NFR-004` |
| **A-014** | Offline capabilities on mobile focus on drafting and inspecting cached proposals, while state-transition actions require server confirmation. | Medium | `NFR-004`, `OQ-016` |

---

## Master Open Questions Register

| ID | Open Question | Owner | Priority | Status |
|:---:|:---|:---:|:---:|:---:|
| **OQ-001** | Should the initial data model accommodate dynamic multi-stage approval chains (e.g., Creative → Legal → Finance) or a single gate? | Architect Lead | High | **Resolved** (Adopted 3-stage sequential pipeline) |
| **OQ-002** | Should re-approval trigger on *any* modification or only changes exceeding financial/audience materiality thresholds? | Domain Lead | Medium | **Resolved** (Material change classification adopted) |
| **OQ-003** | Is multi-tenancy an explicit requirement for the hackathon evaluation or a bonus architectural dimension? | Jury / Team | Medium | Scoped as bonus extension |
| **OQ-004** | Does the scheduling state transition trigger an internal scheduled job or an outbound dispatch to an external executor? | Architect Lead | Medium | **Resolved** (Outbound dispatch via Outbox) |
| **OQ-005** | What mobile framework (Flutter vs. Kotlin Compose vs. Swift) allows the team to deliver the required user journey fastest? | Team | High | Open |
| **OQ-006** | Should campaign withdrawal be allowed if one reviewer in a multi-reviewer pool has already submitted feedback? | Domain Lead | Low | Open |
| **OQ-007** | Is reviewer delegation (temporary re-assignment of review authority during leave) in scope? | Domain Lead | Low | Out of Initial Scope |
| **OQ-008** | Should rejection allow in-place restart to Draft or enforce the creation of a cloned new campaign? | Domain Lead | Low | **Resolved** (In-place restart with version bump) |
| **OQ-009** | In multi-reviewer pools, does approval require consensus ($N$-of-$N$) or threshold ($M$-of-$N$ / first approval)? | Domain Lead | Medium | **Resolved** (Sequential stage gates: 1 pass per stage) |
| **OQ-010** | What is the audit trail retention requirement (e.g., standard 12 months vs. FINRA 3-year WORM compliance)? | Architect Lead | Low | Scoped to standard append-only |
| **OQ-011** | How should conflicting offline edits on mobile be reconciled upon reconnecting? | Architect Lead | High | Open |

---

## Key Domain Research Insights

Our research of industry platforms (**HubSpot, Adobe Marketo, Salesforce Marketing Cloud, Braze, Mailchimp**) and compliance standards (**GDPR, CAN-SPAM, FINRA 2210, SOX 404**) established key foundations:

1. **State Machine Universality:** Enterprise platforms universally isolate **Draft**, **Under Review**, **Approved**, and **Live/Scheduled** phases. No platform allows unapproved assets into execution pipelines.
2. **Immutability of Reviewed Versions:** Enterprise review gates link approvals to an explicit immutable snapshot or digest. Any mutation to the underlying content/budget post-approval invalidates the status.
3. **Separation of Duties (SoD):** Regulatory frameworks (SOX 404 for budgets, FINRA for retail marketing) legally prohibit the creator of marketing content from executing self-approval.
4. **Decoupled Asynchronous Side-Effects:** Real-world systems isolate the transactional approval state change from notification delivery. Notification delays or failures never roll back an approved campaign.
5. **Audit Lineage as Core IP:** In regulated domains, the audit log (who approved what version, when, and with what rationale) is as critical as the campaign asset itself.
