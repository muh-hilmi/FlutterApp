import 'package:flutter/material.dart';
import '../../domain/entities/event_category.dart';

class EventCategoryUtils {
  static String getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return '#meetup';
      case EventCategory.sports:
        return '#sports';
      case EventCategory.workshop:
        return '#workshop';
      case EventCategory.networking:
        return '#networking';
      case EventCategory.food:
        return '#foodie';
      case EventCategory.creative:
        return '#creative';
      case EventCategory.outdoor:
        return '#outdoor';
      case EventCategory.fitness:
        return '#fitness';
      case EventCategory.learning:
        return '#learning';
      case EventCategory.social:
        return '#social';
    }
  }

  static String getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return 'Kumpul';
      case EventCategory.sports:
        return 'Olahraga';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.food:
        return 'Kuliner';
      case EventCategory.creative:
        return 'Kreatif';
      case EventCategory.outdoor:
        return 'Outdoor';
      case EventCategory.fitness:
        return 'Fitness';
      case EventCategory.learning:
        return 'Belajar';
      case EventCategory.social:
        return 'Sosial';
    }
  }

  static EventCategory? getCategoryFromString(String categoryString) {
    return EventCategory.values.firstWhere(
      (category) =>
          getCategoryName(category).toLowerCase() ==
          categoryString.toLowerCase(),
    );
  }

  static IconData getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return Icons.groups_rounded;
      case EventCategory.sports:
        return Icons.sports_basketball_rounded;
      case EventCategory.workshop:
        return Icons.precision_manufacturing_rounded;
      case EventCategory.networking:
        return Icons.people_outline_rounded;
      case EventCategory.food:
        return Icons.restaurant_rounded;
      case EventCategory.creative:
        return Icons.brush_rounded;
      case EventCategory.outdoor:
        return Icons.landscape_rounded;
      case EventCategory.fitness:
        return Icons.fitness_center_rounded;
      case EventCategory.learning:
        return Icons.school_rounded;
      case EventCategory.social:
        return Icons.emoji_people_rounded;
    }
  }
}
