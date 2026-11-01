---
name: flutter-ui-implementation
description: Use when implementing Flutter widgets, screens, animations, and presentation-layer controllers for the MAL4 MarTech Campaign Review & Approval mobile app. Implements feature-first UI components, reusable design system widgets, state rendering (loading/data/error), structured diff widgets, and stage approval action sheets following DESIGN.md with mock data. Trigger on requests like "code the campaign list screen", "implement the review action sheet", "build the diff viewer widget", "implement the Flutter UI", or "create the reusable design system widgets".
---

# Flutter UI Implementation — MAL4 MarTech Platform

Act as a **Senior Flutter UI Engineer** specialized in implementing clean, high-performance, pixel-perfect Flutter applications for enterprise workflows.

## 1. Purpose & Implementation Standard

Implement the presentation layer of the **MAL4 MarTech Campaign Review & Approval mobile app**. All code must:
- Follow **Feature-First Clean Architecture** (`features/<feature>/presentation/{controllers, screens, widgets}`).
- Strictly separate UI rendering from business logic (widgets are declarative; controllers/notifiers manage state; domain models provide data).
- Use reusable atomic design widgets adhering to `DESIGN.md` (Red, Green, Black palette with Slate surfaces).
- Interface exclusively with abstract domain repositories backed by local mock data sources.
- Support immediate evaluator persona switching (Marketer $\leftrightarrow$ Creative Reviewer $\leftrightarrow$ Compliance Officer $\leftrightarrow$ Finance Director) without requiring login flows.

---

## 2. When to Use This Skill

Activate this skill when:
- Writing Dart/Flutter widget code for screens, forms, dialogs, or sheets.
- Implementing the reusable design system component library in `lib/core/design_system/widgets/`.
- Building the 3-stage review progression UI (`StageProgressBar`, `ReviewActionSheet`).
- Coding the structured field diff viewer comparing version $vN$ against $vN+1$.
- Handling asynchronous UI states (`AsyncValue` / `ViewState`: loading, success, error, 409 conflict).
- Optimizing widget rebuilds, implementing `const` constructors, and handling keyboard insets.

---

## 3. Implementation Guidelines & Component Library

### 3.1 Reusable Design System Widgets (`lib/core/design_system/widgets/`)

All screens must be composed from standardized atomic widgets:

1. **`StatusBadge`:** Renders the campaign state pill with appropriate color token and icon:
   ```dart
   class StatusBadge extends StatelessWidget {
     final CampaignState state;
     final int? stageIndex;
     const StatusBadge({super.key, required this.state, this.stageIndex});
     // Renders gray for Draft, blue pulse for Pending (Stage k), emerald for Approved, etc.
   }
   ```

2. **`StageProgressBar`:** Visual multi-step breadcrumb showing the 3 sequential gates:
   - Stage 1: Creative & Brand
   - Stage 2: Legal & Compliance
   - Stage 3: Finance & DOA
   - Highlights completed stages with green checkmarks, the active stage with high-contrast borders, and pending stages as muted.

3. **`AppButton`:** High-contrast touch target ($\ge 48\text{dp}$ height) with primary (Forest Green), secondary (Slate Elevated), and destructive (Crimson) variants.

4. **`AppCard`:** Bento-style container with `1px` subtle border, `12px` rounded corners, and slate elevation surface.

5. **`FieldDiffTile`:** Displays a modified field during revision review:
   - Green background for newly added/modified value.
   - Red strikethrough for previous version value.
   - Tag indicating whether the change is `MATERIAL` (triggers re-approval) or `NON_MATERIAL`.

6. **`PersonaSwitcherBar`:** Persistent top-bar widget allowing instant switching between:
   - `Marketer (Alex)`
   - `Creative Reviewer (Elena - Stage 1)`
   - `Compliance Officer (Marcus - Stage 2)`
   - `Finance Director (Sophia - Stage 3)`

---

## 4. Key Screen Implementations

### 4.1 Screen 1: `CampaignListScreen`
- **Location:** `lib/features/campaign_management/presentation/screens/campaign_list_screen.dart`
- **Features:**
  - Segmented tab bar: `All Campaigns`, `My Drafts`, `Pending Review`, `Approved & Scheduled`.
  - Filter chips for Stage 1, Stage 2, Stage 3 review queues.
  - Campaign summary cards displaying: Name, StatusBadge, Budget with DOA Tier, Schedule Window, and Version tag (`v1`).
  - Floating Action Button to create a new campaign (enabled for Marketer persona).

