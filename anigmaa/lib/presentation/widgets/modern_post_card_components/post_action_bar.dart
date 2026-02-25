import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../pages/post_detail/post_detail_screen.dart';
import '../../pages/profile/profile_screen.dart';
import '../../../core/services/share_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PostActionBar extends StatefulWidget {
  final Post post;
  final VoidCallback? onCommentTap;
  final bool showCommentCount;
  final int? actualCommentCount;

  const PostActionBar({
    super.key,
    required this.post,
    this.onCommentTap,
    this.showCommentCount = true,
    this.actualCommentCount,
  });

  @override
  State<PostActionBar> createState() => _PostActionBarState();
}

class _PostActionBarState extends State<PostActionBar>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _sparkleAnimationController;
  late AnimationController _pulseGlowController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _pulseGlowAnimation;
  late bool _isLiked;
  bool _showSparkles = false;

  // Debounce and loading state for like button
  DateTime? _lastLikeTap;
  static const _likeDebounce = Duration(milliseconds: 300);
  bool _isLiking = false;
  Timer? _likingResetTimer;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;

    // Setup like animation - Star Pop
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _likeScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 35),
        ]).animate(
          CurvedAnimation(
            parent: _likeAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // Setup sparkle animation
    _sparkleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _sparkleAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showSparkles = false;
        });
        _sparkleAnimationController.reset();
      }
    });

    // Setup pulse glow animation - continuous breathing effect when liked
    _pulseGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseGlowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseGlowController, curve: Curves.easeInOut),
    );

    // Start pulse if already liked
    if (_isLiked) {
      _pulseGlowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PostActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isLikedByCurrentUser != _isLiked) {
      setState(() {
        _isLiked = widget.post.isLikedByCurrentUser;
      });
      if (_isLiked) {
        _pulseGlowController.repeat(reverse: true);
      } else {
        _pulseGlowController.stop();
        _pulseGlowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _sparkleAnimationController.dispose();
    _pulseGlowController.dispose();
    _likingResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like Button - Star Pop Sparkle
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: _isLiking
                  ? null
                  : () {
                      // Debounce: check if enough time has passed since last tap
                      final now = DateTime.now();
                      if (_lastLikeTap != null &&
                          now.difference(_lastLikeTap!) < _likeDebounce) {
                        return;
                      }
                      _lastLikeTap = now;

                      final newLikedState = !_isLiked;
                      setState(() {
                        _isLiked = newLikedState;
                        _isLiking = true;
                        // Only show sparkles when LIKING (not unliking)
                        _showSparkles = newLikedState;
                      });
                      _likeAnimationController.forward(from: 0.0);
                      // Only trigger sparkle animation when liking
                      if (newLikedState) {
                        _sparkleAnimationController.forward(from: 0.0);
                        _pulseGlowController.repeat(reverse: true);
                      } else {
                        _pulseGlowController.stop();
                        _pulseGlowController.reset();
                      }
                      context.read<PostsBloc>().add(
                        LikePostToggled(widget.post.id, newLikedState),
                      );

                      // Reset loading state after a short delay
                      _likingResetTimer?.cancel();
                      _likingResetTimer = Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _isLiking = false;
                          });
                        }
                      });
                    },
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _likeScaleAnimation,
                  _pulseGlowAnimation,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _likeScaleAnimation.value,
                    child: Opacity(
                      opacity: _isLiking ? 0.6 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Star emoji — outline when not liked, filled yellow when liked
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: _isLiked
                                ? BoxDecoration(
                                    color: Color.lerp(
                                      const Color(0xFFFFD700).withValues(alpha: 0.10),
                                      const Color(0xFFFFD700).withValues(alpha: 0.20),
                                      _pulseGlowAnimation.value,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  )
                                : null,
                            child: Text(
                              '⭐',
                              style: TextStyle(
                                fontSize: 20 * (_isLiked ? 1.1 : 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.post.likesCount > 0
                                ? _formatCount(widget.post.likesCount)
                                : 'Gas!',
                            style: AppTextStyles.bodyMediumBold.copyWith(
                              fontWeight: _isLiked
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: _isLiked
                                  ? const Color(0xFFFFD700)
                                  : AppColors.textEmphasis,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Sparkle particles
            if (_showSparkles) ..._buildSparkleParticles(),
          ],
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          emoji: '💬',
          label: widget.showCommentCount
              ? (_getCommentCount() > 0
                    ? _formatCount(_getCommentCount())
                    : 'Tanya')
              : '',
          onTap:
              widget.onCommentTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: widget.post),
                  ),
                );
              },
        ),
        const Spacer(),
        _buildActionButton(
          emoji: '🔗',
          label: '',
          onTap: () => _sharePost(context),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 19)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMediumBold.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textEmphasis,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSparkleParticles() {
    return [
      // Top sparkle
      Positioned(
        top: -8,
        left: 10,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -10 * _sparkleAnimation.value),
              child: Opacity(
                opacity: 1.0 - _sparkleAnimation.value,
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 12 * (1.0 + _sparkleAnimation.value * 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Top right sparkle
      Positioned(
        top: -5,
        right: 8,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                10 * _sparkleAnimation.value,
                -8 * _sparkleAnimation.value,
              ),
              child: Opacity(
                opacity: 1.0 - _sparkleAnimation.value,
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 10 * (1.0 + _sparkleAnimation.value * 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Left sparkle
      Positioned(
        left: -5,
        top: 15,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-12 * _sparkleAnimation.value, 0),
              child: Opacity(
                opacity: 1.0 - _sparkleAnimation.value,
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 11 * (1.0 + _sparkleAnimation.value * 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Right sparkle
      Positioned(
        right: -5,
        bottom: 10,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                12 * _sparkleAnimation.value,
                5 * _sparkleAnimation.value,
              ),
              child: Opacity(
                opacity: 1.0 - _sparkleAnimation.value,
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 10 * (1.0 + _sparkleAnimation.value * 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Bottom left sparkle
      Positioned(
        left: 5,
        bottom: -5,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                -8 * _sparkleAnimation.value,
                10 * _sparkleAnimation.value,
              ),
              child: Opacity(
                opacity: 1.0 - _sparkleAnimation.value,
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 9 * (1.0 + _sparkleAnimation.value * 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  int _getCommentCount() {
    return widget.actualCommentCount ?? widget.post.commentsCount;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Bagikan Post', style: AppTextStyles.h3),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildShareOption(
                          context,
                          icon: Icons.copy,
                          label: 'Salin Link',
                          color: AppColors.textSecondary,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'copy link',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.message,
                          label: 'WhatsApp',
                          color: AppColors.success,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'whatsapp',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: Colors.blue[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'facebook',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.alternate_email,
                          label: 'Twitter',
                          color: Colors.lightBlue,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'twitter',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'instagram stories',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.email,
                          label: 'Email',
                          color: AppColors.error,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'email',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.share,
                          label: 'Lainnya',
                          color: AppColors.textSecondary,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().sharePost(
                              context: context,
                              post: widget.post,
                              platform: 'system',
                            );
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.qr_code,
                          label: 'QR Code',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            ShareService().showPostQRCode(context, widget.post);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close dialog first
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: widget.post.author.id,
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.surface,
                              child: Text(
                                widget.post.author.name[0].toUpperCase(),
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.author.name,
                                  style: AppTextStyles.bodyMediumBold,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.post.content.length > 50
                                      ? '${widget.post.content.substring(0, 50)}...'
                                      : widget.post.content,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
