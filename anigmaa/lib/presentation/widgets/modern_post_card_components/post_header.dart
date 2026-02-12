import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/post.dart';
import '../../pages/profile/profile_screen.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';

class PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback? onMenuTap;

  const PostHeader({super.key, required this.post, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: post.author.id),
              ),
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFBBC863),
            backgroundImage:
                post.author.avatar != null && post.author.avatar!.isNotEmpty
                ? CachedNetworkImageProvider(post.author.avatar!)
                : null,
            child: post.author.avatar == null || post.author.avatar!.isEmpty
                ? Text(
                    post.author.name[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000000),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000000),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),

              // Interests tags
              if (post.author.interests.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: post.author.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        interest,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Time
              Text(
                timeago.format(post.createdAt, locale: 'en_short'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // More Menu - rounded button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: Color(0xFF262626),
            ),
            onPressed: onMenuTap ?? () => _showPostMenu(context),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E4DD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                context,
                icon: post.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                iconColor: const Color(0xFFBBC863),
                backgroundColor: const Color(0xFFE8EDDA),
                title: post.isBookmarked
                    ? 'Hapus dari Simpanan'
                    : 'Simpan Post',
                onTap: () {
                  Navigator.pop(context);
                  context.read<PostsBloc>().add(
                    SavePostToggled(post.id, post.isBookmarked),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF6B6B6B),
                backgroundColor: const Color(0xFFFCFCFC),
                title: 'Salin Link',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.flag_outlined,
                iconColor: const Color(0xFFFF6B6B),
                backgroundColor: const Color(0xFFFFEBEE),
                title: 'Laporin',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
