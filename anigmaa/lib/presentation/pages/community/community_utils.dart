import 'package:flutter/material.dart';

class CommunityUtils {
  static String formatEventTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = localDateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today, ${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow, ${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 1 && difference.inDays <= 7) {
      return '${localDateTime.day}/${localDateTime.month}, ${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
    }
  }
}

class CommunityDialogs {
  static void showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post created!')),
              );
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}