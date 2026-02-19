import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event_host.dart';
import '../../../domain/entities/event_location.dart';
import '../../../domain/entities/ticket.dart';
import '../../../core/constants/app_colors.dart' as legacyColors;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../../core/services/auth_service.dart';
import '../../bloc/tickets/tickets_bloc.dart';
import '../../bloc/tickets/tickets_event.dart';
import '../../bloc/tickets/tickets_state.dart';
import '../event_detail/event_detail_screen.dart';
import '../../../injection_container.dart' as di;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    // Load user tickets to get attended events
    final authService = di.sl<AuthService>();
    final userId = authService.userId;
    if (userId != null) {
      context.read<TicketsBloc>().add(LoadUserTickets(userId));
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  /// Convert tickets to event objects for calendar display
  List<Event> _ticketsToEvents(List<Ticket> tickets) {
    return tickets
        .where((ticket) => ticket.eventStartTime != null && ticket.eventTitle != null)
        .map<Event>((ticket) {
      return Event(
        id: ticket.eventId,
        title: ticket.eventTitle!,
        description: '',
        startTime: ticket.eventStartTime!,
        endTime: ticket.eventStartTime!.add(const Duration(hours: 2)),
        location: EventLocation(
          name: ticket.eventLocation ?? 'Unknown Location',
          address: ticket.eventLocation ?? '',
          latitude: 0.0,
          longitude: 0.0,
        ),
        category: EventCategory.social,
        isFree: ticket.isFree,
        price: ticket.pricePaid,
        host: const EventHost(
          id: '',
          name: 'Event Host',
          avatar: '',
          bio: '',
        ),
        maxAttendees: 0,
        createdAt: ticket.purchasedAt,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<TicketsBloc, TicketsState>(
        listener: (context, state) {
          if (state is TicketsError) {
            AppLogger().error('Calendar screen error: ${state.message}');
          }
        },
        builder: (context, state) {
          if (state is TicketsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TicketsLoaded) {
            // Convert tickets to events for calendar display
            _allEvents = _ticketsToEvents(state.tickets);

            return CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: _buildCalendar(),
                ),
                SliverToBoxAdapter(
                  child: _buildSelectedDayEvents(),
                ),
              ],
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      floating: true,
      snap: true,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar',
                style: AppTextStyles.bodyLargeBold.copyWith(
                  fontSize: 18,
                ),
              ),
              Text(
                'Event Schedule',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            });
          },
          icon: const Icon(
            Icons.today,
            color: AppColors.textEmphasis,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<Event>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: AppColors.error),
          holidayTextStyle: TextStyle(color: AppColors.error),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppColors.textEmphasis,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppColors.textEmphasis,
          ),
          titleTextStyle: TextStyle(
            color: AppColors.textEmphasis,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Event>[];

    if (selectedEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No events scheduled',
              style: AppTextStyles.bodyLargeBold.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No events on ${_formatSelectedDate()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Events on ${_formatSelectedDate()}',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: selectedEvents.length,
          itemBuilder: (context, index) {
            return _buildEventCard(selectedEvents[index]);
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: legacyColors.AppColors.getCategoryColor(event.category),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: AppTextStyles.bodyLargeBold.copyWith(
                              color: AppColors.textEmphasis,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: legacyColors.AppColors.getCategoryColor(event.category).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            EventCategoryUtils.getCategoryName(event.category),
                            style: AppTextStyles.label.copyWith(
                              color: legacyColors.AppColors.getCategoryColor(event.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(event.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.currentAttendees}/${event.maxAttendees} going',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (event.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Free',
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (!event.isFree)
                          Text(
                            'Rp ${event.price!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No calendar data available',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate() {
    if (_selectedDay == null) return 'Selected Day';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[_selectedDay!.month - 1];
    final day = _selectedDay!.day;
    final year = _selectedDay!.year;

    return '$month $day, $year';
  }

  String _formatTime(DateTime dateTime) {
    // IMPORTANT: Convert to local time before formatting (best practice)
    final localDateTime = dateTime.toLocal();
    final hour = localDateTime.hour;
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}