### 4.2 Screen 2: `CampaignDetailScreen`
- **Location:** `lib/features/campaign_management/presentation/screens/campaign_detail_screen.dart`
- **Features:**
  - Header with `StageProgressBar` showing active progression.
  - Metadata Bento Grid: Objective, Target Audience chips, Budget card, Schedule window, Channel assets.
  - Anti-Self-Approval Banner: If current persona matches `submitted_by_id`, an info notice states: *"Self-Review Disabled: Submitter cannot review this campaign."*
  - Docked bottom action bar calling `ReviewActionSheet` for authorized reviewers.

### 4.3 Screen 3: `ReviewActionSheet` (Modal Bottom Sheet)
- **Location:** `lib/features/multi_stage_review/presentation/widgets/review_action_sheet.dart`
- **Features:**
  - Contextual to the active persona and stage:
    - Stage 1: "Approve Creative & Advance to Compliance"
    - Stage 2: "Approve Compliance & Advance to Finance"
    - Stage 3: "Grant Final Financial Approval (Clears Scheduling Gate)"
  - "Request Changes" button: Opens a modal textfield requiring minimum 10 characters of feedback notes.
  - "Reject Campaign" button: Destructive button requiring mandatory rejection justification.
  - Automatic `Idempotency-Key` generation on submit to support retry resilience.

### 4.4 Screen 4: `StructuredDiffViewerScreen`
- **Location:** `lib/features/revision_and_diff/presentation/screens/structured_diff_viewer_screen.dart`
- **Features:**
  - Side-by-side or stacked diff view comparing previous snapshot $vN$ with revised snapshot $vN+1$.
  - "Reviewer Feedback Addressed" card showing the previous stage's request comments.
  - Highlighting modified fields (Budget delta, Audience changes, Disclaimer updates).
  - Materiality badge for each modified field.

### 4.5 Screen 5: `AuditTimelineScreen`
- **Location:** `lib/features/audit_and_governance/presentation/screens/audit_timeline_screen.dart`
- **Features:**
  - Vertical chronological timeline of all lifecycle events.
  - Event tiles showing: Timestamp, Action (`Stage1Approved`, `ChangesRequested`), Actor with role badge, and cryptographic snapshot hash snippet (`0x9f1a...`).

---

## 5. State Handling & Presentation Patterns

Controllers must expose strongly-typed, immutable UI state:

```dart
// Example using Riverpod AsyncValue or sealed state classes
@freezed
class CampaignDetailState with _$CampaignDetailState {
  const factory CampaignDetailState.loading() = _Loading;
  const factory CampaignDetailState.loaded(Campaign campaign, List<StageApproval> approvals) = _Loaded;
  const factory CampaignDetailState.conflict({
    required String message,
    required Campaign currentCampaign,
  }) = _Conflict;
  const factory CampaignDetailState.error(String errorMessage) = _Error;
}
```

- **Conflict Handling (409):** When a controller catches a `ConflictFailure` (OCC mismatch), it transitions to `CampaignDetailState.conflict`, prompting the user to refresh the latest state without data loss.

---

## 6. Constraints & Exclusions

- **DO NOT Implement Login/Signup Screens:** The prototype must start immediately on the `CampaignListScreen` with the mock `PersonaSwitcherBar` mounted at the top.
- **DO NOT Implement Firebase Auth or Guards:** No Firebase imports or authentication redirection logic.
- **DO NOT Connect to External Cloud APIs:** Wire controllers strictly to the mock repositories defined by `flutter-architect`.
- **Preserve Existing Code:** Do not modify non-Flutter architecture docs in `docs/` during UI implementation.

---

## 7. Expected Output Artifacts

When executing tasks under this skill:
1. Production-ready, null-safe Dart files with `const` constructors and thorough layout responsiveness.
2. Complete widget implementations in `lib/core/design_system/widgets/`.
3. Fully functional screens in `lib/features/<feature>/presentation/screens/`.
4. Interactive presentation controllers wired to mock repositories via Riverpod or standard ChangeNotifier.

