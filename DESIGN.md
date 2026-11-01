# DESIGN.md — MAL4 MarTech Platform Design System

> **Standard:** `DESIGN.md` specification (inspired by `VoltAgent/awesome-design-md` and `nextlevelbuilder/ui-ux-pro-max-skill`)
> **Application:** Mobile Architecture Lab 4 (MAL4) MarTech Campaign Review & Approval Platform
> **Visual Archetype:** High-density, precision-engineered Architectural SaaS (inspired by Linear, Stripe, and Vercel design systems)

---

## 1. Visual Theme & Atmosphere

- **Aesthetic:** Clean, architectural, disciplined, typography-led. Emphasizes structured information density, clear visual hierarchies, and unambiguous state signifiers.
- **Mood:** Production-grade governance, deterministic reliability, and enterprise compliance. Avoids decorative fluff or low-contrast gradients.
- **Surface Elevation:** Subtle borders (`1px solid var(--border)`), gentle layering with `var(--card)` surfaces, and elevated state badges.

---

## 2. Color Tokens & Semantic Roles

The design system maps semantic tokens dynamically to support both dark mode and light mode seamlessly:

| Token Name | Dark Role / Hex | Light Role / Hex | Purpose |
|:---|:---|:---|:---|
| `--background` | `#0B0F17` (Deep Obsidian) | `#FFFFFF` (Pure White) | Root document surface |
| `--card` | `#111827` (Rich Slate) | `#FFFFFF` (Pure White) | Card containers & bento panels |
| `--card-hover` | `#1E293B` (Elevated Slate) | `#F1F5F9` (Subtle Gray) | Interactive component hover |
| `--border` | `rgba(255, 255, 255, 0.08)` | `#000000` / `#D1D5DB` | Structural dividers & box borders |
| `--foreground` | `#F9FAFB` (High Contrast White) | `#000000` (Pitch Black) | Primary text, titles & headers |
| `--muted-foreground` | `#94A3B8` (Cool Muted Slate) | `#4B5563` (Neutral Charcoal) | Supporting descriptions & secondary metadata |
| `--defense-red` | `#EF4444` (Crimson) | `#DC2626` (Ruby) | The Problem, rejected alternatives, Out-of-Scope |
| `--defense-green` | `#10B981` (Emerald) | `#16A34A` (Forest Green) | The Solution, chosen approaches, approved gates, In-Scope |
| `--defense-black` | `#000000` (Pitch Black) | `#000000` (Pitch Black) | Structural headings, architecture pillars, core frames |

---

## 3. Typography Rules

- **Display & Headings:** Clean sans-serif (`Inter`, `system-ui`, `-apple-system`, `sans-serif`) with tight tracking (`tracking-tight`), uppercase micro-labels (`tracking-wider text-xs font-semibold uppercase`).
- **Body Text:** Standard readability scale (`text-sm` to `text-base`), minimum floor of `12px` (`text-xs`), line-height $1.5$–$1.6$ for scannability.
- **Monospace & Metadata:** `ui-monospace`, `SFMono-Regular`, `Menlo`, `Monaco`, `monospace` for version IDs (`v1`, `v2`), state tokens (`PENDING_REVIEW`), and requirement codes (`FR-004`).

---

## 4. Layout & Bento Grid Architecture

- **Bento Grid Hierarchy:** Modular container cards grouped by functional domain:
  - Header & Brand Masthead (Full-width banner with status badges)
  - Core Problem & Proposed Solution (2-column contrast block)
  - Core 6-Step User Journey (6-card linear sequence with directional arrows)
  - Architectural Approach (3x2 or 2x3 bento grid of engineering pillars)
  - Scope & Boundaries (In-Scope vs. Out-of-Scope balance cards)
  - Quality Goals, SLOs, & Assumptions (Structured metric pill grid)
- **Grid Gap:** Standardized at `gap-3` (mobile/print) or `gap-4` (desktop).
- **Corner Radii:** Consistent `rounded-xl` (`12px`) for cards; `rounded-full` for badges.

---

## 5. Component Styling Standards

- **State Badges:**
  - `DRAFT`: Gray neutral (`bg-slate-500/10 text-slate-400 border border-slate-500/20`)
  - `PENDING REVIEW`: Blue pulse (`bg-blue-500/10 text-blue-400 border border-blue-500/20`)
  - `CHANGES REQUESTED`: Amber notice (`bg-amber-500/10 text-amber-400 border border-amber-500/20`)
  - `APPROVED`: Emerald verified (`bg-emerald-500/10 text-emerald-400 border border-emerald-500/20`)
  - `SCHEDULED`: Violet gate (`bg-purple-500/10 text-purple-400 border border-purple-500/20`)
  - `REJECTED`: Red termination (`bg-rose-500/10 text-rose-400 border border-rose-500/20`)
- **Step Cards:** Numbered pill indicators (`w-6 h-6 rounded-full flex items-center justify-center font-bold text-xs bg-primary/20 text-primary`).
- **Print Optimization:** Embedded `@media print` rules enforcing zero background shadows, crisp vector borders, and precise pagination within standard Letter / A4 physical pages.

