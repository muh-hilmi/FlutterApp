import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart' show LoadEventById;
import '../../bloc/events/events_state.dart';
import '../../bloc/my_events/my_events_bloc.dart';
import '../../bloc/my_events/my_events_event.dart';
import '../../bloc/my_events/my_events_state.dart';
import '../edit_event/edit_event_screen.dart';
import 'host_qna_screen.dart';
import '../event_participants/event_participants_screen.dart';
import '../../../injection_container.dart' as di;

/// Event Management Dashboard - Tab-based interface for event hosts
///
/// Features:
/// - Overview Tab: Event info + quick edit
/// - Q&A Tab: Manage questions (answer, delete)
/// - Attendees Tab: View attendees + check-in
/// - Analytics Tab: Revenue, transactions, charts
class EventManagementDashboard extends StatefulWidget {
  final String eventId;

  const EventManagementDashboard({
    super.key,
    required this.eventId,
  });

  @override
  State<EventManagementDashboard> createState() =>
      _EventManagementDashboardState();
}

class _EventManagementDashboardState extends State<EventManagementDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Event? _event;
  late final EventsBloc _eventsBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Get bloc instance once and reuse it
    _eventsBloc = di.sl<EventsBloc>();
    _loadEventData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventData() async {
    debugPrint('[EventManagementDashboard] _loadEventData called for eventId: ${widget.eventId}');

    // Try to get event from MyEventsBloc first (faster, cached)
    final myEventsState = di.sl<MyEventsBloc>().state;
    debugPrint('[EventManagementDashboard] MyEventsBloc state type: ${myEventsState.runtimeType}');

    if (myEventsState is MyEventsLoaded) {
      debugPrint('[EventManagementDashboard] MyEventsBloc has ${myEventsState.events.length} events');
      try {
        final event = myEventsState.events.firstWhere(
          (e) => e.id == widget.eventId,
        );
        debugPrint('[EventManagementDashboard] Found event in MyEventsBloc cache: ${event.title}');
        if (mounted) {
          setState(() {
            _event = event;
          });
        }
        return; // Found in cache, no need to load from EventsBloc
      } catch (_) {
        debugPrint('[EventManagementDashboard] Event not found in MyEventsBloc cache');
        // Event not found in cache, will load from EventsBloc
      }
    }

    // Load from EventsBloc for fresh data
    debugPrint('[EventManagementDashboard] Loading from EventsBloc...');
    _eventsBloc.add(LoadEventById(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _eventsBloc),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kelola Event',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (_event?.title != null)
                Text(
                  _event!.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFBBC863),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            indicatorColor: const Color(0xFFBBC863),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'EDIT', icon: Icon(Icons.edit_outlined, size: 20)),
              Tab(text: 'Q&A', icon: Icon(Icons.question_answer, size: 20)),
              Tab(text: 'PESERTA', icon: Icon(Icons.people_outline, size: 20)),
              Tab(text: 'ANALITIK', icon: Icon(Icons.analytics_outlined, size: 20)),
            ],
          ),
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            debugPrint('[EventManagementDashboard] BlocBuilder - state type: ${state.runtimeType}');

            // Update _event from state
            if (state is EventsLoaded) {
              debugPrint('[EventManagementDashboard] EventsLoaded - events count: ${state.events.length}');
              debugPrint('[EventManagementDashboard] EventsLoaded - event IDs: ${state.events.map((e) => e.id).toList()}');
              debugPrint('[EventManagementDashboard] Looking for eventId: ${widget.eventId}');

              try {
                final event = state.events.firstWhere(
                  (e) => e.id == widget.eventId,
                );
                debugPrint('[EventManagementDashboard] FOUND event: ${event.title}');

                if (_event == null || _event!.id != event.id) {
                  debugPrint('[EventManagementDashboard] Setting _event to: ${event.title}');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _event = event;
                      });
                      debugPrint('[EventManagementDashboard] _event is now set: ${_event?.title}');
                    }
                  });
                }
              } catch (_) {
                debugPrint('[EventManagementDashboard] Event ${widget.eventId} not found in EventsLoaded state');
              }
            } else if (state is EventsError) {
              debugPrint('[EventManagementDashboard] EventsError: ${state.message}');
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildEditTab(state),
                HostQnAScreen(
                  eventId: widget.eventId,
                  eventTitle: _event?.title,
                ),
                EventParticipantsScreen(
                  eventId: widget.eventId,
                  maxAttendees: _event?.maxAttendees,
                ),
                _buildAnalyticsTab(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditTab(EventsState state) {
    if (_event != null) {
      return EditEventScreen(event: _event!);
    }

    if (state is EventsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _eventsBloc.add(LoadEventById(widget.eventId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBC863),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFBBC863)),
          SizedBox(height: 16),
          Text(
            'Memuat event...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFBBC863),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(EventsState state) {
    if (_event != null) {
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
              child: const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Color(0xFFBBC863),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analitik Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_event!.attendeeIds.length} Tiket Terjual',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (_event!.price != null && _event!.price! > 0)
              Text(
                'Total: ${_formatCurrency(_event!.price! * _event!.attendeeIds.length)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBBC863),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Fitur analitik lengkap akan segera hadir!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (state is EventsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFBBC863)),
          SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFBBC863),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp $amount';
  }
}
