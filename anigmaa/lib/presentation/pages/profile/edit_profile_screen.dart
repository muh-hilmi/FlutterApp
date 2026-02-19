// Edit Profile Screen - Connected to API
// Allows users to edit their profile data and sync with backend

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../domain/entities/user.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/user/user_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Edit Profile Screen with API integration
///
/// To use:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => EditProfileScreen()),
/// );
/// ```
/// The screen will automatically fetch the current user from UserBloc
class EditProfileScreen extends StatefulWidget {
  final User? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  User? _currentUser;
  String? _selectedAvatarUrl;
  File? _selectedImageFile;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  List<String> _selectedInterests = [];
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  final List<String> _genderOptions = [
    'Laki-laki',
    'Perempuan',
    'Lainnya',
    'Prefer not to say',
  ];

  // Standardized interests (aligned with event categories)
  final List<String> _availableInterests = [
    'Meetup',
    'Sports',
    'Workshop',
    'Networking',
    'Food',
    'Creative',
    'Outdoor',
    'Fitness',
    'Learning',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    // If user is passed from constructor, use it
    if (widget.user != null) {
      _currentUser = widget.user;
      _populateFields(_currentUser!);
    } else {
      // Otherwise, try to get current user from bloc
      final state = context.read<UserBloc>().state;
      if (state is UserLoaded) {
        _currentUser = state.user;
        _populateFields(_currentUser!);
      }
    }
  }

  void _populateFields(User user) {
    _bioController.text = user.bio ?? '';
    _phoneController.text = user.phone ?? '';
    _locationController.text = user.location ?? '';
    _selectedAvatarUrl = user.avatar;
    _selectedDateOfBirth = user.dateOfBirth;
    _selectedGender = user.gender;
    _selectedInterests = List.from(user.interests);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        // Handle save completion
        if (_isSaving) {
          if (state is UserLoaded) {
            // Profile updated successfully
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.secondary,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          } else if (state is UserError) {
            // Handle error
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          // Get user name from current user or bloc state
          final userName = _currentUser?.name ??
              (state is UserLoaded ? state.user.name : 'User');

          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: _buildAppBar(),
            body: _isSaving
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfilePhoto(),
                        const SizedBox(height: 8),
                        _buildChangePhotoButton(),
                        const SizedBox(height: 32),
                        _buildDivider(),
                        _buildTextField(
                          label: 'Name',
                          value: userName,
                          readOnly: true,
                          onTap: () {},
                          trailing: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        _buildDivider(),
                        _buildTextField(
                          label: 'Bio',
                          value: _bioController.text.isEmpty
                              ? 'Add bio'
                              : _bioController.text,
                          onTap: () => _editBio(),
                        ),
                        _buildDivider(),
                        _buildTextField(
                          label: 'Phone',
                          value: _phoneController.text.isEmpty
                              ? 'Add phone number'
                              : _phoneController.text,
                          onTap: () => _editPhone(),
                        ),
                        _buildDivider(),
                        _buildTextField(
                          label: 'Gender',
                          value: _selectedGender ?? 'Select gender',
                          onTap: () => _selectGender(),
                        ),
                        _buildDivider(),
                        _buildTextField(
                          label: 'Date of Birth',
                          value: _selectedDateOfBirth != null
                              ? _formatDate(_selectedDateOfBirth!)
                              : 'Select date',
                          onTap: () => _selectDate(),
                        ),
                        _buildDivider(),
                        _buildTextField(
                          label: 'Location',
                          value: _locationController.text.isEmpty
                              ? 'Add location'
                              : _locationController.text,
                          onTap: () => _editLocation(),
                          trailing: _isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.secondary,
                                  ),
                                )
                              : null,
                        ),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Interests'),
                        const SizedBox(height: 16),
                        _buildInterests(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Edit Profile',
        style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _saveProfile,
          child: Text(
            'Done',
            style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: ClipOval(
              child: _selectedImageFile != null
                  ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                  : (_selectedAvatarUrl != null &&
                        _selectedAvatarUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: _selectedAvatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final userName = _currentUser?.name ?? 'User';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: AppTextStyles.display.copyWith(color: AppColors.textTertiary),
        ),
      ),
    );
  }

  Widget _buildChangePhotoButton() {
    return Center(
      child: TextButton(
        onPressed: _changeProfilePicture,
        child: Text(
          'Change photo',
          style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.secondary),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool readOnly = false,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: readOnly ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? 'Add $label' : value,
                style: AppTextStyles.button.copyWith(
                  color: value.isEmpty || readOnly
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ] else if (!readOnly) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInterests() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableInterests.map((interest) {
          final isSelected = _selectedInterests.contains(interest);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedInterests.remove(interest);
                } else {
                  _selectedInterests.add(interest);
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                interest,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Edit dialogs

  Future<void> _editBio() async {
    final controller = TextEditingController(text: _bioController.text);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bio'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bioController.text = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _editPhone() async {
    final controller = TextEditingController(text: _phoneController.text);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+62 ...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _phoneController.text = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _editLocation() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Enter city name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _requestLocation();
              },
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use current location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectGender() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _genderOptions.map((gender) {
            return RadioListTile<String>(
              title: Text(gender),
              value: gender,
              groupValue: _selectedGender,
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.secondary;
                }
                return AppColors.textSecondary;
              }),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final placemark = placemarks.first;
          setState(() {
            _locationController.text =
                '${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.secondary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _chooseFromGallery();
                },
              ),
              if (_selectedImageFile != null || _selectedAvatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    setState(() {
                      _selectedImageFile = null;
                      _selectedAvatarUrl = null;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImageFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    // Check if user is available
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save: User data not loaded'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Upload image if _selectedImageFile is not null
      // TODO: Get the uploaded image URL

      if (mounted) {
        final userBloc = context.read<UserBloc>();

        // Trigger the update via bloc
        userBloc.add(
          UpdateUserProfile(
            bio: _bioController.text.isEmpty ? null : _bioController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            location: _locationController.text.isEmpty ? null : _locationController.text,
            dateOfBirth: _selectedDateOfBirth,
            gender: _selectedGender,
            interests: _selectedInterests.isEmpty ? null : _selectedInterests,
            // avatar: uploadedImageUrl, // Update this after upload
          ),
        );

        // Note: We don't call Navigator.pop() here
        // The BlocListener will handle navigation after successful update
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    // Don't set _isSaving = false in finally - let BlocListener handle it
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
