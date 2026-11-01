---
name: mobile-ui-ux-designer
description: Use when designing mobile UI/UX layouts, wireframes, component design systems, and interaction patterns for the MAL4 MarTech Campaign Review & Approval Flutter app. Applies high-density architectural SaaS aesthetics, tokenized styling from DESIGN.md, mobile UX heuristics, touch-target ergonomics, and 3-stage review visual workflows based on ui-ux-pro-max and awesome-design-md. Trigger on requests like "design the mobile screens", "create Flutter theme tokens", "wireframe the review workflow", "design the structured diff viewer", or "establish mobile UI/UX guidelines".
---

# Mobile UI/UX Designer — MAL4 MarTech Platform

Act as a **Staff Mobile UI/UX Designer** specialized in enterprise MarTech workflows, design systems, and mobile ergonomics for the MAL4 hackathon.

## 1. Purpose & Design Philosophy

Design a high-density, precision-engineered mobile interface for the **Campaign Review & Approval Platform**. The design translates complex enterprise governance, multi-stage approval pipelines, and cryptographic snapshot verification into an effortless, scannable, mobile-first experience.

### Core Visual Archetype (from `DESIGN.md`)
- **Aesthetic:** High-density, typography-led **Architectural SaaS** (inspired by Linear, Stripe Dashboard, and Vercel).
- **Atmosphere:** Clean, disciplined, deterministic, governance-focused. Avoids decorative clutter, low-contrast gradients, and frivolous illustrations.
- **Palette Standard:** Strict **Red, Green, and Black** design system with neutral slate surfaces for maximum contrast and legibility under varying lighting conditions.
- **Design Intelligence:** Grounded in the `VoltAgent/awesome-design-md` standard for markdown design systems and `nextlevelbuilder/ui-ux-pro-max-skill` principles for cognitive load reduction and mobile touch ergonomics.

---

## 2. When to Use This Skill

Activate this skill when:
- Establishing or updating the Flutter theme tokens (`AppTheme`, `AppColors`, `AppTypography`, `AppSpacing`).
- Designing screen layouts for the campaign lifecycle (`CampaignList`, `CampaignDetail`, `ReviewActionSheet`, `StructuredDiffViewer`, `AuditTimeline`).
- Creating component specs for reusable widgets (`StatusBadge`, `StageProgressBar`, `FieldDiffTile`, `AuditTimelineTile`).
- Defining mobile interaction patterns (one-tap approval, swipe gestures, contextual bottom sheets, modal feedback forms).
- Reviewing UI implementations for visual hierarchy, typography scannability, touch targets ($\ge 48\times 48\text{dp}$), and contrast compliance (WCAG AAA).

---

## 3. Design System Tokens & Flutter Theme Specifications

### 3.1 Color Palette & Semantic Roles (from `DESIGN.md`)

```dart
class AppColors {
  // Brand & Defense Core
  static const Color defenseBlack = Color(0xFF000000); // Headings, structural frames
  static const Color defenseGreen = Color(0xFF16A34A); // Approvals, success gates, active stages
  static const Color defenseRed   = Color(0xFFDC2626); // Rejections, material changes, errors

  // Dark Theme Surfaces (Obsidian & Slate)
  static const Color darkBackground = Color(0xFF0B0F17); // Root canvas
  static const Color darkSurface    = Color(0xFF111827); // Card surfaces & bottom sheets
  static const Color darkElevated   = Color(0xFF1E293B); // Interactive card hover / pressed
  static const Color darkBorder     = Color(0xFF1F2937); // Subtle structural borders (1px)
  static const Color darkForeground = Color(0xFFF9FAFB); // High contrast text
  static const Color darkMutedText  = Color(0xFF94A3B8); // Secondary descriptions & metadata

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface    = Color(0xFFF8FAFC);
  static const Color lightBorder     = Color(0xFFE2E8F0);
  static const Color lightForeground = Color(0xFF0F172A);
  static const Color lightMutedText  = Color(0xFF64748B);

  // Lifecycle State Badge Tokens
  static const Color stateDraft      = Color(0xFF64748B); // Slate neutral
  static const Color statePending    = Color(0xFF2563EB); // Blue pulse
  static const Color stateChangesReq = Color(0xFFD97706); // Amber alert
  static const Color stateApproved   = Color(0xFF16A34A); // Emerald verified
  static const Color stateScheduled  = Color(0xFF9333EA); // Purple execution gate
  static const Color stateRejected   = Color(0xFFDC2626); // Rose termination
}
```

---

### 3.2 Typography Hierarchy

- **Display & Section Titles:** Inter or system sans-serif with tight tracking (`tracking-tight`), `w800` or `w900` font weight.
- **Body & Captions:** High-legibility sans-serif with minimum font size of `12pt` (`14pt` for primary labels) and line-height of $1.4\text{--}1.5$.
- **Monospace Metadata:** `ui-monospace`, `SFMono-Regular`, or `Roboto Mono` for version tokens (`v1`, `v2`), SHA-256 hashes (`0x9f1a...`), currency amounts, and state codes (`PENDING_REVIEW`).

---

## 4. Key Screen Wireframes & Component Workflows

### 4.1 Global Mock Role Switcher (Top App Bar)
To satisfy the constraint **No Firebase Auth / No Login Screens**, every screen features a clean, elevated top bar allowing evaluators to switch personas instantly:

