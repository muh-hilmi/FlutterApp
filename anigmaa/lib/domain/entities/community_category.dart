// Standardized community categories (aligned with event categories)
enum CommunityCategory {
  meetup,
  sports,
  workshop,
  networking,
  food,
  creative,
  outdoor,
  fitness,
  learning,
  social,
}

extension CommunityCategoryExtension on CommunityCategory {
  String get displayName {
    switch (this) {
      case CommunityCategory.meetup:
        return 'Kumpul';
      case CommunityCategory.sports:
        return 'Olahraga';
      case CommunityCategory.workshop:
        return 'Workshop';
      case CommunityCategory.networking:
        return 'Networking';
      case CommunityCategory.food:
        return 'Kuliner';
      case CommunityCategory.creative:
        return 'Kreatif';
      case CommunityCategory.outdoor:
        return 'Outdoor';
      case CommunityCategory.fitness:
        return 'Fitness';
      case CommunityCategory.learning:
        return 'Pembelajaran';
      case CommunityCategory.social:
        return 'Sosial';
    }
  }

  String get emoji {
    switch (this) {
      case CommunityCategory.meetup:
        return '🤝';
      case CommunityCategory.sports:
        return '⚽';
      case CommunityCategory.workshop:
        return '🛠️';
      case CommunityCategory.networking:
        return '💼';
      case CommunityCategory.food:
        return '🍔';
      case CommunityCategory.creative:
        return '🎨';
      case CommunityCategory.outdoor:
        return '🌳';
      case CommunityCategory.fitness:
        return '🏃';
      case CommunityCategory.learning:
        return '📚';
      case CommunityCategory.social:
        return '🎉';
    }
  }
}
