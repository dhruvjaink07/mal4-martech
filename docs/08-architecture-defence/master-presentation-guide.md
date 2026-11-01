# MAL4 Architecture Defence & Presentation Master Guide
### Pitching the One-Pager, HLD, LLD, and ADRs (2-Speaker Team Rehearsal Guide)

> **Hackathon Track:** Mobile Architecture Lab 4 (MAL4) &bull; MarTech Campaign Review & Approval  
> **Team Division:**  
> * **Speaker 1 (Domain & Solution Architect):** Business problem framing, regulatory liabilities, One-Pager pitch, HLD system context, modular decomposition, and boundary governance.  
> * **Speaker 2 (Principal Technical Architect):** LLD domain contracts, state machine invariants, dual-check concurrency control, atomic transactions, ADR trade-off defense, and ADR-006 reconciliation.

---

## ⚡ 0. EMERGENCY EXPRESS PITCH (< 5 MINUTES TOTAL)

> **Target:** 3 minutes 30 seconds total + open for Q&A.  
> **Delivery Rule:** High energy, brisk pace, speak to the business stakes and architectural guarantees.

### ⏱️ 0:00 – 0:45 | Problem & The One-Pager (Speaker 1)
> *"Judges, enterprise campaigns involve millions in ad spend and severe regulatory liabilities under GDPR, CAN-SPAM, and SOX 404. Today, reviews happen over Slack and spreadsheets, leading to the most dangerous failure in MarTech: **post-approval drift**—where Version 1 is approved, but someone modifies copy or budget, and an unreviewed Version 2 goes live.*  
> *We built a deterministic platform where an approval is permanently bound to an immutable snapshot:*  
> $$\text{Draft} \xrightarrow{\text{Submit}} \text{Pending Review} \xrightarrow{\text{Review}} \{\text{Approved}, \text{Changes Requested}, \text{Rejected}\} \xrightarrow{\text{Revise}} \text{Re-Submit} \xrightarrow{\text{Gate}} \text{Scheduled}$$  
> *No campaign can ever clear the scheduling gate unless its current digest matches the exact version approved."*

### ⏱️ 0:45 – 01:45 | High-Level Design (HLD) (Speaker 1)
> *"For our architecture, we made deliberate, principled choices:*  
> 1. ***Modular Monolith, Not Microservices:** At our scale (50 users, 200 campaigns, 2-person team), microservices introduce network latency and distributed transaction failures that threaten state consistency. We chose a Feature-First Modular Monolith.*  
> 2. ***Clean-Architecture-Lite:** Our Domain layer has **zero outward dependencies**—it imports neither Flutter nor SQLite. Every business rule is unit-testable in under 50ms.*  
> 3. ***Honest Security Boundary:** On our local-first mobile prototype, RBAC and Separation of Duties are enforced in the Application and Domain layers—never just the UI. We openly acknowledge that this does not provide server-side protection against decompiled binary tampering, but our repository and auth interfaces form the exact seam where a backend API slots in for production."*

### ⏱️ 01:45 – 02:45 | Low-Level Design (LLD) (Speaker 2)
> *"In the LLD, the `Campaign` aggregate root strictly enforces three critical invariants:*  
> 1. ***Separation of Duties (Anti-Self-Approval):** If a campaign author attempts to review their own submission, the domain aborts with `SelfReviewError`.*  
> 2. ***Dual-Check Concurrency:** Reviewers take hours to evaluate creative assets, so pessimistic locking is unusable. We use Optimistic Concurrency Control with two checks: a **Domain Staleness Check** to ensure the reviewer's viewed version is still current, and a **Repository Token Check** (`save(campaign, expectedVersion)`) to reject race-condition overwrites with `409 Conflict`.*  
> 3. ***Material Change Invalidation:** If an approved campaign has a budget shift $\ge \pm 10\%$, reach shift $> 15\%$, or date shift $> 72$ hours, existing approvals are revoked, version bumps to $vN+1$, and it re-enters review.*  
> 4. ***Atomic Persistence:** State transitions and audit entries commit in the **exact same transaction**—state and audit records can never desynchronize."*

