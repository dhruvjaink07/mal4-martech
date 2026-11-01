---
name: flutter-architect
description: Use when architecting, structuring, or reviewing the Flutter application structure for the MAL4 MarTech Campaign Review & Approval mobile prototype. Guides feature-first directory layout, clean separation of presentation/domain/data layers, state management contracts (Riverpod/BLoC), mock repository abstractions, immutable models, and offline-first data flows without premature backend coupling. Trigger on requests like "structure the Flutter app", "design feature folders", "define domain entities and repository interfaces", or "set up presentation/domain/data layers".
---

# Flutter Architect — MAL4 MarTech Platform

Act as a **Principal Mobile Flutter Architect** for the MAL4 MarTech Campaign Review & Approval mobile prototype.

## 1. Purpose & Scope

Guide the structural design, layer boundaries, and state contracts of the Flutter mobile prototype. The architecture must guarantee:
- **Feature-First Modularity:** Code is organized by domain feature (`campaign_creation`, `review_flow`, `revision_diff`, `audit_trail`, `scheduling_gate`), not by generic technical type folders.
- **Strict Separation of Concerns:** Unidirectional data flow cleanly separating Presentation, Domain, and Data layers.
- **Decoupled Persistence & Mocking:** Domain logic depends exclusively on abstract repository interfaces; concrete mock repositories provide deterministic in-memory/local sample data for the prototype without premature backend coupling.
- **Workflow State Machine Alignment:** The mobile state architecture directly reflects the 3-Stage Sequential Approval Pipeline (`Stage 1: Creative` $\rightarrow$ `Stage 2: Compliance` $\rightarrow$ `Stage 3: Finance`) and automated Material Change Invalidation (`FR-014`).

---

## 2. When to Use This Skill

Activate this skill when:
- Defining or scaffolding the Flutter directory structure and module layout.
- Designing domain entities, value objects, and business invariant contracts.
- Defining abstract repository interfaces and mock repository implementations.
- Establishing state management patterns (Riverpod `AsyncNotifier` / BLoC) and UI state models.
- Reviewing PRs or code to ensure dependencies strictly point inward (Presentation $\rightarrow$ Domain $\leftarrow$ Data).
- Structuring offline caching, optimistic updates, and conflict handling on mobile.

---

## 3. Engineering Guidelines & Layering Architecture

### 3.1 Feature-First Directory Layout
The application follows a strict feature-first structure:

```
lib/
├── app.dart                           # MaterialApp, global theme & router configuration
├── main.dart                          # App bootstrap & mock dependency injection container
│
├── core/                              # Cross-cutting foundational modules
│   ├── constants/                     # Global constants, API paths, stage definitions
│   ├── design_system/                 # Design tokens (colors, typography, spacing) matching DESIGN.md
│   │   ├── colors.dart                # Defense Red, Defense Green, Defense Black, surfaces
│   │   ├── typography.dart            # Inter typography scale and weights
│   │   ├── theme.dart                 # ThemeData for Light and Dark modes
│   │   └── widgets/                   # Universal atomic widgets (AppButton, AppCard, StatusBadge)
│   ├── error/                         # Failure classes, exceptions, and user-facing messages
│   │   └── failures.dart              # ConflictFailure (409), ValidationFailure (400), SoDFailure (403)
│   └── utils/                         # SHA-256 canonical hashing, currency and date formatters
│
└── features/                          # Domain feature modules
    ├── campaign_management/           # Proposal creation, draft editing, and submission
    │   ├── data/                      # DTOs, mappers, mock repositories
    │   ├── domain/                    # Campaign aggregate, value objects, repository contracts
    │   └── presentation/              # Controllers, screens, proposal form widgets
    │
    ├── multi_stage_review/            # 3-Stage Sequential Review Pipeline
    │   ├── data/                      # Mock review data, stage decision DTOs
    │   ├── domain/                    # StageApproval entity, review invariants, ReviewRepository
    │   └── presentation/              # ReviewQueueScreen, StageDetailScreen, ReviewActionSheet
    │
    ├── revision_and_diff/             # Revisions, side-by-side diffing, and material change triggers
    │   ├── data/                      # Diff calculation service, snapshot DTOs
    │   ├── domain/                    # FieldDiff entity, materiality evaluation logic
    │   └── presentation/              # StructuredDiffViewer, revision comparison cards
    │
    └── audit_and_governance/          # Immutable timeline and scheduling gate verification
        ├── data/                      # Mock audit events and outbox logs
        ├── domain/                    # AuditEvent entity, scheduling gate invariants
        └── presentation/              # AuditTimelineScreen, SchedulingGateWidget
```

---

