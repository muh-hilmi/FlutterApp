import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_host.dart';
import '../../../domain/entities/event_location.dart';
import '../../../domain/usecases/create_event.dart';
import '../../../domain/usecases/update_event.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../widgets/common/location_picker.dart';
import '../../../../injection_container.dart' as di;
import '../../../core/services/auth_service.dart';
import '../../../core/services/upload_service.dart';
import 'components/chat_message_model.dart';
import 'components/message_bubble.dart';
import 'components/typing_indicator.dart';
import 'components/event_preview_card.dart';
import 'components/category_selector.dart';
import 'components/price_selector.dart';
import 'components/image_options_selector.dart';
import '../event_detail/event_detail_screen.dart';

class _EditOption {
  final IconData icon;
  final String label;
  final String subtitle;
  final ConversationStep step;

  _EditOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.step,
  });
}

class CreateEventConversation extends StatefulWidget {
  /// Optional event to edit. If provided, the screen operates in edit mode
  final Event? event;

  const CreateEventConversation({super.key, this.event});

  @override
  State<CreateEventConversation> createState() =>
      _CreateEventConversationState();
}

class _CreateEventConversationState extends State<CreateEventConversation>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  ConversationStep _currentStep = ConversationStep.greeting;
  bool _isTyping = false;
  bool _waitingForInput = false;
  List<String> _activeQuickReplies = [];
  bool _isEditingFromPreview = false;

  // Event data
  String _eventTitle = '';
  String _eventDescription = '';
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  LocationData? _location;
  EventCategory _category = EventCategory.meetup;
  bool _isFree = true;
  double _price = 0;
  int _capacity = 50;
  File? _coverImage;
  bool _isSubmitting = false;

  // Edit mode
  bool get _isEditMode => widget.event != null && widget.event!.id.isNotEmpty;
  // Re-run mode (create new event from template)
  bool get _isReRunMode => widget.event != null && widget.event!.id.isEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _initializeEditMode();
    } else if (_isReRunMode) {
      _initializeReRunMode();
    } else {
      _startConversation();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _initializeEditMode() {
    final event = widget.event!;
    _eventTitle = event.title;
    _eventDescription = event.description;
    _startDate = event.startTime;
    _startTime = TimeOfDay.fromDateTime(event.startTime);
    _endTime = TimeOfDay.fromDateTime(event.endTime);
    _location = LocationData(
      name: event.location.name,
      address: event.location.address,
      latitude: event.location.latitude,
      longitude: event.location.longitude,
    );
    _category = event.category;
    _isFree = event.isFree;
    _price = event.price ?? 0;
    _capacity = event.maxAttendees;

    // Add initial bot message for edit mode
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _addBotMessage('Halo! 👋\n\nYuk edit event "${event.title}".');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        _currentStep = ConversationStep.preview;
        _showPreview();
      });
    });
  }

  void _initializeReRunMode() {
    final templateEvent = widget.event!;
    _eventTitle = templateEvent.title;
    _eventDescription = templateEvent.description;
    _startDate = templateEvent
        .startTime; // This is a future date set by my_events_screen
    _startTime = TimeOfDay.fromDateTime(templateEvent.startTime);
    _endTime = TimeOfDay.fromDateTime(templateEvent.endTime);
    _location = LocationData(
      name: templateEvent.location.name,
      address: templateEvent.location.address,
      latitude: templateEvent.location.latitude,
      longitude: templateEvent.location.longitude,
    );
    _category = templateEvent.category;
    _isFree = templateEvent.isFree;
    _price = templateEvent.price ?? 0;
    _capacity = templateEvent.maxAttendees;

    // Start conversation with pre-filled data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _addBotMessage(
        'Halo! 👋\n\nYuk bikin event lagi berdasarkan "${templateEvent.title}".\n\nData udah diisi otomatis, lo tinggal sesuaikan tanggal & lokasi aja ya!',
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _currentStep = ConversationStep.preview;
        _showPreview();
      });
    });
  }

  void _startConversation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _addBotMessage('Halo! 👋\n\nYuk bikin event bareng!');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _showQuickReplies(['Mulai Buat Event 🚀']);
      });
    });
  }

  void _addBotMessage(String text, {Widget? customWidget}) {
    if (!mounted) return;
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: text, isBot: true, customWidget: customWidget),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isBot: false));
      _waitingForInput = false;
    });
    _scrollToBottom();
    _inputController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickReplies(List<String> replies) {
    setState(() {
      _waitingForInput = true;
      _activeQuickReplies = replies;
    });
  }

  void _handleQuickReply(String reply) {
    setState(() {
      _activeQuickReplies = [];
    });

    // Handle retry buttons for pickers
    if (reply == 'Pilih Tanggal 📅') {
      _addUserMessage(reply);
      _showDatePicker(isStart: true);
      return;
    } else if (reply == 'Pilih Jam Mulai 🕐') {
      _addUserMessage(reply);
      _showTimePicker(isStart: true);
      return;
    } else if (reply == 'Pilih Jam Selesai 🕐') {
      _addUserMessage(reply);
      _showTimePicker(isStart: false);
      return;
    } else if (reply == 'Pilih Lokasi 📍') {
      _addUserMessage(reply);
      _showLocationPicker();
      return;
    }

    // Normal flow
    _addUserMessage(reply);
    _moveToNextStep();
  }

  void _moveToNextStep() {
    // Check if editing from preview BEFORE any async operations
    // This ensures we capture the correct state even if it changes during async delays
    final isEditing = _isEditingFromPreview;
    if (isEditing) {
      setState(() {
        _isEditingFromPreview = false;
        _currentStep = ConversationStep.preview;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _addBotMessage('Perfect! Ini preview eventnya:');
        _showPreview();
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      switch (_currentStep) {
        case ConversationStep.greeting:
          _currentStep = ConversationStep.askStartDate;
          _addBotMessage('Keren! 🎉\n\nKapan eventnya dimulai?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showDatePicker(isStart: true);
          });
          break;

        case ConversationStep.askStartDate:
          _currentStep = ConversationStep.askStartTime;
          String dateStr = DateFormat('dd MMMM yyyy').format(_startDate!);
          _addBotMessage('Oke tanggal $dateStr 📅\n\nJam berapa mulainya?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showTimePicker(isStart: true);
          });
          break;

        case ConversationStep.askStartTime:
          _currentStep = ConversationStep.askEndTime;
          _addBotMessage('Sip! 🕐\n\nSampai jam berapa eventnya?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showTimePicker(isStart: false);
          });
          break;

        case ConversationStep.askEndTime:
          _currentStep = ConversationStep.askLocation;
          _addBotMessage('Perfect! 🕐\n\nDimana tempatnya nih?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showLocationPicker();
          });
          break;

        case ConversationStep.askLocation:
          _currentStep = ConversationStep.askName;
          _addBotMessage('Lokasi oke! 📍\n\nSekarang, apa nama eventnya?');
          _waitForTextInput();
          break;

        case ConversationStep.askName:
          _currentStep = ConversationStep.askDescription;
          _addBotMessage(
            'Nice! "$_eventTitle" 🔥\n\nCeritain dong, eventnya tentang apa?',
          );
          _waitForTextInput(multiline: true);
          break;

        case ConversationStep.askDescription:
          _currentStep = ConversationStep.askCategory;
          _addBotMessage('Mantap! 📝\n\nMasuk kategori apa nih eventnya?');
          _showCategorySelector();
          break;

        case ConversationStep.askCategory:
          _currentStep = ConversationStep.askPrice;
          String categoryName = EventCategoryUtils.getCategoryDisplayName(
            _category,
          );
          _addBotMessage(
            '$categoryName ya! ✨\n\nEvent ini gratis atau berbayar?',
          );
          _showPriceSelector();
          break;

        case ConversationStep.askPrice:
          _currentStep = ConversationStep.askCapacity;
          if (_isFree) {
            _addBotMessage(
              'Gratis! Asik banget 🎁\n\nBisa muat berapa orang nih?\n\n💡 Minimal 3 orang (kamu + 2 teman)',
            );
          } else {
            String priceStr = CurrencyFormatter.formatToRupiah(_price);
            _addBotMessage(
              'Harga $priceStr per orang 💰\n\nBisa muat berapa orang nih?\n\n💡 Minimal 3 orang (kamu + 2 teman)',
            );
          }
          _waitForNumberInput();
          break;

        case ConversationStep.askCapacity:
          _currentStep = ConversationStep.askImage;
          _addBotMessage(
            'Oke kapasitas $_capacity orang! 👥\n\nTerakhir, mau tambahin foto cover?',
          );
          _showImageOptions();
          break;

        case ConversationStep.askImage:
          _currentStep = ConversationStep.preview;
          _addBotMessage('Perfect! Ini preview eventnya:');
          _showPreview();
          break;

        default:
          break;
      }
    });
  }

  void _waitForTextInput({bool multiline = false}) {
    setState(() => _waitingForInput = true);
  }

  void _waitForNumberInput() {
    setState(() => _waitingForInput = true);
  }

  void _handleTextInput(String text) {
    if (text.trim().isEmpty) return;

    switch (_currentStep) {
      case ConversationStep.askName:
        _eventTitle = text.trim();
        break;
      case ConversationStep.askDescription:
        final trimmedDescription = text.trim();
        // Backend requires minimum 10 characters for description
        if (trimmedDescription.length < 10) {
          _addBotMessage(
            '⚠️ Deskripsi event terlalu pendek. Minimal 10 karakter ya!',
          );
          _waitForTextInput(multiline: true);
          return;
        }
        _eventDescription = trimmedDescription;
        break;
      case ConversationStep.askCapacity:
        final capacityValue = int.tryParse(text) ?? 50;
        _capacity = capacityValue < 3 ? 3 : capacityValue;
        if (capacityValue < 3) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _addBotMessage(
                '⚠️ Minimal kapasitas 3 orang ya (kamu + 2 teman).',
              );
            }
          });
        }
        break;
      default:
        break;
    }

    _addUserMessage(text);
    _moveToNextStep();
  }

  void _showDatePicker({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFBBC863)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _activeQuickReplies = [];
      });
      _startDate = date;
      String dateStr = DateFormat('dd MMMM yyyy').format(date);
      _addUserMessage(dateStr);
      _moveToNextStep();
    } else {
      // User canceled, show retry option
      _addBotMessage(
        'Oke, kalau udah siap pilih tanggalnya, klik tombol ini ya! 📅',
      );
      _showQuickReplies(['Pilih Tanggal 📅']);
    }
  }

  void _showTimePicker({required bool isStart}) async {
    // Calculate initial end time (start time + 2 hours)
    TimeOfDay initialEndTime = const TimeOfDay(hour: 21, minute: 0);
    if (_startTime != null) {
      int endHour = (_startTime!.hour + 2) % 24;
      initialEndTime = TimeOfDay(hour: endHour, minute: _startTime!.minute);
    }

    final time = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 19, minute: 0)
          : initialEndTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFFBBC863)),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time != null) {
      // Validate end time
      if (!isStart && _startTime != null) {
        final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
        final endMinutes = time.hour * 60 + time.minute;

        if (endMinutes == startMinutes) {
          _addBotMessage(
            'Oops! ⏰ Jam mulai dan selesai tidak boleh sama. Event minimal harus ada durasinya dong!',
          );
          _showQuickReplies(['Pilih Jam Selesai 🕐']);
          return;
        }
      }

      setState(() {
        _activeQuickReplies = [];
      });
      if (isStart) {
        _startTime = time;
      } else {
        _endTime = time;
      }

      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      final timeStr = DateFormat('HH:mm').format(dt);
      _addUserMessage(timeStr);
      _moveToNextStep();
    } else {
      // User canceled, show retry option
      String message = isStart
          ? 'Oke, kalau udah siap pilih jam mulainya, klik tombol ini ya! 🕐'
          : 'Oke, kalau udah siap pilih jam selesainya, klik tombol ini ya! 🕐';
      _addBotMessage(message);
      _showQuickReplies(
        isStart ? ['Pilih Jam Mulai 🕐'] : ['Pilih Jam Selesai 🕐'],
      );
    }
  }

  void _showLocationPicker() async {
    final result = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPicker(
        onLocationSelected: (locationData) {
          Navigator.pop(context, locationData);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _activeQuickReplies = [];
      });
      _location = result;
      _addUserMessage('📍 ${result.name}');
      _moveToNextStep();
    } else {
      // User canceled, show retry option
      _addBotMessage(
        'Oke, kalau udah siap pilih lokasinya, klik tombol ini ya! 📍',
      );
      _showQuickReplies(['Pilih Lokasi 📍']);
    }
  }

  void _showCategorySelector() {
    setState(() => _waitingForInput = true);
  }

  void _showPriceSelector() {
    setState(() => _waitingForInput = true);
  }

  void _showImageOptions() {
    setState(() => _waitingForInput = true);
  }

  void _showPriceInput() async {
    final priceController = TextEditingController();

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    const Text(
                      'Berapa Harganya? 💰',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan harga per orang dalam Rupiah',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: const Color(0xFFBBC863),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Minimal Rp 1.000, maksimal Rp 1.000.000',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFBBC863),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Price input with modern card style
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFCFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFBBC863,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Rp',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFBBC863),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                              decoration: InputDecoration(
                                hintText: '50.000',
                                hintStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[300],
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              autofocus: true,
                              maxLength: 7,
                              onChanged: (value) {
                                // Format with thousand separator
                                final digits = value.replaceAll('.', '');
                                if (digits.isNotEmpty) {
                                  final number = int.tryParse(digits) ?? 0;
                                  // Enforce maximum price of 1,000,000
                                  if (number > 1000000) return;
                                  final formatted = NumberFormat(
                                    '#,###',
                                    'id_ID',
                                  ).format(number);
                                  // Update controller without triggering onChanged loop
                                  if (formatted != value) {
                                    priceController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(
                                        offset: formatted.length,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final digits = priceController.text.replaceAll(
                            '.',
                            '',
                          );
                          final price = double.tryParse(digits);
                          if (price != null && price > 0 && price <= 1000000) {
                            Navigator.pop(context, price);
                          } else if (price != null && price > 1000000) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Maksimal harga Rp 1.000.000',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Masukkan harga yang valid',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBBC863),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan Harga 💵',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      _price = result;
      String priceStr = CurrencyFormatter.formatToRupiah(_price);
      _addUserMessage(priceStr);
      _moveToNextStep();
    }
  }

  void _showPreview() {
    // Show preview card in chat
    final previewWidget = EventPreviewCard(
      title: _eventTitle,
      description: _eventDescription,
      startDate: _startDate!,
      startTime: _startTime!,
      endTime: _endTime!,
      locationName: _location?.name ?? 'Lokasi',
      category: _category,
      isFree: _isFree,
      price: _price,
      capacity: _capacity,
      coverImage: _coverImage,
      onTap: () => _showFullPreview(),
    );

    _addBotMessage('', customWidget: previewWidget);
    setState(() => _waitingForInput = true);
  }

  void _showFullPreview() {
    // Create a temporary Event object for preview
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final tempEvent = Event(
      id: 'preview',
      title: _eventTitle,
      description: _eventDescription,
      category: _category,
      startTime: startDateTime,
      endTime: endDateTime,
      location: EventLocation(
        name: _location?.name ?? 'Lokasi',
        address: _location?.address ?? '',
        latitude: _location?.latitude ?? 0.0,
        longitude: _location?.longitude ?? 0.0,
      ),
      host: EventHost(id: 'preview', name: 'Nama Host', avatar: '', bio: ''),
      imageUrls: _coverImage != null ? [_coverImage!.path] : [],
      maxAttendees: _capacity,
      price: _isFree ? null : _price,
      isFree: _isFree,
      status: EventStatus.upcoming,
      attendeeIds: const [],
      interestedUserIds: const [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: tempEvent),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFBBC863).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFBBC863)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Batalkan Event?'),
            content: const Text(
              'Progress kamu bakal ilang nih kalau keluar sekarang. Yakin?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nggak Jadi'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ya, Keluar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showUploadErrorDialog(String error) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must click a button
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Upload Gagal!', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Masalah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.contains('Connection refused')
                              ? 'Backend server untuk upload tidak berjalan.'
                              : 'Gagal mengupload cover image.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Apa yang ingin kamu lakukan?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu bisa lanjut buat event tanpa cover, atau batalkan untuk coba lagi nanti.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Lanjut Tanpa Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBC863),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleBackNavigation() async {
    final shouldPop = await _showExitConfirmationDialog();
    if (shouldPop && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFBBC863)),
            onPressed: _handleBackNavigation,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode ? 'Edit Event' : 'Buat Event Baru',
                key: const Key('create_event_title'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _isEditMode ? 'Ubah detail event' : 'Isi detail event kamu',
                key: const Key('create_event_subtitle'),
                style: const TextStyle(
                  color: Color(0xFFBBC863),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          toolbarHeight: 64,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (_waitingForInput && _activeQuickReplies.isNotEmpty)
              _buildQuickRepliesArea(),
            if (_waitingForInput && _activeQuickReplies.isEmpty)
              _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _activeQuickReplies
                .map((reply) => _buildQuickReply(reply))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    Widget inputWidget;

    // If there are active quick replies, show them
    if (_activeQuickReplies.isNotEmpty) {
      inputWidget = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _activeQuickReplies
            .map((reply) => _buildQuickReply(reply))
            .toList(),
      );
    } else {
      switch (_currentStep) {
        case ConversationStep.greeting:
          inputWidget = Center(child: _buildQuickReply('Mulai Buat Event 🚀'));
          break;

        case ConversationStep.askCategory:
          inputWidget = CategorySelector(
            onCategorySelected: (category) {
              _category = category;
              String categoryName = EventCategoryUtils.getCategoryDisplayName(
                category,
              );
              _addUserMessage(categoryName);
              _moveToNextStep();
            },
          );
          break;

        case ConversationStep.askPrice:
          inputWidget = PriceSelector(
            onOptionSelected: (isFree) {
              _isFree = isFree;
              if (isFree) {
                _price = 0;
                _addUserMessage('Gratis 🎁');
                _moveToNextStep();
              } else {
                _showPriceInput();
              }
            },
          );
          break;

        case ConversationStep.askImage:
          inputWidget = ImageOptionsSelector(
            onOptionSelected: (source) async {
              if (source == null) {
                _addUserMessage('Skip foto');
                _moveToNextStep();
              } else {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: source);
                if (image != null) {
                  _coverImage = File(image.path);
                  _addUserMessage('Foto terupload! ✅');
                  _moveToNextStep();
                }
              }
            },
          );
          break;

        case ConversationStep.preview:
          inputWidget = _buildPreviewActions();
          break;

        default:
          inputWidget = _buildTextInput();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(top: false, child: inputWidget),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () {
        _handleQuickReply(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBBC863), Color(0xFFA8B657)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBBC863).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    final isCapacityStep = _currentStep == ConversationStep.askCapacity;

    // For capacity step, use a custom counter widget
    if (isCapacityStep) {
      return _buildCapacitySelector();
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: _currentStep == ConversationStep.askDescription ? 3 : 1,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: _getInputHint(),
              filled: true,
              fillColor: const Color(0xFFFCFCFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: Color(0xFFBBC863),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _handleTextInput(_inputController.text),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _handleTextInput(_inputController.text),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFBBC863),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBBC863).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current capacity display
          Center(
            child: Column(
              children: [
                Text(
                  '$_capacity',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Text(
                  'orang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Slider for quick selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Geser untuk ubah jumlah',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '3 - 500',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFBBC863),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFBBC863),
                  inactiveTrackColor: const Color(
                    0xFFBBC863,
                  ).withValues(alpha: 0.2),
                  thumbColor: const Color(0xFFBBC863),
                  overlayColor: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                ),
                child: Slider(
                  value: _capacity.toDouble(),
                  min: 3,
                  max: 500,
                  divisions: 497,
                  label: '$_capacity orang',
                  onChanged: (value) {
                    setState(() {
                      _capacity = value.round();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quick preset buttons
          Text(
            'Pilih cepat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPresetButton(10),
              const SizedBox(width: 10),
              _buildPresetButton(25),
              const SizedBox(width: 10),
              _buildPresetButton(50),
              const SizedBox(width: 10),
              _buildPresetButton(100),
            ],
          ),
          const SizedBox(height: 20),
          // Direct input option
          InkWell(
            onTap: _showDirectInputDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 18, color: const Color(0xFFBBC863)),
                  const SizedBox(width: 8),
                  Text(
                    'Input Manual',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFBBC863),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Helper text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minimal 3 orang (kamu + 2 teman)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _handleTextInput(_capacity.toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBC863),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Lanjut',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int value) {
    final isSelected = _capacity == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _capacity = value;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFBBC863) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFBBC863) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  void _showDirectInputDialog() {
    final controller = TextEditingController(text: _capacity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masukkan Jumlah Peserta'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '3 - 500',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 3 && value <= 500) {
                setState(() {
                  _capacity = value;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan angka 3 - 500'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _getInputHint() {
    switch (_currentStep) {
      case ConversationStep.askName:
        return 'Nama event kamu...';
      case ConversationStep.askDescription:
        return 'Ceritain eventnya...';
      default:
        return 'Ketik disini...';
    }
  }

  Widget _buildPreviewActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit button row
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFBBC863).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton.icon(
            onPressed: _showEditOptions,
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFFBBC863)),
            label: const Text(
              'Edit Detail Event ✏️',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBBC863),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleBackNavigation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFBBC863)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBBC863),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBC863),
                  disabledBackgroundColor: const Color(
                    0xFFBBC863,
                  ).withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Simpan Perubahan 💾' : 'Buat Event! 🎉',
                        key: const Key('create_event_submit_button'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Color(0xFFBBC863), size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              // Edit options
              ..._buildEditOptions(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEditOptions() {
    final options = [
      _EditOption(
        icon: Icons.calendar_today,
        label: 'Tanggal & Jam',
        subtitle:
            '${DateFormat('dd MMM yyyy').format(_startDate!)} • ${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}',
        step: ConversationStep.askStartDate,
      ),
      _EditOption(
        icon: Icons.location_on,
        label: 'Lokasi',
        subtitle: _location?.name ?? 'Lokasi',
        step: ConversationStep.askLocation,
      ),
      _EditOption(
        icon: Icons.title,
        label: 'Nama Event',
        subtitle: _eventTitle,
        step: ConversationStep.askName,
      ),
      _EditOption(
        icon: Icons.description,
        label: 'Deskripsi',
        subtitle: _eventDescription.length > 30
            ? '${_eventDescription.substring(0, 30)}...'
            : _eventDescription,
        step: ConversationStep.askDescription,
      ),
      _EditOption(
        icon: Icons.category,
        label: 'Kategori',
        subtitle: EventCategoryUtils.getCategoryDisplayName(_category),
        step: ConversationStep.askCategory,
      ),
      _EditOption(
        icon: _isFree ? Icons.card_giftcard : Icons.attach_money,
        label: 'Harga',
        subtitle: _isFree ? 'Gratis' : CurrencyFormatter.formatToRupiah(_price),
        step: ConversationStep.askPrice,
      ),
      _EditOption(
        icon: Icons.people,
        label: 'Kapasitas',
        subtitle: '$_capacity orang',
        step: ConversationStep.askCapacity,
      ),
      _EditOption(
        icon: Icons.image,
        label: 'Cover Image',
        subtitle: _coverImage != null ? 'Foto terupload' : 'Belum ada foto',
        step: ConversationStep.askImage,
      ),
    ];

    return options.map((option) => _buildEditOptionTile(option)).toList();
  }

  Widget _buildEditOptionTile(_EditOption option) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _goToEditStep(option.step);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option.icon,
                size: 20,
                color: const Color(0xFFBBC863),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  void _goToEditStep(ConversationStep step) {
    // Set the step and show appropriate message based on what's being edited
    setState(() {
      _currentStep = step;
      _waitingForInput = false;
      _activeQuickReplies = [];
      _isEditingFromPreview =
          true; // Set flag so we return to preview after edit
    });

    // Add a message to indicate we're editing
    String editMessage = '';
    switch (step) {
      case ConversationStep.askStartDate:
        editMessage = 'Oke, kita edit tanggal & jamnya 📅';
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showDatePicker(isStart: true);
        });
        break;
      case ConversationStep.askStartTime:
        editMessage = 'Oke, kita edit jamnya 🕐';
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showTimePicker(isStart: true);
        });
        break;
      case ConversationStep.askLocation:
        editMessage = 'Oke, kita edit lokasinya 📍';
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showLocationPicker();
        });
        break;
      case ConversationStep.askName:
        editMessage = 'Oke, kita edit nama eventnya ✍️';
        _waitForTextInput();
        break;
      case ConversationStep.askDescription:
        editMessage = 'Oke, kita edit deskripsinya 📝';
        _waitForTextInput(multiline: true);
        break;
      case ConversationStep.askCategory:
        editMessage = 'Oke, kita edit kategorinya 🏷️';
        _showCategorySelector();
        break;
      case ConversationStep.askPrice:
        editMessage = 'Oke, kita edit harganya 💰';
        _showPriceSelector();
        break;
      case ConversationStep.askCapacity:
        editMessage = 'Oke, kita edit kapasitasnya 👥';
        _waitForNumberInput();
        break;
      case ConversationStep.askImage:
        editMessage = 'Oke, kita edit covernya 🖼️';
        _showImageOptions();
        break;
      default:
        break;
    }

    if (editMessage.isNotEmpty) {
      _addBotMessage(editMessage);
    }
  }

  void _submitEvent() async {
    if (_isSubmitting) return;

    // Validate required fields
    if (_eventTitle.isEmpty ||
        _eventDescription.isEmpty ||
        _startDate == null ||
        _startTime == null ||
        _endTime == null ||
        _location == null) {
      _addBotMessage('⚠️ Data belum lengkap. Silakan mulai dari awal.');
      _currentStep = ConversationStep.greeting;
      _messages.clear();
      _startConversation();
      return;
    }

    if (mounted) setState(() => _isSubmitting = true);

    try {
      // Get current user for host info
      final authService = di.sl<AuthService>();
      final userId = authService.userId;

      if (userId == null) {
        _addBotMessage('⚠️ Silakan login terlebih dahulu.');
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      // Get user profile from UserBloc for complete host info
      String userName = authService.userName ?? 'User';
      String? userAvatar;
      String? userBio;

      if (context.read<UserBloc>().state is UserLoaded) {
        final userState = context.read<UserBloc>().state as UserLoaded;
        userName = userState.user.name;
        userAvatar = userState.user.avatar;
        userBio = userState.user.bio;
        AppLogger().info('Using user profile from UserBloc: $userName');
      } else {
        AppLogger().warning(
          'UserBloc not in loaded state, using basic auth info',
        );
      }

      // Upload cover image if selected (only for new events)
      List<String> imageUrls = [];
      AppLogger().info(
        '[CreateEvent] _isEditMode: $_isEditMode, _isReRunMode: $_isReRunMode, _coverImage: $_coverImage',
      );

      if (!_isEditMode && !_isReRunMode && _coverImage != null) {
        _addBotMessage('📤 Mengupload cover image...');
        try {
          final uploadService = UploadService();
          final imageUrl = await uploadService.uploadImage(_coverImage!);
          imageUrls = [imageUrl];
          AppLogger().info('Cover image uploaded: $imageUrl');
          _addBotMessage('✅ Cover image berhasil diupload!');
        } catch (e) {
          AppLogger().error('Failed to upload cover image: $e');
          // Show dialog for upload error
          final shouldContinue = await _showUploadErrorDialog(e.toString());
          if (!shouldContinue) {
            if (mounted) setState(() => _isSubmitting = false);
            return; // Stop event creation
          }
          // User chose to continue without image
          _addBotMessage('⚠️ Event akan dibuat tanpa cover image.');
        }
      } else if (_isEditMode || _isReRunMode) {
        // Keep existing images in edit mode or re-run mode
        imageUrls = widget.event!.imageUrls;
        AppLogger().info(
          '[CreateEvent] Edit/Re-run mode - keeping existing images: $imageUrls',
        );
      } else {
        AppLogger().warning('[CreateEvent] No cover image to upload');
      }

      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // If end time is before start time, assume it's the next day
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime.add(const Duration(days: 1));
      }

      // Create Event entity
      AppLogger().info(
        '[CreateEvent] Creating event with imageUrls: $imageUrls',
      );
      AppLogger().info(
        '[CreateEvent] startDateTime BEFORE Event: $startDateTime (isUtc: ${startDateTime.isUtc})',
      );
      AppLogger().info(
        '[CreateEvent] endDateTime BEFORE Event: $endDateTime (isUtc: ${endDateTime.isUtc})',
      );

      final event = Event(
        id: _isEditMode ? widget.event!.id : '', // Use existing ID for edit
        title: _eventTitle,
        description: _eventDescription,
        category: _category,
        startTime: startDateTime,
        endTime: endDateTime,
        location: EventLocation(
          name: _location!.name,
          address: _location!.address,
          latitude: _location!.latitude,
          longitude: _location!.longitude,
        ),
        host: EventHost(
          id: userId,
          name: userName,
          avatar: userAvatar ?? '',
          bio: userBio ?? '',
        ),
        imageUrls: imageUrls,
        maxAttendees: _capacity,
        price: _isFree ? null : _price,
        isFree: _isFree,
        status:
            (_isEditMode || _isReRunMode) &&
                widget.event!.status == EventStatus.cancelled
            ? EventStatus
                  .upcoming // Reset cancelled events to upcoming
            : EventStatus.upcoming,
        attendeeIds:
            const [], // Always start fresh (no attendees for new/re-run events)
        interestedUserIds:
            const [], // Always start fresh (no interested users for new/re-run events)
      );

      if (_isEditMode) {
        // Update existing event
        final updateEventUseCase = di.sl<UpdateEvent>();
        final result = await updateEventUseCase(
          UpdateEventParams(event: event),
        );

        result.fold(
          (failure) {
            AppLogger().error('Failed to update event: $failure');
            String errorMessage = failure.message;

            // Parse backend validation errors and show user-friendly messages
            if (errorMessage.contains('MaxAttendees') &&
                errorMessage.contains('min')) {
              errorMessage =
                  '❌ Minimal kapasitas 3 orang ya (kamu + 2 teman). Silakan ubah kapasitasnya.';
            } else if (errorMessage.contains('Invalid body request')) {
              errorMessage =
                  '❌ Data tidak valid. Mohon periksa kembali isian Anda.';
            } else if (errorMessage.contains('Field validation')) {
              errorMessage = '❌ ${failure.message}';
            } else {
              errorMessage = '❌ Gagal mengupdate event: ${failure.message}';
            }

            _addBotMessage(errorMessage);
            if (mounted) setState(() => _isSubmitting = false);
          },
          (updatedEvent) {
            AppLogger().info('Event updated successfully: ${updatedEvent.id}');
            _addBotMessage(
              '🎉 Event berhasil diupdate! "${updatedEvent.title}"',
            );

            // Refresh events list
            context.read<EventsBloc>().add(LoadEvents());

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context, updatedEvent);
              }
            });
          },
        );
      } else {
        // Create new event
        final createEventUseCase = di.sl<CreateEvent>();
        final result = await createEventUseCase(
          CreateEventParams(event: event),
        );

        result.fold(
          (failure) {
            AppLogger().error('Failed to create event: $failure');
            String errorMessage = failure.message;

            // Parse backend validation errors and show user-friendly messages
            if (errorMessage.contains('MaxAttendees') &&
                errorMessage.contains('min')) {
              errorMessage =
                  '❌ Minimal kapasitas 3 orang ya (kamu + 2 teman). Silakan ubah kapasitasnya.';
            } else if (errorMessage.contains('Invalid body request')) {
              errorMessage =
                  '❌ Data tidak valid. Mohon periksa kembali isian Anda.';
            } else if (errorMessage.contains('Field validation')) {
              errorMessage = '❌ ${failure.message}';
            } else {
              errorMessage = '❌ Gagal membuat event: ${failure.message}';
            }

            _addBotMessage(errorMessage);
            if (mounted) setState(() => _isSubmitting = false);
          },
          (createdEvent) {
            AppLogger().info('Event created successfully: ${createdEvent.id}');
            AppLogger().info(
              'Created event imageUrls: ${createdEvent.imageUrls}',
            );
            _addBotMessage('🎉 Event berhasil dibuat! "${createdEvent.title}"');

            // Refresh events list
            context.read<EventsBloc>().add(LoadEvents());

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context, createdEvent);
              }
            });
          },
        );
      }
    } catch (e, stackTrace) {
      AppLogger().error(
        'Error ${_isEditMode ? 'updating' : 'creating'} event: $e\n$stackTrace',
      );
      _addBotMessage('❌ Terjadi kesalahan: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
