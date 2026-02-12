import 'package:anigmaa/core/utils/event_category_utils.dart';
import 'package:anigmaa/domain/entities/event_category.dart';
import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final Function(EventCategory) onCategorySelected;

  const CategorySelector({super.key, required this.onCategorySelected});

  // Emoji for each category to make it more fun
  String _getCategoryEmoji(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return '🤝';
      case EventCategory.sports:
        return '⚽';
      case EventCategory.workshop:
        return '🛠️';
      case EventCategory.networking:
        return '💼';
      case EventCategory.food:
        return '🍜';
      case EventCategory.creative:
        return '🎨';
      case EventCategory.outdoor:
        return '🏕️';
      case EventCategory.fitness:
        return '💪';
      case EventCategory.learning:
        return '📚';
      case EventCategory.social:
        return '🎉';
    }
  }

  // Get description for each category
  String _getCategoryDescription(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return 'Kumpul bareng';
      case EventCategory.sports:
        return 'Olahraga';
      case EventCategory.workshop:
        return 'Belajar skill';
      case EventCategory.networking:
        return 'Perluas relasi';
      case EventCategory.food:
        return 'Kulineran';
      case EventCategory.creative:
        return 'Seni & kreativitas';
      case EventCategory.outdoor:
        return 'Petualangan';
      case EventCategory.fitness:
        return 'Workout';
      case EventCategory.learning:
        return 'Edukasi';
      case EventCategory.social:
        return 'Sosial & hangout';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Kategori Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap untuk memilih kategori yang paling cocok',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Grid of category chips - 2 per row
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
          ),
          itemCount: EventCategory.values.length,
          itemBuilder: (context, index) {
            final category = EventCategory.values[index];
            return _buildCategoryChip(context, category);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context, EventCategory category) {
    final emoji = _getCategoryEmoji(category);
    final name = EventCategoryUtils.getCategoryDisplayName(category);
    final description = _getCategoryDescription(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCategorySelected(category),
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFFBBC863).withValues(alpha: 0.2),
        highlightColor: const Color(0xFFBBC863).withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFCFCFC),
                const Color(0xFFF5F5F5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFBBC863).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBBC863).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji with background
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              // Category name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
