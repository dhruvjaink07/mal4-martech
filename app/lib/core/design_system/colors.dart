import 'package:flutter/material.dart';

/// Semantic Color Tokens for the MAL4 MarTech Platform
/// Directly derived from DESIGN.md (Architectural SaaS, Red/Green/Black defense palette).
class AppColors {
  AppColors._();

  // Defense Palette Standard (from DESIGN.md)
  static const Color defenseBlack = Color(0xFF000000); // Primary frames & structural text
  static const Color defenseGreen = Color(0xFF16A34A); // Verified gates, approvals, success
  static const Color defenseGreenLight = Color(0xFFDCFCE7); // Success badge background
  static const Color defenseRed   = Color(0xFFDC2626); // Rejections, material changes, errors
  static const Color defenseRedLight = Color(0xFFFEE2E2); // Error/rejection badge background

  // Dark Surface Tokens (Deep Obsidian & Rich Slate)
  static const Color darkBackground = Color(0xFF0B0F17); // Root canvas
  static const Color darkSurface    = Color(0xFF111827); // Card containers & panels
  static const Color darkElevated   = Color(0xFF1E293B); // Pressed / hover state
  static const Color darkBorder     = Color(0xFF1F2937); // Subtle 1px structural borders
  static const Color darkForeground = Color(0xFFF9FAFB); // High contrast text
  static const Color darkMutedText  = Color(0xFF94A3B8); // Supporting text & metadata

  // Light Surface Tokens
  static const Color lightBackground = Color(0xFFFFFFFF); // Canvas
  static const Color lightSurface    = Color(0xFFF8FAFC); // Card background
  static const Color lightElevated   = Color(0xFFF1F5F9); // Interactive cards
  static const Color lightBorder     = Color(0xFFE2E8F0); // Subtle 1px dividers
  static const Color lightForeground = Color(0xFF0F172A); // High contrast text
  static const Color lightMutedText  = Color(0xFF64748B); // Supporting text

  // Lifecycle State Badge Colors
  static const Color stateDraft      = Color(0xFF64748B);
  static const Color statePending    = Color(0xFF2563EB);
  static const Color stateChangesReq = Color(0xFFD97706);
  static const Color stateApproved   = Color(0xFF16A34A);
  static const Color stateScheduled  = Color(0xFF9333EA);
  static const Color stateRejected   = Color(0xFFDC2626);

  static const Color stateDraftBg       = Color(0xFFF1F5F9);
  static const Color stateDraftText     = Color(0xFF475569);
  static const Color statePendingBg     = Color(0xFFEFF6FF);
  static const Color statePendingText   = Color(0xFF1D4ED8);
  static const Color stateChangesReqBg  = Color(0xFFFEF3C7);
  static const Color stateChangesReqText= Color(0xFFB45309);
  static const Color stateApprovedBg    = Color(0xFFDCFCE7);
  static const Color stateApprovedText  = Color(0xFF15803D);
  static const Color stateScheduledBg   = Color(0xFFF3E8FF);
  static const Color stateScheduledText = Color(0xFF7E22CE);
  static const Color stateRejectedBg    = Color(0xFFFEE2E2);
  static const Color stateRejectedText  = Color(0xFFB91C1C);

  // Stage Indicator Colors
  static const Color stage1Creative   = Color(0xFF0284C7); // Sky blue
  static const Color stage2Compliance = Color(0xFFD97706); // Amber
  static const Color stage3Finance    = Color(0xFF059669); // Emerald
}