```
┌─────────────────────────────────────────────────────────────┐
│ [MAL4 MarTech]  Persona: [ Creative Reviewer (Stage 1) ▼ ]  │
├─────────────────────────────────────────────────────────────┤
│ Switch to: Marketer | Legal (Stage 2) | Finance (Stage 3)   │
└─────────────────────────────────────────────────────────────┘
```

---

### 4.2 Multi-Stage Review Pipeline Tracker Component
Displayed prominently at the top of the `CampaignDetailScreen`:

```
┌─────────────────────────────────────────────────────────────┐
│  PIPELINE PROGRESSION (Version v1)                          │
│                                                             │
│  [ (✓) Creative ] ───▶ [ (●) Compliance ] ───▶ [ ( ) Finance] │
│      Stage 1                Stage 2               Stage 3   │
│   Brand Approved        Action Required         Spend Gate  │
└─────────────────────────────────────────────────────────────┘
```
- **Visual Indicators:**
  - `Completed`: Solid green circle with white checkmark.
  - `Active`: Blue or pulsing green border indicating current evaluation gate.
  - `Pending`: Muted gray outline.
  - `Rejected/Changes`: Crimson warning icon.

---

### 4.3 Structured Field Diff Viewer (`FR-011`, `revision-workflow.md`)
When reviewing a revised campaign ($v2, v3$), reviewers need instant side-by-side verification:

```
┌─────────────────────────────────────────────────────────────┐
│  REVISION DIFF: v1 ──▶ v2 (Snapshot: 0x4c2b)                │
├─────────────────────────────────────────────────────────────┤
│  Feedback Addressed:                                        │
│  "Reduced budget by 15% and removed EU audience per legal"  │
├─────────────────────────────────────────────────────────────┤
│  [!] BUDGET AMOUNT (Material Change)                        │
│  [-] $15,000.00 USD  (v1)                                   │
│  [+] $12,500.00 USD  (v2 - Approved DOA Tier 1)             │
├─────────────────────────────────────────────────────────────┤
│  [!] TARGET AUDIENCE (Material Change)                      │
│  [-] US & EU All Registered Users                           │
│  [+] US Only, Opted-In Loyalty Members                      │
├─────────────────────────────────────────────────────────────┤
│  [i] UTM CAMPAIGN (Non-Material Change)                     │
│  [-] spring_26_promo ──▶ [+] spring_26_loyalty              │
└─────────────────────────────────────────────────────────────┘
```

---

### 4.4 Ergonomic Contextual Action Sheet (Bottom Docked)
Following mobile thumb-zone ergonomics, all primary review actions reside in a persistent bottom sheet:

```
┌─────────────────────────────────────────────────────────────┐
│  Stage 2 Action: Legal & Compliance Audit                   │
├─────────────────────────────────────────────────────────────┤
│  [  Request Changes  ]  [      Approve Stage 2      ]       │
│  (Amber Outline)        (Solid Forest Green - 52dp)         │
├─────────────────────────────────────────────────────────────┤
│  [ Reject Campaign ]  (Subtle Red Text Button)              │
└─────────────────────────────────────────────────────────────┘
```
- **Touch Target:** Minimum height of `52dp` for primary approval button; `48dp` for secondary actions.
- **Haptic Feedback:** Subtle medium haptic vibration upon tapping Approve or Request Changes.

---

## 5. Mobile UX Heuristics & Ergonomic Guidelines

1. **Thumb-Zone Optimization:** Critical decision buttons (Approve, Request Changes) must be placed in the bottom third of the screen, easily reachable with one-handed thumb navigation.
2. **Scannable Information Hierarchy:** Use bento cards with distinct label-value pairs:
   - Primary data (Campaign Name, Status Badge, Budget) at the top.
   - Secondary parameters (Audience, Dates, Channels) in middle collapsible sections.
   - Audit trail and technical hashes placed in a tabbed lower container.
3. **Unambiguous Anti-Self-Approval Feedback:** If a Marketer views their own campaign while switched to a Reviewer persona, the bottom action buttons are disabled with an explicit informative banner:
   > ℹ️ *Separation of Duties Policy: You cannot review or approve a campaign you submitted.*
4. **Instant Feedback on Retries:** If a network timeout occurs, tapping retry displays an inline micro-spinner rather than freezing the screen, and idempotency guarantees prevent duplicate popups.

---

## 6. Constraints & Exclusions

- **NO Authentication / Login Screens:** Do NOT design login, signup, password reset, or OTP verification screens. Persona selection is handled entirely via the top-bar mock switcher.
- **Strict adherence to DESIGN.md:** Never use random hex colors or unapproved pastel palettes. Stick strictly to Defense Red, Defense Green, Defense Black, and Slate card surfaces.

---

## 7. Expected Output Artifacts

When executing tasks under this skill:
1. Complete Flutter theme files (`lib/core/design_system/theme.dart`, `colors.dart`, `typography.dart`).
2. Production-ready reusable UI widgets (`StatusBadge`, `StageProgressBar`, `FieldDiffTile`, `AuditTimelineTile`).
3. Layout blueprints and widget composition trees for all key screens.
4. Mobile usability verification checklists (touch targets $\ge 48\text{dp}$, contrast ratios, thumb-zone placement).

