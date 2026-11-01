# Architecture Traceability Matrix

> **Document Status:** Draft v1.2
> **Last Updated:** 2026-11-01
> **Owner:** Architecture & Engineering Lead

---

## Columns

Requirement → Business Rule → Architecture Component → HLD Section → LLD Section → Diagram → Test Scenario

| Requirement | Business Rule | Architecture Component | HLD Section | LLD Section | Diagram | Test Scenario |
|---|---|---|---|---|---|---|
| FR-001–003 | Campaign creation/edit rules | Campaign Management module, `Campaign` aggregate | `HLD/MAL4-HLD.md` §4.9 | `LLD/MAL4-LLD.md` §5.2.2 | `05-diagrams/class-diagram.mmd` | Unit: creation/edit rules without UI or DB (TC-CAMP-01–04) |
| FR-004 | Submission creates v1, requires complete fields | `SubmitCampaign` use case | `HLD/MAL4-HLD.md` §4.12 | `LLD/MAL4-LLD.md` §5.2.3, §6.2 | `05-diagrams/approval-sequence.mmd` | Use-case test with a fake repository (TC-VER-01) |
| FR-005 | Withdrawal only if no decision yet | `WithdrawSubmission` use case | `HLD/MAL4-HLD.md` §4.9 | `LLD/MAL4-LLD.md` §6.1 | `05-diagrams/campaign-state-machine.mmd` | Unit: withdraw after a decision exists raises `InvalidTransitionError` |
| FR-006–FR-011 | Review & approval decisions, feedback, resubmission | Review & Approval Workflow module | `HLD/MAL4-HLD.md` §4.9, §4.12 | `LLD/MAL4-LLD.md` §5.2.4, §6.1, §6.3 | `05-diagrams/approval-sequence.mmd`, `revision-sequence.mmd` | Integration: stale-approval scenario (TC-REV-02) |
| FR-012 | Scheduling gate, approved version must still be current | Scheduling module | `HLD/MAL4-HLD.md` §4.9, §4.12 | `LLD/MAL4-LLD.md` §5.2.7, §6.6 | `05-diagrams/campaign-state-machine.mmd` | Concurrency test: duplicate-schedule rejection (TC-SCHED-02) |
| FR-013, FR-014 | Versioning, material-change invalidation | Campaign Version Management, `CampaignVersion`/`ApprovalRecord` | `HLD/MAL4-HLD.md` §4.11 | `LLD/MAL4-LLD.md` §5.2.3, §6.2 | `05-diagrams/class-diagram.mmd`, `er-diagram.mmd` | Unit: version-token conflict (TC-VER-03); material-change-invalidation (TC-REV-05) |
| FR-015, FR-016 | Audit logging, approval history view | Audit Management module | `HLD/MAL4-HLD.md` §4.9, §4.11 | `LLD/MAL4-LLD.md` §5.2.5, §6.5 | `05-diagrams/er-diagram.mmd` | Repository: append-only, no update/delete path exists (TC-AUDIT-01–03) |
| FR-017, FR-018 | RBAC, self-review prevention | Authentication & Authorization module | `HLD/MAL4-HLD.md` §4.13 | `LLD/MAL4-LLD.md` §5.2.1, §5.2.4 | `05-diagrams/class-diagram.mmd` | Unit: authorization-check tests independent of UI (TC-AUTH-01–02, TC-REV-03) |
| FR-019 | Lifecycle notifications | Notification Management module | `HLD/MAL4-HLD.md` §4.9, §4.14 | `LLD/MAL4-LLD.md` §5.2.6 | `05-diagrams/error-recovery-sequence.mmd` | Use-case: notification failure does not roll back the transaction (TC-NOTIFY-01) |
| NFR-001–003 | Consistency, version-approval binding, concurrent-edit safety | `CampaignRepository.save` optimistic check | `HLD/MAL4-HLD.md` §4.11, §4.14 | `LLD/MAL4-LLD.md` §6.4 | `05-diagrams/data-flow.mmd` | Concurrency: `ConcurrentModificationError` on stale write |
| NFR-004 | Idempotency | Use-case layer (mechanism not finalized) | `HLD/MAL4-HLD.md` §4.17 (flagged open) | `LLD/MAL4-LLD.md` §6.4 (Gap note), §7 (Idempotency note) | — | **Not yet validated — open item** |
| NFR-005 | Partial-failure recovery | Domain event + Notification Management | `HLD/MAL4-HLD.md` §4.10, §4.14 | `LLD/MAL4-LLD.md` §5.2.6.E | `05-diagrams/error-recovery-sequence.mmd` | Use-case: transaction commit independent of notification outcome (TC-NOTIFY-01) |
| NFR-007 | Duplicate scheduling prevention | Scheduling module | `HLD/MAL4-HLD.md` §4.9, §4.14 | `LLD/MAL4-LLD.md` §5.2.7, §6.4 | `05-diagrams/campaign-state-machine.mmd` | Concurrency: concurrent-schedule test (TC-SCHED-02) |
| NFR-008–010 | Authentication, authorization, self-review enforcement | Authentication & Authorization module | `HLD/MAL4-HLD.md` §4.13 | `LLD/MAL4-LLD.md` §5.2.1 | `05-diagrams/class-diagram.mmd` | Unit: authorization-rejection tests (TC-AUTH-01–02) |
| NFR-012, NFR-013 | Auditability, retention | Audit Management module | `HLD/MAL4-HLD.md` §4.13, §4.11 | `LLD/MAL4-LLD.md` §5.2.5 | `05-diagrams/er-diagram.mmd` | Repository: atomic audit/state commit; no mutation API exists (TC-AUDIT-01) |
| NFR-015 | Scalability | Modular Monolith decision | `HLD/MAL4-HLD.md` §4.6 | — | `05-diagrams/deployment-architecture.mmd` | Not load-tested — architecture-defense discussion point only |