### 3.2 Layer Responsibilities & Allowed Dependencies

```
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   Screens, Widgets, Controllers (Riverpod / BLoC)      │
│   - Consumes Domain Entities and ViewState             │
│   - Dispatches user intents to Use Cases/Controllers   │
└───────────────────────────┬────────────────────────────┘
                            │ depends on (points down)
                            ▼
┌────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                      │
│   Entities, Value Objects, Repository Interfaces       │
│   - PURE DART: Zero Flutter UI, Zero Network imports   │
│   - Holds business invariants (Anti-Self-Approval, OCC)│
└───────────────────────────▲────────────────────────────┘
                            │ implements (points up/in)
┌───────────────────────────┴────────────────────────────┐
│                       DATA LAYER                       │
│   DTOs, Mappers, Mock Repositories, Local Sources      │
│   - Implements Domain Repository interfaces            │
│   - Translates local JSON/memory state to Entities     │
└────────────────────────────────────────────────────────┘
```

1. **Domain Layer (The Core):**
   - **Zero external framework dependencies** (no `flutter/material.dart`, no HTTP packages).
   - Contains immutable entities (`Campaign`, `CampaignSnapshot`, `StageApproval`).
   - Contains immutable value objects (`BudgetAllocation`, `AudienceCriteria`, `ScheduleWindow`).
   - Defines abstract repository interfaces (`CampaignRepository`, `ReviewRepository`).
   - Enforces core invariants:
     - Anti-Self-Approval: `submittedById != reviewerId`.
     - Monotonic progression: Stage $k+1$ requires Stage $k$ approval on the active snapshot.
     - Scheduling verification: Requires 3 valid stage approvals matching `snapshotHash`.

2. **Data Layer (The Implementation):**
   - Contains Data Transfer Objects (DTOs) with `fromJson` and `toJson`.
   - Contains Mappers translating between DTOs and Domain Entities.
   - Provides `MockCampaignRepository` and `MockReviewRepository` seeded with realistic MarTech campaign samples.
   - Implements simulated async latency ($100\text{--}300\text{ms}$) and simulated optimistic locking collisions to test resilience.

3. **Presentation Layer (The UI State):**
   - Implements immutable UI state classes representing:
     - `InitialState`, `LoadingState`, `LoadedState<T>`, `ErrorState`, `ConflictState` (409).
   - Controllers/Notifiers call repositories and expose reactive state streams.
   - Widgets are strictly declarative and render according to the state model.

---

## 4. State Management Contracts

For Riverpod (recommended for clean dependency injection and testability):

```dart
// Domain Repository Contract
abstract class CampaignRepository {
  Future<List<Campaign>> getCampaigns({CampaignState? filterState, int? filterStage});
  Future<Campaign> getCampaignById(String id);
  Future<Campaign> createDraft(CampaignDraftInput input);
  Future<Campaign> updateDraft(String id, int expectedVersion, CampaignDraftInput input);
  Future<Campaign> submitForReview(String id, int expectedVersion, String submitterId);
  Future<Campaign> advanceStage({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String reviewerRole,
    String? notes,
  });
  Future<Campaign> requestChanges({
    required String campaignId,
    required int expectedVersion,
    required int currentStage,
    required String reviewerId,
    required String feedback,
  });
  Future<Campaign> scheduleCampaign(String id, int expectedVersion, String actorId);
}
```

---

## 5. Constraints & Important Exclusions

- **NO Authentication Implementation:** Do NOT implement Firebase Auth, username/password screens, or authentication guards. The app operates with a simple top-bar **Role Switcher** widget allowing judges to toggle between:
  - `Marketer (Alex - Submitter)`
  - `Creative Reviewer (Elena - Stage 1)`
  - `Compliance Officer (Marcus - Stage 2)`
  - `Finance Director (Sophia - Stage 3)`
- **NO Premature Cloud Backend:** Do NOT introduce AWS Amplify, Firebase Cloud Firestore, Supabase, or live REST endpoints before the architecture decision records (ADRs) are completed.
- **Mock-First Architecture:** All data operations must resolve against clean in-memory mock repositories with realistic pre-populated marketing campaigns.

---

## 6. Expected Output Artifacts

When executing tasks under this skill:
1. Complete Dart file structures conforming to `features/<feature>/{presentation,domain,data}`.
2. Abstract repository interfaces and domain aggregate models with invariant assertions.
3. Fully typed mock repository implementations with sample marketing campaigns in various lifecycle states (`Draft`, `Stage 1 Creative`, `Stage 2 Compliance`, `Stage 3 Finance`, `Approved`, `Changes Requested`).
4. Architecture verification checklists confirming inward dependency flow and zero UI imports in the domain layer.

