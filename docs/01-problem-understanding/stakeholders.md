# Stakeholders

> **Document Status:** Draft v1.0
> **Last Updated:** 2026-11-01
> **Owner:** Domain Research & Requirements Lead
> **Traces to:** [Problem Statement](problem-statement.md)

---

## Overview

Stakeholder identification is based on research into real-world campaign management platforms (HubSpot, Marketo, Salesforce Marketing Cloud, Braze, Mailchimp) and enterprise marketing team structures. Roles are scoped to the Campaign Review & Approval domain — not a full MarTech stack.

For the MAL4 challenge, we distinguish between:

- **Primary stakeholders:** Direct users of the system who interact with the campaign lifecycle.
- **Secondary stakeholders:** People or systems that are affected by or influence the campaign workflow but do not directly operate it.
- **System actors:** External systems that integrate with the campaign management system at its boundary.

---

## Primary Stakeholders

### ST-001: Marketer (Campaign Creator)

**Also known as:** Campaign Manager, Content Creator, Digital Marketer

**Description:** The person who creates, edits, and submits campaigns for review. In smaller teams, one person may handle all content and campaign setup. In larger teams, this may be split between a Campaign Manager (strategy/setup) and Content Creators (copy/creative).

**Responsibilities:**
- Create new campaign proposals with required metadata (name, objective, audience, budget, schedule, content).
- Edit campaigns in Draft state.
- Submit campaigns for review when ready.
- Respond to reviewer feedback by revising the campaign.
- Re-submit revised campaigns for another review cycle.
- View the current status of their campaigns.

**Key concerns:**
- Fast, intuitive workflow for creating and submitting campaigns.
- Clear visibility into where a campaign is in the approval process.
- Specific, actionable feedback when changes are requested.
- Assurance that approved campaigns proceed to scheduling without delays.
- Ability to track revision history and understand what changed between versions.

**Interaction frequency:** Daily to multiple times per day.

---

### ST-002: Reviewer (Approver)

**Also known as:** Marketing Manager, Brand Manager, Compliance Officer, Creative Director

**Description:** An authorised person who evaluates submitted campaigns and makes approval decisions. In real-world platforms, this role may be filled by different people depending on the review stage — a brand manager for creative review, a legal/compliance officer for regulatory review, or a finance lead for budget review.

For the initial architecture, we model a single Reviewer role with permissions to approve, reject, or request changes. The architecture should support future differentiation (e.g., separate compliance and creative reviewers).

**Responsibilities:**
- Receive notifications when campaigns are submitted for review.
- Review campaign content, audience, budget, and schedule.
- Approve campaigns that meet standards and policies.
- Reject campaigns that are fundamentally unsuitable.
- Request changes with specific feedback when modifications are needed.
- Ensure that the version being reviewed is the current version.

**Key concerns:**
- Seeing only campaigns that require their attention (not noise from irrelevant submissions).
- Confidence that the campaign has not been modified since submission (version integrity).
- Ability to compare the current version with previous versions when reviewing revisions.
- Clear audit trail of their decisions for accountability.
- No ambiguity about whether their approval applies to the current version.
- Efficient batch review workflow when multiple campaigns are pending.

**Interaction frequency:** Daily; may have bursts of multiple reviews.

---

### ST-003: System Administrator

**Also known as:** Marketing Operations Lead, MarTech Admin, Platform Admin

**Description:** The person responsible for configuring and maintaining the campaign management system. Sets up approval workflows, manages user roles and permissions, configures notification rules, and monitors system health.

**Responsibilities:**
- Configure approval workflow rules (who can approve, how many approvals required).
- Manage user accounts and role assignments.
- Define which campaign changes trigger re-approval.
- Configure notification channels and escalation policies (future scope).
- Monitor system activity and audit logs.
- Troubleshoot workflow issues (stuck campaigns, failed notifications).

**Key concerns:**
- Ability to configure workflows without code changes.
- Visibility into system health and bottlenecks.
- Access to audit logs for governance and compliance reporting.
- User management that supports the organisation's team structure.
- System reliability — the admin is first to hear about outages.

**Interaction frequency:** Weekly for configuration; ad hoc for troubleshooting.

---

## Secondary Stakeholders

### ST-004: Marketing Leadership (CMO / VP / Director)

**Description:** Senior leaders who oversee the marketing function. They do not typically interact with the campaign system directly but rely on its outputs for governance and decision-making.

**Concerns:**
- Campaigns go through proper governance before publication.
- Budget commitments are authorised by appropriate personnel.
- Regulatory and brand risk is managed.
- Visibility into campaign pipeline and approval bottlenecks (future: reporting/dashboards).

**Interaction:** Indirect — through reports, dashboards, and escalations.

---

### ST-005: Legal and Compliance Team

**Description:** Reviews campaigns for regulatory compliance (GDPR, CAN-SPAM, industry-specific regulations). In regulated industries (financial services, healthcare, pharma), this is a mandatory approval gate.

