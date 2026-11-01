# MAL4 Architecture Defence & Presentation Master Guide
### Pitching the One-Pager, HLD, LLD, and ADRs (2-Speaker Team Rehearsal Guide)

> **Hackathon Track:** Mobile Architecture Lab 4 (MAL4) &bull; MarTech Campaign Review & Approval  
> **Presentation Window:** 10-minute presentation + 5-minute technical jury cross-examination  
> **Team Division:**  
> * **Speaker 1 (Domain & Solution Architect):** Business problem framing, regulatory liabilities, One-Pager pitch, HLD system context, modular decomposition, and boundary governance.  
> * **Speaker 2 (Principal Technical Architect):** LLD domain contracts, state machine invariants, dual-check concurrency control, atomic transactions, ADR trade-off defense, and ADR-006 reconciliation.

---

## 1. Ten-Minute Presentation Flow & Time Allocation

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
> * * **ADR-003 (Event Processing):** In-process domain events emitted strictly post-commit, ensuring notification outages cannot roll back durable transactions.*  
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

## 3. Top 6 Jury Cross-Examination Defense Playbook

### Q1: "Why a Modular Monolith? Isn't Microservices the enterprise standard?"
* **Response (Speaker 1):**  
  *"Microservices solve organizational scaling bottlenecks—enabling 50 independent teams to deploy on separate cadences—and divergent infrastructure scaling needs. Neither applies to a 2-person team building for 50 concurrent users. Introducing microservices would force distributed sagas, 2PC coordinators, and network partitioning risks that directly threaten our primary goal: strict transactional consistency. Our Modular Monolith delivers clean domain boundaries without distributed complexity."*

### Q2: "You have no backend server. Isn't on-device authorization insecure?"
* **Response (Speaker 2):**  
  *"Yes, against a malicious user tampering with a decompiled binary—which we disclosed plainly in ADR-004. However, we did not leave enforcement in the UI: our RBAC and Separation of Duties are hard-coded in the Application and Domain layers. An attacker cannot bypass checks merely by manipulating Flutter widgets or deep links. Crucially, our `AuthProvider` and `CampaignRepository` interfaces form the exact seam where an enterprise OIDC Identity Provider and API gateway slot in for production without touching domain code."*

### Q3: "How do you mathematically prevent post-approval drift?"
* **Response (Speaker 2):**  
  *"Through three structural mechanisms:*  
  1. *Snapshots are immutable. When v1 is submitted, its canonical content is locked.*  
  2. *The `ApprovalRecord` does not set a boolean flag on the campaign row; it binds immutably to `versionReviewed`.*  
  3. *At the Scheduling Gate, the domain re-verifies that `campaign.currentVersion == approval.versionReviewed`. If any edit occurred, the version was bumped to v2, causing the scheduling gate to immediately abort with `VersionMismatchError`."*

### Q4: "Why use full immutable snapshots instead of event-sourced delta diffs?"
* **Response (Speaker 1):**  
  *"Event-sourcing diffs save storage, but require replaying projection streams to reconstruct state. If projection lag occurs or a mobile client experiences intermittent connectivity, you risk 'reconstruction drift' where reviewers evaluate slightly different state than what was submitted. Full immutable snapshots are $O(1)$ queryable, permanently verifiable, and the payload size of a campaign metadata record is under 50KB—storage is cheap; audit correctness is priceless."*

### Q5: "What happens if two reviewers submit decisions at the exact same split-second?"
* **Response (Speaker 2):**  
  *"Our Optimistic Concurrency Control handles this deterministically. Both reviewers load version 1. Reviewer A’s write arrives first; the repository checks `expectedVersion == 1`, commits, and increments the stored version to 2. Reviewer B’s write arrives an instant later with `expectedVersion == 1`; the repository detects `storedVersion == 2`, rejects the write immediately, and throws `ConflictFailure(409)`. Reviewer B is notified to reload and inspect the updated state. We never allow silent overwrites."*

### Q6: "Why did ADR-006 remain 'Proposed / Unresolved' in your ADR index?"
* **Response (Speaker 1):**  
  *"Because intellectual honesty is an architectural virtue. When requirements evolve faster than the solution design, bad engineering teams quietly rewrite documents to pretend they always matched. We treated the divergence as a first-class architectural event. Recording ADR-006 made the conflict visible and quantified three clear paths forward. In our defense, we stand firmly on Option C: the delivered prototype validates the governance rules on device, while the schema documents the enterprise target state."*

---

### Reference Architecture Deliverables Index
* **Executive 1-Pager Brief:** [`assets/diagrams/MAL4_MarTech_One_Page_Solution_Brief.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/assets/diagrams/MAL4_MarTech_One_Page_Solution_Brief.pdf)
* **High-Level Design (HLD):** [`docs/09-architecture-deliverables/MAL4-HLD.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-HLD.pdf)
* **Low-Level Design (LLD):** [`docs/09-architecture-deliverables/MAL4-LLD.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-LLD.pdf)
* **Architecture Decision Records (ADR):** [`docs/09-architecture-deliverables/MAL4-ADR.pdf`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/09-architecture-deliverables/MAL4-ADR.pdf)
* **Jury Question Bank:** [`docs/08-architecture-defence/anticipated-questions.md`](file:///Users/phodeco/Tech/study/mal4-martech-campaign-arch/docs/08-architecture-defence/anticipated-questions.md)