### ⏱️ 02:45 – 03:30 | ADRs & ADR-006 Reconciliation (Speaker 2)
> *"Every choice has a formal ADR with rejected alternatives:*  
> * *We chose **immutable full snapshots** over event diffs because $O(1)$ point-in-time verification eliminates projection lag.*  
> * *We chose **in-process events emitted strictly post-commit**, ensuring notification outages never roll back durable transactions.*  
> * *Most importantly, look at **ADR-006**: During documentation, we found our requirements evolved to specify a 3-stage sequential pipeline with a backend, while our Solution Design assumed single-approval local-first.*  
> *Instead of quietly hiding this, we documented it as an explicit conflict with three resolution paths. In our defense, we present **Option C**: our delivered mobile prototype validates all governance mechanics on-device, while the relational schema and outbox specifications serve as our documented Enterprise Target Architecture."*

### ⏱️ 03:30 – 03:45 | Hand-off to Jury Q&A (Both)
> *"We delivered a production-grade architecture that is provably correct, completely honest about its boundaries, and backed by a full suite of HLD, LLD, and ADR deliverables. We're ready for your questions."*

---

## 🛡️ Top 3 Instant Judge Answers (10-Second Snipers)

1. **"Why no microservices?"**  
   &rarr; *"Microservices solve organizational scaling across 50 teams and divergent deployment schedules. For 2 engineers and 50 users, it adds distributed transaction risk that destroys state consistency. Modular Monolith gives us boundary isolation with zero network overhead."*
2. **"How do you prevent post-approval drift?"**  
   &rarr; *"Approvals bind to the immutable snapshot version integer, not a mutable boolean flag. At the scheduling gate, we mathematically verify `campaign.currentVersion == approval.versionReviewed`. Any edit increments the version and fails the gate."*
3. **"Why is ADR-006 unresolved?"**  
   &rarr; *"Intellectual honesty. Bad teams silently rewrite documents to pretend they matched. We made the divergence visible, presented Options A, B, and C, and chose Option C: an MVP prototype proving the domain invariants on device, and target architecture documented in the schema."*

---

## 1. Full 10-Minute Presentation Flow & Time Allocation

```
00:00 - 02:00 (2.0 min) | Part 1: The One-Pager — Problem, Regulatory Stakes & Core Flow (Speaker 1)
02:00 - 04:30 (2.5 min) | Part 2: High-Level Design (HLD) — Architecture Style & Topology (Speaker 1)
04:30 - 07:00 (2.5 min) | Part 3: Low-Level Design (LLD) — Invariants, Concurrency & State Guard (Speaker 2)
07:00 - 09:00 (2.0 min) | Part 4: ADR Defense & The ADR-006 Reconciliation (Speaker 2)
09:00 - 10:00 (1.0 min) | Part 5: Executive Wrap-Up & Hand-off to Jury Q&A (Both)
```

---

## Part 1: The One-Pager Pitch (00:00 – 02:00)
**Speaker 1:** *Deliver with authority; frame the technical architecture around massive enterprise financial and legal stakes.*

### 1.1 The Enterprise Problem & Market Context (45s)
> *"Judges, in enterprise marketing operations, marketing campaigns represent significant financial commitments and severe regulatory liabilities. Today, campaign reviews are broken: teams coordinate over Slack, email, and spreadsheets.*  
> *This ad-hoc governance exposes enterprises to three catastrophic failure modes:*  
> 1. ***Regulatory Fines:** Opt-in violations under GDPR, disclosure omissions under CAN-SPAM, or misleading claims penalized under SEC and FINRA.*  
> 2. ***Brand Erosion:** Outdated assets, unvetted discounts, or off-brand messaging slipping into production storefronts.*  
> 3. ***Financial Overspend:** Unbudgeted spend exceeding delegation-of-authority (DOA) limits under SOX 404.*  
> *The root cause is structural: existing tools treat approvals as informal status tags rather than immutable, cryptographically verifiable contracts."*

### 1.2 The Core Governance Failure: Post-Approval Drift (35s)
> *"The single most damaging failure in MarTech is **post-approval drift**: a domain reviewer approves Version 1 of a campaign, but someone tweaks copy or budget later, and an unreviewed Version 2 is scheduled and published.*  
> *Our architecture solves this by construction: an approval is permanently bound to the exact immutable snapshot reviewed. If a campaign changes by even a single byte, existing approvals are invalidated."*

### 1.3 The Deterministic Core Flow (40s)
> *"We guide every campaign through a deterministic 6-state lifecycle:*  
> $$\text{Draft} \xrightarrow{\text{Submit}} \text{Pending Review} \xrightarrow{\text{Review}} \{\text{Approved}, \text{Changes Requested}, \text{Rejected}\} \xrightarrow{\text{Revise}} \text{Re-Submit} \xrightarrow{\text{Gate}} \text{Scheduled}$$  
> *Only an approved campaign on its approved snapshot can ever clear the scheduling gate."*