**Concerns:**
- Access to review campaign content, disclaimers, and audience targeting.
- Assurance that compliance-approved content is not modified after their sign-off.
- Immutable audit trail proving their review was completed.
- Re-approval is triggered when legally material changes occur.

**Interaction:** Per campaign, when compliance review is required. May be integrated as a specialised reviewer role in a multi-stage approval workflow (future scope).

> **Note:** For the initial architecture, Legal/Compliance is modelled as a specialisation of the Reviewer role (ST-002). If multi-stage approvals are implemented, they become a distinct approval stage.

---

### ST-006: Finance / Budget Owner

**Description:** Approves campaign budget allocations. In SOX-compliant organisations, marketing spend above certain thresholds requires financial authorisation with delegation-of-authority controls.

**Concerns:**
- Budget amounts in campaigns are accurate and within authorised limits.
- Budget changes to approved campaigns are flagged and require re-authorisation.
- Audit trail connecting budget approval to the specific campaign version.

**Interaction:** Per campaign, when budget approval is required. Initially modelled as a Reviewer concern.

---

## System Actors (External Systems at the Boundary)

These are not human stakeholders but systems that interact with the campaign management system. They are listed here to define the system boundary.

| Actor | Interaction | Direction |
|---|---|---|
| **Notification Service** | Sends alerts when campaigns are submitted, approved, rejected, or when changes are requested | Outbound |
| **Scheduling System** | Receives approved campaigns for time-based delivery scheduling | Outbound |
| **Identity Provider** | Authenticates users and provides role/permission claims | Inbound |
| **Asset/Content Storage** | Stores and retrieves campaign content assets (images, copy, documents) | Bidirectional |
| **Analytics/Reporting** | Consumes campaign lifecycle events for dashboards and reporting | Outbound |

> **Architecture Lead input needed:** The system boundary and integration contracts with these actors will be defined in the System Context document (02-solution-design/system-context.md).

---

## Stakeholder Concerns Matrix

| ID | Stakeholder | Role | Key Concerns | Priority |
|---|---|---|---|---|
| ST-001 | Marketer | Campaign Creator | Usability, workflow transparency, revision tracking | **High** |
| ST-002 | Reviewer | Approver | Version integrity, decision auditability, review efficiency | **High** |
| ST-003 | System Admin | Platform Admin | Configuration flexibility, system health, audit access | **High** |
| ST-004 | Marketing Leadership | Executive Sponsor | Governance, budget control, risk management | **Medium** |
| ST-005 | Legal/Compliance | Compliance Reviewer | Regulatory compliance, immutable audit trail, post-approval change detection | **Medium** |
| ST-006 | Finance | Budget Owner | Budget accuracy, authorisation limits, spend audit trail | **Medium** |

---

## Stakeholder Interaction Model

```
┌─────────────────────────────────────────────────────────────────┐
│                   Campaign Review & Approval System              │
│                                                                  │
│  ┌──────────┐    submits     ┌──────────┐    configures          │
│  │ Marketer │───────────────▶│ Campaign │◀──────────────┐        │
│  │ (ST-001) │◀───────────────│  Engine  │               │        │
│  └──────────┘  feedback/     └────┬─────┘         ┌─────┴──────┐ │
│                 status            │               │ Sys Admin  │ │
│                              reviews              │  (ST-003)  │ │
│                                   │               └────────────┘ │
│  ┌──────────┐    decides     ┌────▼─────┐                        │
│  │ Reviewer │◀───────────────│  Review  │                        │
│  │ (ST-002) │───────────────▶│  Queue   │                        │
│  └──────────┘  approve/      └──────────┘                        │
│                reject/                                           │
│                request changes                                   │
└─────────────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
  ┌──────────────┐             ┌──────────────┐
  │ Notification │             │  Scheduling  │
  │   Service    │             │    System    │
  └──────────────┘             └──────────────┘
```

---

## Assumptions

| ID | Assumption | Traces to |
|---|---|---|
| A-003 | The initial architecture models a single reviewer role. Multi-stage approval (creative → compliance → budget) is a future extension. | OQ-001 |
| A-007 | All primary stakeholders authenticate through a shared identity provider with role-based access control. | — |
| A-008 | The Marketer and Reviewer roles are distinct — a person may hold both roles, but cannot review their own submissions. | Industry best practice (separation of duties) |
| A-009 | Notification delivery is best-effort; failure to notify does not block the approval workflow. | OQ — needs Architecture Lead input |

---

## Open Questions

| ID | Question | Traces to |
|---|---|---|
| OQ-001 | Should the system support multi-stage approvals in the initial design? This affects how Reviewer (ST-002), Legal (ST-005), and Finance (ST-006) are modelled. | Problem Statement OQ-001 |
| OQ-007 | Can a reviewer delegate their review to another authorised person? | Escalation and delegation policy |
| OQ-008 | Should the system enforce that a submitter cannot approve their own campaign, or is this a configurable policy? | Separation of duties |
| OQ-009 | Are there scenarios where multiple reviewers must all approve (consensus), or is a single authorised approval sufficient? | Approval policy design |
