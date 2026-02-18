import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_state.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/utils/app_logger.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  static Future<Post?> show(BuildContext context) {
    return showModalBottomSheet<Post>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostSheet(),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  Event? _selectedEvent;
  final FocusNode _focusNode = FocusNode();
  bool _isCreating = false;

  // Updated: canPost requires text/image AND an event
  bool get canPost =>
      !_isCreating &&
      (_textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty) &&
      _selectedEvent != null;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFBBC863);

    // Provide keyboard padding manually
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75, // 3/4 screen height
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                // 1. SOFT GLOW BACKGROUND
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.15),
                          primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. CONTENT
                Column(
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            'Buat Postingan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: canPost ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: 200),
                            child: ElevatedButton(
                              onPressed: canPost ? _createPost : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(
                                  0,
                                  36,
                                ), // Compact button
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                'Post',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Color(0xFFF0F0F0), height: 32),

                    Expanded(
                      child: BlocBuilder<UserBloc, UserState>(
                        builder: (context, userState) {
                          User? currentUser;
                          if (userState is UserLoaded) {
                            currentUser = userState.user;
                          }

                          return ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              // User Info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage: currentUser?.avatar != null
                                        ? NetworkImage(currentUser!.avatar!)
                                        : null,
                                    child: currentUser?.avatar == null
                                        ? Text(
                                            currentUser?.name[0]
                                                    .toUpperCase() ??
                                                'U',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    currentUser?.name ?? 'User',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Text Field
                              TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                maxLines: null,
                                minLines: 2,
                                decoration: InputDecoration(
                                  hintText: "Apa yang lagi seru?",
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 20),

                              // MANDATORY EVENT SELECTOR (Prominent)
                              if (_selectedEvent == null)
                                GestureDetector(
                                  onTap: _showEventSelector,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      border: Border.all(
                                        color: const Color(0xFFBBC863),
                                        width: 1.5,
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: Color(0xFFBBC863),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pilih Event (Wajib)',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black87,
                                                  ),
                                            ),
                                            Text(
                                              'Event apa yang mau dibahas?',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                _buildGlassmorphicTicket(),

                              // Image Grid
                              if (_selectedImages.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildImageGrid(),
                              ],

                              SizedBox(height: keyboardHeight + 80),
                            ],
                          );
                        },
                      ),
                    ),

                    // Accessory Bar (Only Images now)
                    _buildAccessoryBar(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessoryBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tambahkan ke postingan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_rounded,
                color: Colors.blueAccent,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Option A: Glassmorphic Ticket style
  Widget _buildGlassmorphicTicket() {
    final event = _selectedEvent!;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7), // Semi-transparent
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFBBC863,
                ).withValues(alpha: 0.1), // Subtle lime shadow
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (event.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    event.imageUrl!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBC863).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            event.date.day.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: const Color(0xFF556018),
                              height: 1,
                            ),
                          ),
                          Text(
                            _monthName(event.date.month),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: const Color(0xFFBBC863),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.location.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
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
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _selectedEvent = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 250),
        child: _selectedImages.length == 1
            ? Stack(
                children: [
                  Image.file(
                    File(_selectedImages[0]),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  _buildRemoveImageButton(0),
                ],
              )
            : GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                      _buildRemoveImageButton(index),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRemoveImageButton(int index) {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () => setState(() => _selectedImages.removeAt(index)),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  void _showEventSelector() {
    // Show inner sheet for selection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Pilih Event',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<EventsBloc, EventsState>(
                builder: (context, state) {
                  if (state is EventsLoaded) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                      itemCount: state.events.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedEvent = event);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event, color: Colors.grey[400]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        if (_selectedImages.length + images.length <= 4) {
          setState(() {
            _selectedImages.addAll(images.map((img) => img.path).toList());
          });
        } else {
          // Toast/Snackbar
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<void> _createPost() async {
    if (_isCreating) return;

    // Get current user from UserBloc
    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoaded) {
      _showErrorSnackBar('User tidak ditemukan. Silakan login kembali.');
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Step 1: Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        _showLoadingSnackBar('Mengupload gambar...');

        final uploadService = UploadService();
        final imageFiles = _selectedImages.map((path) => File(path)).toList();

        try {
          imageUrls = await uploadService.uploadImages(imageFiles);

          if (imageUrls.length != _selectedImages.length) {
            if (!mounted) return;
            _showErrorSnackBar('Beberapa gambar gagal diupload.');
            // Continue with successfully uploaded images
          }
        } catch (e) {
          AppLogger().error('Error uploading images: $e');
          if (!mounted) return;
          _showErrorSnackBar('Gagal upload gambar: $e');
          setState(() => _isCreating = false);
          return;
        }
      }

      // Step 2: Determine post type
      final postType = imageUrls.isNotEmpty
          ? PostType.text_with_images
          : PostType.text_with_event;

      // Step 3: Create the Post entity
      final post = Post(
        id: '', // Empty ID for new post
        author: userState.user,
        content: _textController.text.trim(),
        type: postType,
        imageUrls: imageUrls,
        attachedEvent: _selectedEvent,
        createdAt: DateTime.now(),
        visibility: PostVisibility.public,
      );

      // Step 4: Dispatch CreatePostRequested event
      if (!mounted) return;
      context.read<PostsBloc>().add(CreatePostRequested(post));

      // Step 5: Close the sheet
      if (mounted) {
        Navigator.pop(context, post);
      }
    } catch (e) {
      AppLogger().error('Error creating post: $e');
      _showErrorSnackBar('Gagal membuat post: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFBBC863),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