> 🎙️ **Transition to HLD:** *"To enforce these business rules without compromise, our High-Level Design establishes a clean, decoupled modular architecture."*

---

## Part 2: High-Level Design (HLD) Walkthrough (02:00 – 04:30)
**Speaker 1:** *Reference [`docs/09-architecture-deliverables/MAL4-HLD.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-HLD.pdf) §4.6–§4.15.*

### 2.1 Architecture Style: Modular Monolith + Clean-Lite (50s)
> *"We made a deliberate, principled choice to reject microservices. For a 2-person engineering team and an enterprise workload of 5–50 concurrent users and 200 active campaigns, distributed microservices would introduce network latency, distributed transaction coordination, and operational overhead that would directly jeopardize delivery.*  
> *Instead, we designed a **Modular Monolith** organized **Feature-First**, layered with **Clean-Architecture-lite**.*  
> *Our Domain layer has zero outward dependencies—it imports neither Flutter nor SQLite. Every lifecycle guard, state transition, and authorization check is unit-testable in pure Dart in under 50ms without mocking databases or UI frameworks."*

### 2.2 Subsystem Decomposition: 7 Cohesive Capabilities (50s)
> *"The system decomposes into 7 cohesive modules:*  
> 1. ***Authentication & Authorization:*** *Role-based gating and Separation of Duties.*  
> 2. ***Campaign Management:*** *Proposal creation and metadata drafting.*  
> 3. ***Campaign Version Management:*** *Immutable snapshotting ($O(1)$ queryable).*  
> 4. ***Review & Approval Workflow:*** *Consolidated because a reviewer’s decision IS the approval.*  
> 5. ***Audit Management:*** *Append-only, tamper-evident audit ledger.*  
> 6. ***Notification Management:*** *Asynchronous, decoupled lifecycle notifications.*  
> 7. ***Scheduling:*** *The final defensive gate before outbound delivery engines."*

### 2.3 The Authorization Boundary & Stated Gap (50s)
> *"We want to be completely candid about our security boundary: in our local-first mobile prototype, authorization and Separation of Duties (Anti-Self-Approval) are enforced on-device within the Application and Domain layers.*  
> *This fulfills the architectural intent of NFR-009—no user can bypass checks by manipulating UI buttons—but we openly disclose that this does not provide server-side cryptographic protection against decompiled binary tampering. Our repository and auth interfaces form the exact seam where a remote Identity Provider and API gateway slot in for production."*

> 🎙️ **Transition to LLD:** *"I'll now hand over to my co-architect to dive into the Low-Level Design contracts, state machine invariants, and concurrency mechanics."*

---

## Part 3: Low-Level Design (LLD) Walkthrough (04:30 – 07:00)
**Speaker 2:** *Reference [`docs/09-architecture-deliverables/MAL4-LLD.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-LLD.pdf) §5.2 & §6.1–§6.6.*

### 3.1 Domain Invariants & Aggregate Root Protection (50s)
> *"In the LLD, the `Campaign` aggregate root strictly guards all business mutations. An illegal transition—such as attempting to approve a `Draft` campaign, or an author attempting to approve their own proposal—throws a typed domain exception before reaching the persistence layer.*  
> *We enforce strict **Separation of Duties (Anti-Self-Approval)**: if `campaign.submitted_by_id == reviewer.id`, the operation is aborted with a `SelfReviewError`. This guarantees regulatory compliance with Sarbanes-Oxley 404 and FINRA Rule 2210."*

### 3.2 Concurrency Control: The Dual-Check Pattern (50s)
> *"We use Optimistic Concurrency Control (OCC) rather than pessimistic locking. A reviewer evaluating creative assets often takes minutes to hours; holding database locks across that thinking time would freeze the system.*  
> *We implement a **dual-check pattern** that answers two distinct questions:*  
> * **1. Domain Staleness Check:** *When an approval is submitted, the use case loads the campaign fresh from the repository and verifies that the version the reviewer viewed matches the current version. If the author withdrew and resubmitted in the interim, it throws `StaleReviewError`.*  
> * **2. Repository Write Check:** *At the persistence boundary, `save(campaign, expectedVersion)` checks the monotonic integer token. If another write committed milliseconds earlier, it throws `ConflictFailure(409)`.*  
> *The second writer fails loudly and immediately; no silent overwrites or automatic merges are ever permitted."*

