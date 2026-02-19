import 'package:flutter/material.dart';

/// ANIGMAA Color System v1.0
///
/// AGENTS: Always use these tokens. NEVER hardcode hex colors.
/// See BLUEPRINT/12_design_system.md for full usage rules.
///
/// KEY DECISION: There are TWO lime colors with different purposes:
///   - [secondary]     #BBC863 Warm Lime  → primary accent (most UI elements)
///   - [electricLime]  #CCFF00 Electric   → FAB only (high-energy CTA)
class AppColors {
  // ─── Primary Brand Colors ────────────────────────────────────────────────

  /// Rich Black — primary buttons, active states, main text
  static const Color primary = Color(0xFF111111);

  /// Warm Lime — PRIMARY accent color.
  /// Use for: icons, tab indicators, borders, interactive states, event cards,
  /// profile elements, action buttons, progress indicators.
  /// AGENTS: This replaces the old #CCFF00. Use AppColors.secondary everywhere.
  static const Color secondary = Color(0xFFBBC863);

  /// Electric Lime — HIGH-ENERGY accent. FAB ONLY.
  /// DO NOT use for general UI. Reserved exclusively for floating action button.
  static const Color electricLime = Color(0xFFCCFF00);

  /// Pure White
  static const Color white = Color(0xFFFFFFFF);

  // ─── Accent Surfaces ─────────────────────────────────────────────────────
  // Semi-transparent secondary for backgrounds and borders.

  /// 10% Warm Lime — tinted backgrounds (icon containers, image placeholders)
  static const Color accentSurface = Color(0x1ABBC863);

  /// 20% Warm Lime — borders on accent containers
  static const Color accentBorder = Color(0x33BBC863);

  // ─── Semantic / Functional ───────────────────────────────────────────────
  static const Color error = Color(0xFFFF3B30); // iOS Red
  static const Color success = Color(0xFF34C759); // iOS Green
  static const Color warning = Color(0xFFFFCC00); // iOS Yellow
  static const Color info = Color(0xFF007AFF); // iOS Blue

  // ─── Surface Hierarchy ───────────────────────────────────────────────────
  // AGENTS: Use the right surface for the right depth level.
  //   background → main scaffold
  //   surface     → app bar, bottom nav, default cards
  //   cardSurface → elevated sections inside a card (e.g. profile info card)
  //   surfaceAlt  → input fields, shimmer base, deepest surface

  /// #FFFFFF — main scaffold/page background
  static const Color background = Color(0xFFFFFFFF);

  /// #FAFAFA — app bar, bottom nav, default card backgrounds
  static const Color surface = Color(0xFFFAFAFA);

  /// #F8F8F8 — elevated card sections (e.g. "Event kamu saat ini" card)
  static const Color cardSurface = Color(0xFFF8F8F8);

  /// #F5F5F5 — text input fill, shimmer, deepest surface layer
  static const Color surfaceAlt = Color(0xFFF5F5F5);

  // ─── Text Colors ─────────────────────────────────────────────────────────
  // AGENTS: Follow this hierarchy strictly.
  //   textPrimary   → headings, body content
  //   textEmphasis  → secondary headings, descriptions
  //   textSecondary → labels, captions, meta
  //   textTertiary  → hints, timestamps, placeholder
  //   textDisabled  → disabled state

  /// #000000 — headings, primary body text
  static const Color textPrimary = Color(0xFF000000);

  /// #3D3D3D — slightly softer text (descriptions, secondary headings)
  static const Color textEmphasis = Color(0xFF3D3D3D);

  /// #666666 — labels, captions, meta info
  static const Color textSecondary = Color(0xFF666666);

  /// #999999 — timestamps, hints, placeholders
  static const Color textTertiary = Color(0xFF999999);

  /// #CCCCCC — disabled state text
  static const Color textDisabled = Color(0xFFCCCCCC);

  // ─── Borders & Dividers ──────────────────────────────────────────────────
  /// #EEEEEE — list dividers, thin separators
  static const Color divider = Color(0xFFEEEEEE);

  /// #E0E0E0 — card borders, container outlines
  static const Color border = Color(0xFFE0E0E0);

  /// #111111 — focused input border
  static const Color borderFocus = Color(0xFF111111);

  // ─── Overlays ────────────────────────────────────────────────────────────
  /// 40% Black — modal scrims
  static const Color overlay = Color(0x66000000);

  /// 70% Black — dark gradient on event image cards
  static const Color overlayStrong = Color(0xB3000000);

  // ─── Shimmer ─────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
