import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event_location.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/my_events/my_events_bloc.dart';
import '../../bloc/my_events/my_events_event.dart';
import '../../widgets/common/location_picker.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

/// ✨ Modern Edit Event Screen - Complete UI/UX Redesign
///
/// Design Principles:
/// - Clean, minimalist aesthetic with purposeful spacing
/// - Visual hierarchy with clear section separation
/// - Polished micro-interactions and feedback
/// - Accessible touch targets (44pt minimum)
/// - Progressive disclosure of information
/// - Delightful animations
class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();

  late AnimationController _fabController;
  late AnimationController _headerController;

  // Form state
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  LocationData? _location;
  EventCategory _category = EventCategory.meetup;
  bool _isFree = true;
  File? _coverImage;
  String? _coverImageUrl;

  // UI state
  bool _isSaving = false;
  bool _hasChanges = false;
  final Set<String> _updatedFields = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID');
    _initializeFromEvent();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Animate header based on scroll position
    final offset = _scrollController.offset;
    if (offset > 50 && _headerController.status == AnimationStatus.dismissed) {
      _headerController.forward();
    } else if (offset < 50 &&
        _headerController.status == AnimationStatus.completed) {
      _headerController.reverse();
    }
  }

  void _initializeFromEvent() {
    final event = widget.event;

    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _startDate = event.startTime.toLocal();
    _startTime = TimeOfDay.fromDateTime(event.startTime.toLocal());
    _endTime = TimeOfDay.fromDateTime(event.endTime.toLocal());
    _category = event.category;
    _isFree = event.isFree;
    final price = event.price ?? 0;
    _priceController.text = _isFree ? '' : price.toString();
    _capacityController.text = event.maxAttendees.toString();
    if (event.imageUrls.isNotEmpty) {
      _coverImageUrl = event.imageUrls.first;
    }

    _location = LocationData(
      name: event.location.name,
      address: event.location.address,
      latitude: event.location.latitude,
      longitude: event.location.longitude,
    );
  }


  void _markFieldChanged(String fieldName) {
    if (_updatedFields.add(fieldName)) {
      setState(() {
        _hasChanges = true;
      });
      _fabController.forward();
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? finalImageUrl = _coverImageUrl;
      if (_coverImage != null) {
        finalImageUrl = _coverImageUrl;
      }

      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: _combineDateTime(_startDate!, _startTime!),
        endTime: _combineDateTime(_startDate!, _endTime!),
        location: EventLocation(
          name: _location?.name ?? widget.event.location.name,
          address: _location?.address ?? widget.event.location.address,
          latitude: _location?.latitude ?? widget.event.location.latitude,
          longitude: _location?.longitude ?? widget.event.location.longitude,
        ),
        category: _category,
        isFree: _isFree,
        price: _isFree ? null : (double.tryParse(_priceController.text) ?? 0),
        maxAttendees:
            int.tryParse(_capacityController.text) ?? widget.event.maxAttendees,
        imageUrls: finalImageUrl != null
            ? [finalImageUrl]
            : widget.event.imageUrls,
      );

      if (mounted) {
        context.read<EventsBloc>().add(UpdateEventRequested(updatedEvent));
        context.read<MyEventsBloc>().add(const RefreshMyEvents());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Color(0xFFBBC863),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Event berhasil diupdate!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFBBC863),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate event: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildCoverSection(),
                  const SizedBox(height: 24),
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  _buildDateTimeCard(),
                  const SizedBox(height: 16),
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                  _buildCategoryCard(),
                  const SizedBox(height: 16),
                  _buildPricingCard(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  /// 🎨 Modern Glass Morphism AppBar
  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1A1A1A),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hasChanges
                ? const Color(0xFFBBC863)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.check_rounded,
                    color: _hasChanges ? Colors.white : AppColors.border,
                  ),
            onPressed: (_hasChanges && !_isSaving) ? _saveChanges : null,
          ),
        ),
      ],
      title: Text(
        'Edit Event',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      centerTitle: true,
    );
  }

  /// 📸 Cover Image Section with Modern Upload UI
  Widget _buildCoverSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _pickImage,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFBBC863).withValues(alpha: 0.1),
                  const Color(0xFFBBC863).withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _coverImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _coverImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _coverImage = null;
                                _coverImageUrl = null;
                                _markFieldChanged('imageUrl');
                              });
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tap untuk ganti foto',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _coverImageUrl != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          _coverImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildEmptyCover();
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tap untuk ganti foto',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildEmptyCover(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCover() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 32,
              color: Color(0xFFBBC863),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Foto Sampul',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rekomendasi: 16:9, minimal 1080p',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  /// ✏️ Title & Description Section
  Widget _buildTitleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Event',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              labelText: 'Judul Event',
              hintText: 'Contoh: Workshop UI/UX Design',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.border,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceAlt, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFBBC863),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Judul event harus diisi';
              }
              if (value.trim().length < 5) {
                return 'Judul minimal 5 karakter';
              }
              return null;
            },
            onChanged: (_) => _markFieldChanged('title'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              labelText: 'Deskripsi Event',
              hintText: 'Jelaskan detail event kamu dengan menarik...',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.border,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceAlt, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFBBC863),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Deskripsi harus diisi';
              }
              if (value.trim().length < 20) {
                return 'Deskripsi minimal 20 karakter';
              }
              return null;
            },
            onChanged: (_) => _markFieldChanged('description'),
          ),
        ],
      ),
    );
  }

  /// 📅 Date & Time Card
  Widget _buildDateTimeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: Color(0xFFBBC863),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tanggal & Waktu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTimeSelector(start: true)),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Color(0xFFBBC863),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeSelector(start: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceAlt),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 24,
              color: _startDate != null
                  ? const Color(0xFFBBC863)
                  : AppColors.border,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Event',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startDate != null
                        ? DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(_startDate!)
                        : 'Pilih tanggal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _startDate != null
                          ? const Color(0xFF1A1A1A)
                          : AppColors.border,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({required bool start}) {
    final time = start ? _startTime : _endTime;
    final label = start ? 'Mulai' : 'Selesai';

    return InkWell(
      onTap: () => _selectTime(isStartTime: start),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceAlt),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time != null
                  ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : '--:--',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: time != null
                    ? const Color(0xFF1A1A1A)
                    : AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📍 Location Card
  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: Color(0xFFBBC863),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lokasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LocationPicker(
            initialLocation: _location,
            onLocationSelected: (location) {
              setState(() {
                _location = location;
                _markFieldChanged('location');
              });
            },
          ),
        ],
      ),
    );
  }

  /// 🏷️ Category Card with Modern Chips
  Widget _buildCategoryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  size: 20,
                  color: Color(0xFFBBC863),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kategori',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: EventCategory.values.map((category) {
              final isSelected = _category == category;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFBBC863)
                      : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFBBC863,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _category = category;
                        _markFieldChanged('category');
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        category.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textEmphasis,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 💰 Pricing Card
  Widget _buildPricingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isFree
                      ? Icons.card_giftcard_rounded
                      : Icons.payments_rounded,
                  size: 20,
                  color: const Color(0xFFBBC863),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Harga Tiket',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isFree
                  ? const Color(0xFFBBC863).withValues(alpha: 0.08)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFree
                    ? const Color(0xFFBBC863).withValues(alpha: 0.3)
                    : AppColors.surfaceAlt,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isFree
                      ? Icons.money_off_rounded
                      : Icons.attach_money_rounded,
                  size: 28,
                  color: _isFree
                      ? const Color(0xFFBBC863)
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isFree ? 'Event Gratis' : 'Event Berbayar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isFree
                            ? 'Siapa saja bisa ikut'
                            : 'Peserta perlu membeli tiket',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !_isFree,
                  onChanged: (value) {
                    setState(() {
                      _isFree = !value;
                      if (_isFree) {
                        _priceController.clear();
                      }
                      _markFieldChanged('isFree');
                    });
                  },
                  activeTrackColor: const Color(0xFFBBC863),
                ),
              ],
            ),
          ),
          if (!_isFree) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                labelText: 'Harga Tiket',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFBBC863),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceAlt, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFBBC863),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (!_isFree && (value == null || value.isEmpty)) {
                  return 'Harga harus diisi';
                }
                if (!_isFree && value != null && value.isNotEmpty) {
                  final price = double.tryParse(value);
                  if (price == null || price < 1000) {
                    return 'Harga minimal Rp 1.000';
                  }
                }
                return null;
              },
              onChanged: (_) => _markFieldChanged('price'),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              labelText: 'Kapasitas Maksimum',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
              hintText: 'Jumlah peserta',
              suffixText: 'orang',
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceAlt, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFBBC863),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kapasitas harus diisi';
              }
              final capacity = int.tryParse(value);
              if (capacity == null || capacity < 1) {
                return 'Kapasitas minimal 1';
              }
              return null;
            },
            onChanged: (_) => _markFieldChanged('maxAttendees'),
          ),
        ],
      ),
    );
  }

  /// 🎯 Modern Floating Action Button
  Widget _buildModernFAB() {
    if (!_hasChanges) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveChanges,
        backgroundColor: const Color(0xFFBBC863),
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_rounded),
        label: Text(
          'Simpan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih tanggal event',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBBC863),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _markFieldChanged('startTime');
      });
    }
  }

  Future<void> _selectTime({required bool isStartTime}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      helpText: isStartTime ? 'Waktu mulai' : 'Waktu selesai',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBBC863),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          if (_endTime != null &&
              _endTime!.hour < picked.hour &&
              _endTime!.minute < picked.minute) {
            _endTime = picked;
          }
        } else {
          _endTime = picked;
        }
        _markFieldChanged('startTime');
      });
    }
  }

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFBBC863),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Fitur upload foto akan segera hadir!'),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
