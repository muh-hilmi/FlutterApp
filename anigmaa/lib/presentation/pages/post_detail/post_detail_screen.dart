import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../widgets/share/share_bottom_sheet.dart';
import '../../widgets/modern_post_card_components/post_header.dart';
import '../../widgets/modern_post_card_components/post_content.dart';
import '../../widgets/modern_post_card_components/post_images.dart';
import '../../widgets/modern_post_card_components/event_attachment.dart';
import '../../widgets/modern_post_card_components/post_poll.dart';
import '../../widgets/modern_post_card_components/post_action_bar.dart';
import '../../widgets/common/comment_section.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    // Load comments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PostsBloc>().add(LoadComments(widget.post.id));
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _handleReply(Comment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAuthorName = comment.author.name;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
    });
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Color(0xFF1F2937),
        ),
      );
      return;
    }

    final comment = Comment(
      id: '',
      postId: widget.post.id,
      author: userState.user,
      content: _commentController.text.trim(),
      createdAt: DateTime.now(),
      parentCommentId: _replyToCommentId,
    );

    context.read<PostsBloc>().add(CreateCommentRequested(comment));
    _commentController.clear();
    _cancelReply();
    _commentFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user for avatar
    final userState = context.watch<UserBloc>().state;
    final currentUser = userState is UserLoaded ? userState.user : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          Post currentPost = widget.post;

          if (state is PostsLoaded) {
            final updatedPost = state.posts
                .where((p) => p.id == widget.post.id)
                .firstOrNull;
            if (updatedPost != null) {
              currentPost = updatedPost;
            }
          }

          return Column(
            children: [
              // Main scrollable content
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(currentPost),
                    SliverToBoxAdapter(child: _buildPostContent(currentPost)),
                    SliverToBoxAdapter(
                      child: CommentSection(
                        post: currentPost,
                        onReply: _handleReply,
                      ),
                    ),
                    // Bottom padding for the input bar
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),

              // Instagram-style bottom input bar
              _buildBottomInputBar(currentUser),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomInputBar(User? currentUser) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom
            : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyToAuthorName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Membalas $_replyToAuthorName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Input row
          Row(
            children: [
              // User avatar
              _buildUserAvatar(currentUser),
              const SizedBox(width: 8),

              // Input field
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tambahkan komentar...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),

              // Send button
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Kirim',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _commentController.text.trim().isNotEmpty
                          ? const Color(0xFFBBC863)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(User? user) {
    if (user != null && user.avatar != null && user.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: CachedNetworkImageProvider(user.avatar!),
      );
    }

    if (user != null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFBBC863),
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.person, size: 18, color: Colors.grey),
    );
  }

  Widget _buildAppBar(Post post) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Postingan',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.black),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ShareBottomSheet(post: post),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
    );
  }

  Widget _buildPostContent(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: PostHeader(post: post),
        ),

        // Post Text Content
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: PostContent(content: post.content),
          ),

        // Post Images
        if (post.imageUrls.isNotEmpty) PostImages(imageUrls: post.imageUrls),

        // Event Mini Card (if has event)
        if (post.attachedEvent != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EventAttachment(post: post),
          ),

        // Poll (if has poll)
        if (post.poll != null) const PostPoll(),

        // Action Bar (Like, Comment, etc)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              final actualCommentCount = state is PostsLoaded &&
                      state.commentsByPostId.containsKey(post.id)
                  ? state.commentsByPostId[post.id]!.length
                  : null;

              return PostActionBar(
                post: post,
                actualCommentCount: actualCommentCount,
                onCommentTap: () {
                  // Scroll to comment section
                  final controller = PrimaryScrollController.of(context);
                  controller.animateTo(
                    controller.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              );
            },
          ),
        ),

        Divider(color: Colors.grey[100], height: 1),
      ],
    );
  }
}