### 3.3 Material Change Invalidation & Atomic Audit Commits (50s)
> *"If an approved campaign is edited, our domain logic evaluates change materiality:*  
> * *Budget change $\ge \pm 10\%$*  
> * *Audience reach shift $> 15\%$*  
> * *Flight date shifts $> 72$ hours*  
> *A material mutation automatically revokes existing approvals, increments the version to $vN+1$, and forces re-entry through review.*  
> *Furthermore, every state change commits in the **exact same local transaction** as its audit record. State and audit log never desynchronize—they commit together or not at all."*

> 🎙️ **Transition to ADRs:** *"Let us examine the Architecture Decision Records and the trade-offs that govern this design."*

---

## Part 4: ADR Defense & The ADR-006 Reconciliation (07:00 – 09:00)
**Speaker 2:** *Reference [`docs/09-architecture-deliverables/MAL4-ADR.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-ADR.pdf).*

### 4.1 The Core Accepted ADRs (ADR-001 through ADR-005) (45s)
> *"Every architectural choice was evaluated against competing alternatives and documented in our ADRs:*  
> * * **ADR-001 (Architecture Style):** Modular Monolith + Clean-lite. We traded DTO ring-mapper ceremony for speed while preserving domain isolation.*  
> * * **ADR-002 (Data Consistency & Concurrency):** Full immutable snapshots + OCC. We accepted small storage overhead for $O(1)$ point-in-time audit verification without event-sourcing replay lag.*  
> * * **ADR-003 (Event Processing):** In-process domain events emitted strictly post-commit, ensuring notification outages never roll back durable transactions.*  
> * * **ADR-004 (Authorization Boundary):** On-device RBAC with honest stated security boundaries.*  
> * * **ADR-005 (Persistence Strategy):** Drift over SQLite local-first persistence, delivering zero-network offline reliability."*

### 4.2 The Standout Architectural Asset: ADR-006 Reconciliation (75s)
> *"I want to draw your attention to **ADR-006**. While preparing our documentation, we identified that our requirements baseline had evolved to specify a **3-stage sequential pipeline** (Creative &rarr; Compliance &rarr; Finance) with SHA-256 cryptographic snapshot hashes and server-side relational enforcement, while our Solution Design implemented a single-reviewer local-first architecture.*  
> *Rather than papering over this discrepancy or secretly rewriting documents, we recorded it explicitly as **ADR-006: Proposed Reconciliation**, presenting three clear paths:*  
> * * **Option A:** Rewrite the Solution Design to the server-backed 3-stage model.*  
> * * **Option B:** Scope requirements back to single-approval local-first.*  
> * * **Option C (Our Defensible Position):** A Two-Tier architectural narrative.*  
> *Our delivered mobile prototype proves all governance invariants on device, while the PostgreSQL schema, Transactional Outbox, and API Gateway specifications serve as our documented Enterprise Target Architecture. This intellectual honesty proves our review process works."*

---

## Part 5: Closing Wrap-Up (09:00 – 10:00)
**Speaker 1:**  
> *"To summarize: we have delivered an architecture that is:*  
> 1. ***Sized proportionately** to team and timeline.*  
> 2. ***Provably correct** in its state machine, version binding, and concurrency control.*  
> 3. ***Completely transparent** about its operational and security boundaries.*  
> 4. ***Supported by publication-grade deliverables** in our HLD, LLD, ADRs, and 1-Page Brief.*  
> *Thank you. We welcome the jury’s questions."*

---

### Reference Architecture Deliverables Index
* **Executive 1-Pager Brief:** [`assets/diagrams/MAL4_MarTech_One_Page_Solution_Brief.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/assets/diagrams/MAL4_MarTech_One_Page_Solution_Brief.pdf)
* **High-Level Design (HLD):** [`docs/09-architecture-deliverables/MAL4-HLD.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-HLD.pdf)
* **Low-Level Design (LLD):** [`docs/09-architecture-deliverables/MAL4-LLD.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-LLD.pdf)
* **ADR Deliverable (Red/Green/Black):** [`docs/09-architecture-deliverables/MAL4-ADR.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-ADR.pdf)
* **Jury Question Bank:** [`docs/08-architecture-defence/anticipated-questions.md`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/08-architecture-defence/anticipated-questions.md)
