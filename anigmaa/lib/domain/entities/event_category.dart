enum EventCategory {
  meetup,
  sports,
  workshop,
  networking,
  food,
  creative,
  outdoor,
  fitness,
  learning,
  social
}

enum EventStatus { upcoming, ongoing, ended, cancelled }

extension EventCategoryExtension on EventCategory {
  String get displayName {
    switch (this) {
      case EventCategory.meetup:
        return 'Meetup';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.food:
        return 'Food & Drink';
      case EventCategory.creative:
        return 'Creative';
      case EventCategory.outdoor:
        return 'Outdoor';
      case EventCategory.fitness:
        return 'Fitness';
      case EventCategory.learning:
        return 'Learning';
      case EventCategory.social:
        return 'Social';
    }
  }
}