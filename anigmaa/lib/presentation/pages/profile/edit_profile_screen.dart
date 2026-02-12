// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

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

/// Instagram-style Edit Profile Screen with flyerr theme
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

  String? _selectedAvatarUrl;
  File? _selectedImageFile;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  List<String> _selectedInterests = [];
  bool _isLoading = false;
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
    if (widget.user != null) {
      _bioController.text = widget.user!.bio ?? '';
      _phoneController.text = widget.user!.phone ?? '';
      _locationController.text = widget.user!.location ?? '';
      _selectedAvatarUrl = widget.user!.avatar;
      _selectedDateOfBirth = widget.user!.dateOfBirth;
      _selectedGender = widget.user!.gender;
      _selectedInterests = List.from(widget.user!.interests);
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBBC863)),
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
                    value: widget.user?.name ?? '',
                    readOnly: true,
                    onTap: () {},
                    trailing: const Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  _buildDivider(),
                  _buildTextField(
                    label: 'Bio',
                    value: _bioController.text,
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
                              color: Color(0xFFBBC863),
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
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _saveProfile,
          child: const Text(
            'Done',
            style: TextStyle(
              color: Color(0xFFBBC863),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
              border: Border.all(color: Colors.grey.shade200, width: 1),
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
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFBBC863),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.user?.name[0].toUpperCase() ?? 'U',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildChangePhotoButton() {
    return Center(
      child: TextButton(
        onPressed: _changeProfilePicture,
        child: const Text(
          'Change photo',
          style: TextStyle(
            color: Color(0xFFBBC863),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade200);
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
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? 'Add $label' : value,
                style: TextStyle(
                  fontSize: 15,
                  color: value.isEmpty || readOnly
                      ? Colors.grey.shade600
                      : Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ] else if (!readOnly) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
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
                color: isSelected
                    ? const Color(0xFFBBC863)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFBBC863)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                interest,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bioController.text = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFBBC863),
                fontWeight: FontWeight.w600,
              ),
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _phoneController.text = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFBBC863),
                fontWeight: FontWeight.w600,
              ),
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
                foregroundColor: const Color(0xFFBBC863),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFBBC863),
                fontWeight: FontWeight.w600,
              ),
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
                  return const Color(0xFFBBC863);
                }
                return Colors.grey.shade600;
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFBBC863)),
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
            backgroundColor: Colors.red,
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
                leading: const Icon(Icons.camera_alt, color: Color(0xFFBBC863)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFBBC863),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _chooseFromGallery();
                },
              ),
              if (_selectedImageFile != null || _selectedAvatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Upload image if _selectedImageFile is not null
      // TODO: Get the uploaded image URL

      if (mounted) {
        final userBloc = context.read<UserBloc>();
        final currentUserId = widget.user?.id;

        userBloc.add(
          UpdateUserProfile(
            bio: _bioController.text,
            phone: _phoneController.text,
            location: _locationController.text,
            dateOfBirth: _selectedDateOfBirth,
            gender: _selectedGender,
            interests: _selectedInterests,
            // avatar: uploadedImageUrl, // Update this after upload
          ),
        );

        // Wait for update to complete
        await Future.delayed(const Duration(seconds: 1));

        // Refresh the profile data in parent screen
        if (currentUserId != null) {
          userBloc.add(LoadUserById(currentUserId));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFFBBC863),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
