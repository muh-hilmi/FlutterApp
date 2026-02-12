import 'package:flutter/material.dart';
import '../../domain/entities/event_category.dart';

/// Application color scheme following Clean Architecture principles
/// Centralized color management for consistent theming
class AppColors {
  // Primary Colors - Neon Green Highlight
  static const Color primary = Color(0xFFBBC863);
  static const Color primaryLight = Color(0xFFCCD67E);
  static const Color primaryDark = Color(0xFF9AAA4C);

  // Secondary Colors - Black
  static const Color secondary = Color(0xFF000000);
  static const Color secondaryLight = Color(0xFF1A1A1A);
  static const Color secondaryDark = Color(0xFF000000);

  // Background Colors - White/Light Theme
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF333333);
  static const Color textTertiary = Color(0xFF666666);

  // Status Colors - Neon Style
  static const Color success = Color(0xFFBBC863);
  static const Color error = Color(0xFFFF0055);
  static const Color warning = Color(0xFFFFFF00);
  static const Color info = Color(0xFF00FFFF);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Category Colors - Unified Neon Green
  // TODO: Consider using different colors for each category for better UX
  static const Map<EventCategory, Color> categoryColors = {
    EventCategory.meetup: Color(0xFFBBC863),
    EventCategory.sports: Color(0xFFBBC863),
    EventCategory.workshop: Color(0xFFBBC863),
    EventCategory.networking: Color(0xFFBBC863),
    EventCategory.food: Color(0xFFBBC863),
    EventCategory.creative: Color(0xFFBBC863),
    EventCategory.outdoor: Color(0xFFBBC863),
    EventCategory.fitness: Color(0xFFBBC863),
    EventCategory.learning: Color(0xFFBBC863),
    EventCategory.social: Color(0xFFBBC863),
  };

  /// Get category color with fallback to primary
  static Color getCategoryColor(EventCategory category) {
    return categoryColors[category] ?? primary;
  }
}