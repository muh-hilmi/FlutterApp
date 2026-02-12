import 'package:flutter/material.dart';

class ProfileEmptyStates {
  static Widget buildEmptyPosts({required bool isOwnProfile}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada postingan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (isOwnProfile)
            Text(
              'Buat postingan pertamamu!',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
        ],
      ),
    );
  }

  static Widget buildEmptyEvents({required bool isOwnProfile}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.event_outlined, size: 64, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada event',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (isOwnProfile)
            Text(
              'Buat event pertamamu!',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
        ],
      ),
    );
  }

  static Widget buildEmptySaved() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada item tersimpan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simpan event & post favoritmu di sini',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }
}