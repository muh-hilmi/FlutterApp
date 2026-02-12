import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart'; // Fixed import
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event_location.dart'; // Added import
import '../../../domain/entities/event_host.dart'; // Added import
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
// Removed missing CustomSnackbar import

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _ticketNameController = TextEditingController(
    text: 'General Admission',
  );

  // State
  EventCategory _selectedCategory = EventCategory.creative; // Fixed enum
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  late LatLng _selectedLocation;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isMapReady = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
      });
    } catch (e) {
      // Default to Jakarta
      setState(() {
        _selectedLocation = const LatLng(-6.2088, 106.8456);
        _isMapReady = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _ticketNameController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Helper for Snackbar
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? Colors.white : Colors.black),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Trigger upload immediately
      if (!mounted) return;
      context.read<EventsBloc>().add(
        UploadEventImageRequested(_selectedImage!),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _submitEvent();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _submitEvent() {
    if (_formKey.currentState!.validate()) {
      if (_uploadedImageUrl == null && _selectedImage != null) {
        _showSnackbar('Tunggu upload gambar selesai ya! ⏳', isError: true);
        return;
      }

      final event = Event(
        id: '', // Backend generates ID
        title: _titleController.text,
        description: _descriptionController.text,
        // Removed `date` field
        startTime: _startTime,
        endTime: _endTime,
        location: EventLocation(
          // Constructed EventLocation
          name: _locationNameController.text,
          address: _locationNameController.text, // Fallback
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        ),
        category: _selectedCategory,
        imageUrls: _uploadedImageUrl != null
            ? [_uploadedImageUrl!]
            : [], // Fixed posterUrl to imageUrls
        host: const EventHost(
          // Dummy host, backend should replace
          id: 'user',
          name: 'User',
          avatar: '',
          bio: '',
        ),
        // organizerId, organizerName, organizerAvatarUrl removed as they are part of Host
        maxAttendees:
            int.tryParse(_capacityController.text) ??
            100, // Fixed capacity -> maxAttendees
        // remainingCapacity removed, calculated getters usually
        attendeeIds: [],
        price: double.tryParse(_priceController.text) ?? 0,
        isFree: (double.tryParse(_priceController.text) ?? 0) == 0,
        interestedUserIds: [],
        status: EventStatus.upcoming, // Fixed status enum
        createdAt: DateTime.now(),
      );

      context.read<EventsBloc>().add(CreateEventRequested(event));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state is EventsLoaded) {
          if (state.lastUploadedImageUrl != null) {
            setState(() {
              _uploadedImageUrl = state.lastUploadedImageUrl;
            });
            // Clear the one-time message if needed, but Bloc handles clearing usually or we ignore duplicates
          }
          if (state.successMessage != null &&
              state.successMessage!.contains('Event berhasil')) {
            _showSnackbar(state.successMessage!);
            Navigator.pop(context);
          }
          if (state.createErrorMessage != null) {
            _showSnackbar(state.createErrorMessage!, isError: true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Buat Event Baru',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildStep1(), _buildStep2(), _buildStep3()],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Event',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('Nama Event'),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _buildInputDecoration('Cth: Music Festival 2024'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Nama event wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          _buildLabel('Deskripsi'),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _buildInputDecoration('Jelaskan serunya event kamu...'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Deskripsi wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          _buildLabel('Kategori'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: EventCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategory = category);
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Mulai'),
                    _buildDateTimePicker(
                      _startTime,
                      (date) => setState(() => _startTime = date),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Selesai'),
                    _buildDateTimePicker(
                      _endTime,
                      (date) => setState(() => _endTime = date),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi Event',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Nama Tempat'),
              TextFormField(
                controller: _locationNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _buildInputDecoration('Cth: GBK Senayan'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama tempat wajib diisi' : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              if (_isMapReady)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onCameraMove: (position) {
                    _selectedLocation = position.target;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation,
                    ),
                  },
                )
              else
                const Center(child: CircularProgressIndicator()),

              Center(
                child: Icon(
                  LucideIcons.mapPin,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual & Tiket',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('Poster Event'),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.imagePlus,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Poster',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : _uploadedImageUrl == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 24),

          _buildLabel('Kapasitas'),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _buildInputDecoration('Cth: 100'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Kapasitas wajib diisi' : null,
          ),

          const SizedBox(height: 20),
          _buildLabel('Harga Tiket (Rp)'),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _buildInputDecoration('0 untuk event gratis'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Harga wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Kembali',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_currentStep == 2 ? 'Buat Event' : 'Lanjut'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateTimePicker(
    DateTime initialDate,
    Function(DateTime) onSelect,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(initialDate),
          );
          if (time != null) {
            onSelect(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.calendar,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy, HH:mm').format(initialDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
