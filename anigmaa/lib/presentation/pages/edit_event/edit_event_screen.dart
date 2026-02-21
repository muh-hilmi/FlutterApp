import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event_location.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/my_events/my_events_bloc.dart';
import '../../bloc/my_events/my_events_event.dart';
import '../../widgets/common/location_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Simplified Edit Event Screen
class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  LocationData? _location;
  EventCategory _category = EventCategory.meetup;
  bool _isFree = true;
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeFromEvent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
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
      maxAttendees: int.tryParse(_capacityController.text) ?? widget.event.maxAttendees,
      imageUrls: _coverImageUrl != null ? [_coverImageUrl!] : widget.event.imageUrls,
    );

    if (mounted) {
      context.read<EventsBloc>().add(UpdateEventRequested(updatedEvent));
      context.read<MyEventsBloc>().add(const RefreshMyEvents());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil diupdate!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Event', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text('Simpan', style: AppTextStyles.button.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image
            _buildCoverSection(),
            const SizedBox(height: 16),

            // Title
            _buildSectionTitle('Judul Event'),
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Contoh: Workshop UI/UX Design',
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            _buildSectionTitle('Deskripsi'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Jelaskan detail event...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date & Time
            _buildSectionTitle('Tanggal & Waktu'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: _selectDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Text(
                      _startDate != null
                          ? DateFormat('d MMM yyyy').format(_startDate!)
                          : 'Pilih tanggal',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTimeSelector('Mulai', _startTime, () => _selectTime(isStartTime: true))),
                const SizedBox(width: 8),
                Expanded(child: _buildTimeSelector('Selesai', _endTime, () => _selectTime(isStartTime: false))),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            _buildSectionTitle('Lokasi'),
            LocationPicker(
              initialLocation: _location,
              onLocationSelected: (location) {
                setState(() => _location = location);
              },
            ),
            const SizedBox(height: 16),

            // Category
            _buildSectionTitle('Kategori'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventCategory.values.map((category) {
                final isSelected = _category == category;
                return FilterChip(
                  label: Text(category.displayName, style: AppTextStyles.bodySmall),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _category = category);
                  },
                  selectedColor: AppColors.secondary,
                  checkmarkColor: AppColors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Pricing
            _buildSectionTitle('Harga Tiket'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(_isFree ? Icons.card_giftcard : Icons.payments,
                      size: 20, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Text(_isFree ? 'Gratis' : 'Berbayar', style: AppTextStyles.bodyMediumBold),
                  const Spacer(),
                  Switch(
                    value: !_isFree,
                    onChanged: (value) {
                      setState(() {
                        _isFree = !value;
                        if (_isFree) _priceController.clear();
                      });
                    },
                    activeThumbColor: AppColors.secondary,
                  ),
                ],
              ),
            ),
            if (!_isFree) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (!_isFree && (value == null || value.isEmpty)) {
                    return 'Harga harus diisi';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kapasitas',
                suffixText: 'orang',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kapasitas harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTextStyles.bodyMediumBold),
    );
  }

  Widget _buildCoverSection() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: _coverImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_coverImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildEmptyCover()),
            )
          : _buildEmptyCover(),
    );
  }

  Widget _buildEmptyCover() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('Foto Sampul', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '--:--',
              style: AppTextStyles.h3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectTime({required bool isStartTime}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
}