Rows left unresolved (NFR-004 idempotency, NFR-011 tenant isolation — conditional/deferred per `01/`, OQ-009 multi-reviewer, OQ-016 offline/sync) are intentionally not claimed as validated anywhere in this matrix.

---

## Known Weaknesses / Architecture Review Notes (Quality Gate)

Stated honestly, per the project's own standard of identifying weaknesses rather than hiding them:

1. **NFR-008/009 server-side-enforcement gap** — this architecture enforces authorization on-device, not via a deployed server. See `HLD/MAL4-HLD.md` §4.13 and §4.15. This is the single most likely point of challenge from judges reading the NFRs literally.
2. **Idempotency-key scheme (NFR-004) is undesigned** — the direction is sketched (`LLD/MAL4-LLD.md` §6.4's Gap note) but not finalized. A true race (not a retry-after-success) is not fully covered by the optimistic-concurrency mechanism alone.
3. **Multi-reviewer consensus (OQ-009) is unresolved** — the current design assumes single-approval. Adding consensus would require a new sub-state not currently in `LLD/MAL4-LLD.md` §6.1's transition table.
4. **Offline/multi-device sync (OQ-016) is unresolved** — the architecture is offline-capable by construction but explicitly not multi-device-capable (`HLD/MAL4-HLD.md` §4.15).
5. **Notification outbox/retry persistence is undesigned** — `NotificationGateway`'s exact retry/backoff policy is not specified (`LLD/MAL4-LLD.md` §5.2.6.G).
6. **Diagrams are rendered and visually verified** — both `docs/09-architecture-deliverables/MAL4-HLD.pdf` and `MAL4-LLD.pdf` embed all 11 diagrams as rendered PNGs (via mermaid-cli), each inspected page-by-page during generation, not just assumed to have rendered correctly.
7. **No Flutter/Dart code exists** — every class signature, pseudocode block, and test scenario in the LLD is a design artifact, not implementation evidence. Nothing here should be read as "already built" or "already tested."
8. **The workflow, data-design, and quality-attribute documentation is not yet finalized** — several cross-references in the HLD/LLD point to specifications still in progress; those remain open dependencies, not assumptions dressed up as facts.

## Sequencing Note for `docs/03-architecture-decisions/`

The High-Level Design already establishes the architecture-style, concurrency-model, and event-processing decisions that `ADR-001/002/003` are expected to formalize. Recommendation: those ADRs should be written as concise, structured decision records (context, alternatives considered, decision, consequences, risks) distilling what is already justified in the HLD, rather than re-deriving the analysis.
