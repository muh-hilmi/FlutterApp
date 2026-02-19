import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ANIGMAA Typography System v1.0 — Plus Jakarta Sans
///
/// AGENTS: Always use these styles. NEVER use raw TextStyle with plusJakartaSans inline.
/// See BLUEPRINT/12_design_system.md for the full typographic hierarchy.
///
/// HIERARCHY (largest → smallest):
///   display → h1 → h2 → h3 → bodyLarge → bodyMedium → bodySmall → caption → label
class AppTextStyles {
  // ─── Display ─────────────────────────────────────────────────────────────
  /// For hero numbers and large stats (e.g. "1.2rb followers")
  static TextStyle get display => GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    height: 1.0,
  );

  // ─── Headings ────────────────────────────────────────────────────────────
  /// Page titles — used once per screen
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.2,
  );

  /// Section titles, dialog titles
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.3,
  );

  /// Card titles, app bar title
  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.3,
  );

  // ─── Body ────────────────────────────────────────────────────────────────
  /// Primary content text (posts, descriptions)
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Bold variant of bodyLarge — user names, important labels at 16px
  static TextStyle get bodyLargeBold => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );

  /// Standard body text (list items, secondary content)
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Semi-bold body — sub-labels, section titles at 14px
  static TextStyle get bodyMediumBold => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Small body — tertiary content, supporting text
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Caption ─────────────────────────────────────────────────────────────
  /// Timestamps, locations, meta info (12px medium)
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Extra small meta — rarely used, for dense info (11px medium)
  static TextStyle get captionSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.3,
  );

  // ─── Components ──────────────────────────────────────────────────────────
  /// Button text — elevated & outlined buttons
  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.2,
    height: 1.0,
  );

  /// Pill/tag labels — event status badges, filter chips
  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  /// Tab labels — active and inactive tab text
  static TextStyle get tabLabel => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.0,
  );
}
