import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../bloc/my_events/my_events_bloc.dart';
import '../../bloc/my_events/my_events_event.dart';
import '../../bloc/my_events/my_events_state.dart';
import '../event_participants/event_participants_screen.dart';
import '../create_event/create_event_conversation.dart';
import '../event_management/event_management_dashboard.dart';
import '../event_summary/event_summary_screen.dart';
import '../../../injection_container.dart' as di;

/// Screen displaying events created by the current user
/// Features:
/// - Tabs: "Aktif" (upcoming/ongoing) and "Selesai" (ended)
/// - List of user's hosted events with key details
/// - Edit, Delete, and Check-in actions (for active events)
/// - Event Summary with analytics (for completed events)
/// - Empty state when no events
/// - FAB to create new event
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MyEventsBloc>()..add(const LoadMyEvents()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: BlocBuilder<MyEventsBloc, MyEventsState>(
          builder: (context, state) {
            if (state is MyEventsLoading) {
              return _buildLoadingState();
            }

            if (state is MyEventsError) {
              return _buildErrorState(context, state.message);
            }

            if (state is MyEventsLoaded) {
              if (state.events.isEmpty) {
                return _buildEmptyState(context);
              }

              final activeEvents = state.events.where((e) => e.isActive).toList();
              final completedEvents = state.events.where((e) => e.isCompleted).toList();

              if (activeEvents.isEmpty && completedEvents.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  // Tab bar
                  _buildTabBar(state.events),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveEventsTab(activeEvents),
                        _buildCompletedEventsTab(completedEvents),
                      ],
                    ),
                  ),
                ],
              );
            }

            return _buildEmptyState(context);
          },
        ),
        floatingActionButton: _buildCreateEventFAB(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      key: const Key('my_events_app_bar'),
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Event Gue',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A1A),
        ),
      ),
      leading: IconButton(
        key: const Key('my_events_back_button'),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF1A1A1A),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          key: const Key('my_events_refresh_button'),
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () {
            context.read<MyEventsBloc>().add(const RefreshMyEvents());
          },
        ),
      ],
    );
  }

  Widget _buildTabBar(List<Event> allEvents) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFBBC863),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          indicatorColor: const Color(0xFFBBC863),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              text: 'AKTIF',
              icon: const Icon(Icons.play_circle_outline, size: 20),
            ),
            Tab(
              text: 'SELESAI',
              icon: const Icon(Icons.check_circle_outline, size:20),
            ),
          ],
        ),
        Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildActiveEventsTab(List<Event> activeEvents) {
    if (activeEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upcoming_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Event Aktif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Event yang akan datang/berlangsung akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const Key('active_events_refresh_indicator'),
      onRefresh: () async {
        context.read<MyEventsBloc>().add(const RefreshMyEvents());
      },
      color: const Color(0xFFBBC863),
      child: ListView.builder(
        key: const Key('active_events_list'),
        padding: const EdgeInsets.all(16),
        itemCount: activeEvents.length,
        itemBuilder: (context, index) {
          return _buildEventCard(context, activeEvents[index], isActive: true);
        },
      ),
    );
  }

  Widget _buildCompletedEventsTab(List<Event> completedEvents) {
    if (completedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
            size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Event Selesai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Event yang sudah selesai akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const Key('completed_events_refresh_indicator'),
      onRefresh: () async {
        context.read<MyEventsBloc>().add(const RefreshMyEvents());
      },
      color: const Color(0xFFBBC863),
      child: ListView.builder(
        key: const Key('completed_events_list'),
        padding: const EdgeInsets.all(16),
        itemCount: completedEvents.length,
        itemBuilder: (context, index) {
          return _buildEventCard(context, completedEvents[index], isActive: false);
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, {required bool isActive}) {
    final attendeesCount = event.attendeeIds.length;
    final maxAttendees = event.maxAttendees;
    final isFull = attendeesCount >= maxAttendees;

    return Container(
      key: Key('my_events_event_card_${event.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFBBC863).withValues(alpha: 0.3)
              : (Colors.blue[700] ?? Colors.blue).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image or placeholder
          if (event.fullImageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: CachedNetworkImage(
                imageUrl: event.fullImageUrls.first,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFBBC863),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  AppLogger().error('[MyEvents] Failed to load image for "${event.title}"');
                  AppLogger().error('[MyEvents] URL: $url');
                  AppLogger().error('[MyEvents] Error: $error');
                  return _buildImagePlaceholder();
                },
              ),
            )
          else
            _buildImagePlaceholder(),

          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Row(
                  children: [
                    Text(
                      _formatDate(event.startTime),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  event.title,
                  key: Key('my_events_event_title_${event.id}'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Date & Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDateTime(event.startTime, event.endTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    // Attendees count
                    Icon(
                      isFull ? Icons.people_rounded : Icons.person_outline_rounded,
                      size: 15,
                      color: isFull ? Colors.red[600] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$attendeesCount/$maxAttendees',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFull ? Colors.red[700] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tickets sold (if not free)
                    if (!event.isFree)
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 15,
                            color: const Color(0xFFBBC863),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${event.ticketsSold} terjual',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFBBC863),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                _buildActionButtons(context, event, isActive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Event event, bool isActive) {
    if (isActive) {
      // Active events: Kelola, Check-in, Delete
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              key: Key('my_events_manage_button_${event.id}'),
              icon: Icons.manage_accounts_outlined,
              label: 'Kelola',
              color: const Color(0xFFBBC863),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventManagementDashboard(
                      eventId: event.id,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    if (!context.mounted) return;
                    context.read<MyEventsBloc>().add(const RefreshMyEvents());
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              key: Key('my_events_checkin_button_${event.id}'),
              icon: Icons.qr_code_scanner_rounded,
              label: 'Check-in',
              color: const Color(0xFF1A1A1A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventParticipantsScreen(
                      eventId: event.id,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    if (!context.mounted) return;
                    context.read<MyEventsBloc>().add(const RefreshMyEvents());
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          _buildDeleteButton(context, event),
        ],
      );
    } else {
      // Completed events: Lihat Ringkasan, Re-run
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              key: Key('my_events_summary_button_${event.id}'),
              icon: Icons.analytics_outlined,
              label: 'Lihat Ringkasan',
              color: const Color(0xFF1A1A1A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventSummaryScreen(event: event),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              key: Key('my_events_rerun_button_${event.id}'),
              icon: Icons.restore,
              label: 'Re-Run',
              color: const Color(0xFFBBC863),
              onTap: () {
                _showReRunDialog(context, event);
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFBBC863).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.event_outlined,
          size: 48,
          color: Color(0xFFBBC863),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, Event event) {
    // Only allow deletion if no attendees and event hasn't started
    final canDelete = event.attendeeIds.isEmpty && !event.hasEnded;

    return InkWell(
      key: Key('my_events_delete_button_${event.id}'),
      onTap: canDelete
          ? () => _showDeleteDialog(context, event)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: canDelete
              ? Colors.red[50]
              : Colors.grey[100],
          border: Border.all(
            color: canDelete
                ? Colors.red[300]!
                : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 18,
          color: canDelete
              ? Colors.red[700]
              : Colors.grey[400],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('my_events_delete_dialog_${event.id}'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hapus Event?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Lo yakin mau hapus "${event.title}"? Tindakan ini nggak bisa dibatalin.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('my_events_delete_cancel_button'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          ElevatedButton(
            key: Key('my_events_delete_confirm_button_${event.id}'),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MyEventsBloc>().add(DeleteMyEvent(event.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReRunDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('my_events_rerun_dialog_${event.id}'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Buat Event Lagi?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Buat event baru berdasarkan "${event.title}" dengan data yang sama. Lo tetap perlu setting tanggal & lokasi.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tips: Lo bisa edit tanggal, lokasi, dan harga setelah event dibuat.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Create a template event from the completed event
              // This will pre-fill the form with existing data
              final templateEvent = Event(
                id: '', // Empty ID = create new event
                title: event.title,
                description: event.description,
                category: event.category,
                startTime: DateTime.now().add(const Duration(days: 7)), // Default: 1 week from now
                endTime: DateTime.now().add(const Duration(days: 7)).add(const Duration(hours: 3)), // Default: 3 hours duration
                location: event.location,
                host: event.host,
                imageUrls: event.imageUrls,
                maxAttendees: event.maxAttendees,
                price: event.price,
                isFree: event.isFree,
                status: EventStatus.upcoming, // Reset to upcoming
                requirements: event.requirements,
                // Reset counters
                attendeeIds: const [],
                ticketsSold: 0,
                interestedUserIds: const [],
                waitlistIds: const [],
              );

              // Navigate to create event with pre-filled data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEventConversation(event: templateEvent),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Buat',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBBC863)),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('my_events_retry_button'),
            onPressed: () {
              context.read<MyEventsBloc>().add(const LoadMyEvents());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 64,
              color: const Color(0xFFBBC863),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yakin bikin event seru sekarang!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEventFAB(BuildContext context) {
    return FloatingActionButton.extended(
      key: const Key('my_events_create_fab'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateEventConversation(),
          ),
        ).then((_) {
          if (mounted) {
            context.read<MyEventsBloc>().add(const RefreshMyEvents());
          }
        });
      },
      backgroundColor: const Color(0xFFBBC863),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Bikin Event',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final months = [
      'Jan', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${localDate.day} ${months[localDate.month - 1]}';
  }

  String _formatDateTime(DateTime start, DateTime end) {
    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final startDay = localStart.day;
    final startMonth = months[localStart.month - 1];
    final startHour = localStart.hour.toString().padLeft(2, '0');
    final startMinute = localStart.minute.toString().padLeft(2, '0');

    final endHour = localEnd.hour.toString().padLeft(2, '0');
    final endMinute = localEnd.minute.toString().padLeft(2, '0');

    return '$startDay $startMonth, $startHour:$startMinute - $endHour:$endMinute';
  }
}
