import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../bloc/my_events/my_events_bloc.dart';
import '../../bloc/my_events/my_events_event.dart';
import '../../bloc/my_events/my_events_state.dart';
import '../event_participants/event_participants_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../create_event/create_event_conversation.dart';
import '../event_management/event_management_dashboard.dart';
import '../event_summary/event_summary_screen.dart';
import '../../../injection_container.dart' as di;

/// Modern "My Events" screen with clean, card-based design
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
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              BlocBuilder<MyEventsBloc, MyEventsState>(
                builder: (context, state) {
                  if (state is MyEventsLoading) {
                    return const Expanded(child: _LoadingState());
                  }

                  if (state is MyEventsError) {
                    return Expanded(child: _ErrorState(message: state.message));
                  }

                  if (state is MyEventsLoaded) {
                    if (state.events.isEmpty) {
                      return const Expanded(child: _EmptyState());
                    }

                    final activeEvents = state.events
                        .where((e) => e.isActive)
                        .toList();
                    final completedEvents = state.events
                        .where((e) => e.isCompleted)
                        .toList();
                    final archivedEvents = state.events
                        .where((e) => e.isArchived)
                        .toList();

                    if (activeEvents.isEmpty && completedEvents.isEmpty && archivedEvents.isEmpty) {
                      return const Expanded(child: _EmptyState());
                    }

                    return Expanded(
                      child: Column(
                        children: [
                          _buildTabBar(),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _ActiveEventsTab(events: activeEvents),
                                _CompletedEventsTab(events: completedEvents),
                                _ArchivedEventsTab(events: archivedEvents),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const Expanded(child: _EmptyState());
                },
              ),
            ],
          ),
        ),
        floatingActionButton: _buildCreateEventFAB(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Text(
            'Event Gue',
            style: AppTextStyles.h2.copyWith(letterSpacing: -0.5),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<MyEventsBloc>().add(const RefreshMyEvents());
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.bodyMediumBold,
          unselectedLabelStyle: AppTextStyles.bodyMediumBold,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
            Tab(text: 'Arsip'),
          ],
        ),
      ),
    );
  }
}

class _ActiveEventsTab extends StatelessWidget {
  final List<Event> events;

  const _ActiveEventsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyTabState(
        icon: Icons.upcoming_outlined,
        title: 'Belum Ada Event Aktif',
        subtitle: 'Event yang akan datang akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MyEventsBloc>().add(const RefreshMyEvents());
      },
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _ModernEventCard(event: events[index], isActive: true);
        },
      ),
    );
  }
}

class _CompletedEventsTab extends StatelessWidget {
  final List<Event> events;

  const _CompletedEventsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyTabState(
        icon: Icons.history,
        title: 'Belum Ada Event Selesai',
        subtitle: 'Event yang sudah selesai akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MyEventsBloc>().add(const RefreshMyEvents());
      },
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _ModernEventCard(event: events[index], isActive: false);
        },
      ),
    );
  }
}

class _ArchivedEventsTab extends StatelessWidget {
  final List<Event> events;

  const _ArchivedEventsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyTabState(
        icon: Icons.archive_outlined,
        title: 'Belum Ada Event Arsip',
        subtitle: 'Event yang diarsip akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MyEventsBloc>().add(const RefreshMyEvents());
      },
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _ArchivedEventCard(event: events[index]);
        },
      ),
    );
  }
}

/// Modern card design for events
class _ModernEventCard extends StatelessWidget {
  final Event event;
  final bool isActive;

  const _ModernEventCard({required this.event, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final attendeesCount = event.attendeeIds.length;
    final maxAttendees = event.maxAttendees;
    final isFull = attendeesCount >= maxAttendees;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with status badge overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: event.fullImageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.fullImageUrls.first,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.secondary.withValues(alpha: 0.3),
                                AppColors.secondary.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              // Status badge
              Positioned(
                top: 12,
                left: 12,
                child: _StatusBadge(event: event, isActive: isActive),
              ),
              // Price badge
              if (event.isFree)
                Positioned(
                  top: 12,
                  right: 56,
                  child: _PriceBadge(text: 'GRATIS', isFree: true),
                )
              else if (event.price != null)
                Positioned(
                  top: 12,
                  right: 56,
                  child: _PriceBadge(
                    text: 'Rp ${event.price!.toInt().toString()}',
                    isFree: false,
                  ),
                ),
              // Menu button
              Positioned(
                top: 8,
                right: 8,
                child: _EventMenuButton(event: event, isActive: isActive),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: AppTextStyles.bodyLargeBold.copyWith(
                    letterSpacing: -0.3,
                    color: AppColors.textEmphasis,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Date row
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDateRange(event.startTime, event.endTime),
                ),
                const SizedBox(height: 4),

                // Time row
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text: _formatTimeRange(event.startTime, event.endTime),
                ),
                const SizedBox(height: 4),

                // Location row
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: event.location.name,
                ),
                const SizedBox(height: 8),

                // Stats
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_outline_rounded,
                      label: '$attendeesCount/$maxAttendees',
                      color: isFull ? AppColors.error : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    if (!event.isFree && event.ticketsSold > 0)
                      _StatChip(
                        icon: Icons.confirmation_number_outlined,
                        label: '${event.ticketsSold} terjual',
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.2),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.event_outlined, size: 36, color: AppColors.secondary),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (isActive) {
      return Row(
        children: [
          Expanded(
            child: _ModernButton(
              icon: Icons.manage_accounts_outlined,
              label: 'Kelola',
              color: AppColors.primary,
              isFilled: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventManagementDashboard(eventId: event.id),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<MyEventsBloc>().add(const RefreshMyEvents());
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModernButton(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Check-in',
              color: AppColors.primary,
              isFilled: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventParticipantsScreen(eventId: event.id),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<MyEventsBloc>().add(const RefreshMyEvents());
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          _DeleteButton(event: event),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _ModernButton(
              icon: Icons.analytics_outlined,
              label: 'Ringkasan',
              color: AppColors.primary,
              isFilled: false,
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
            child: _ModernButton(
              icon: Icons.restore,
              label: 'Re-Run',
              color: AppColors.secondary,
              isFilled: true,
              onTap: () => _showReRunDialog(context, event),
            ),
          ),
        ],
      );
    }
  }

  void _showReRunDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Buat Event Lagi?',
          style: AppTextStyles.h3.copyWith(color: AppColors.textEmphasis),
        ),
        content: Text(
          'Buat event baru berdasarkan "${event.title}" dengan data yang sama.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final templateEvent = Event(
                id: '',
                title: event.title,
                description: event.description,
                category: event.category,
                startTime: DateTime.now().add(const Duration(days: 7)),
                endTime: DateTime.now().add(const Duration(days: 7, hours: 3)),
                location: event.location,
                host: event.host,
                imageUrls: event.imageUrls,
                maxAttendees: event.maxAttendees,
                price: event.price,
                isFree: event.isFree,
                status: EventStatus.upcoming,
                attendeeIds: const [],
                ticketsSold: 0,
                interestedUserIds: const [],
                requirements: event.requirements,
                waitlistIds: const [],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateEventConversation(event: templateEvent),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Buat',
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = [
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
    return '${start.day} ${months[start.month - 1]} ${start.year}';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}

/// Archived event card with grayed out appearance
class _ArchivedEventCard extends StatelessWidget {
  final Event event;

  const _ArchivedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final attendeesCount = event.attendeeIds.length;
    final maxAttendees = event.maxAttendees;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with grayscale filter and archived badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: event.fullImageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.fullImageUrls.first,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.textTertiary.withValues(alpha: 0.3),
                                  AppColors.textTertiary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              // Archived badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.archive_outlined, size: 12, color: AppColors.white),
                      const SizedBox(width: 4),
                      Text(
                        'ARSIP',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: AppTextStyles.bodyLargeBold.copyWith(
                    letterSpacing: -0.3,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Date row
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDateRange(event.startTime, event.endTime),
                ),
                const SizedBox(height: 4),

                // Time row
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text: _formatTimeRange(event.startTime, event.endTime),
                ),
                const SizedBox(height: 4),

                // Location row
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: event.location.name,
                ),
                const SizedBox(height: 8),

                // Stats
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      icon: Icons.people_outline_rounded,
                      label: '$attendeesCount/$maxAttendees',
                      color: AppColors.textTertiary,
                    ),
                    if (!event.isFree && event.ticketsSold > 0)
                      _StatChip(
                        icon: Icons.confirmation_number_outlined,
                        label: '${event.ticketsSold} terjual',
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textTertiary.withValues(alpha: 0.2),
            AppColors.textTertiary.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.event_outlined, size: 36, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModernButton(
            icon: Icons.unarchive,
            label: 'Pulihkan',
            color: AppColors.secondary,
            isFilled: true,
            onTap: () => _showRestoreDialog(context, event),
          ),
        ),
        const SizedBox(width: 8),
        _DeleteButton(event: event),
      ],
    );
  }

  void _showRestoreDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pulihkan Event?',
          style: AppTextStyles.h3.copyWith(color: AppColors.textEmphasis),
        ),
        content: Text(
          'Pulihkan "${event.title}" dari arsip?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MyEventsBloc>().add(UnarchiveMyEvent(event.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Pulihkan',
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = [
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
    return '${start.day} ${months[start.month - 1]} ${start.year}';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final Event event;
  final bool isActive;

  const _StatusBadge({required this.event, required this.isActive});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (isActive) {
      // Check if event is currently happening
      final now = DateTime.now().toUtc();
      final isOngoing =
          now.isAfter(event.startTime.toUtc()) &&
          now.isBefore(event.endTime.toUtc());

      if (isOngoing) {
        text = 'SEDANG BERLANGSUNG';
        color = AppColors.success;
      } else {
        text = 'AKAN DATANG';
        color = AppColors.secondary;
      }
    } else {
      text = 'SELESAI';
      color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Price badge widget
class _PriceBadge extends StatelessWidget {
  final String text;
  final bool isFree;

  const _PriceBadge({required this.text, required this.isFree});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: isFree ? AppColors.success : AppColors.textEmphasis,
        ),
      ),
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Stat chip widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern button widget
class _ModernButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isFilled;
  final VoidCallback onTap;

  const _ModernButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isFilled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isFilled ? AppColors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFilled ? AppColors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete button widget
class _DeleteButton extends StatefulWidget {
  final Event event;

  const _DeleteButton({required this.event});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final canDelete =
        widget.event.attendeeIds.isEmpty && !widget.event.hasEnded;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: canDelete ? () => _showDeleteDialog(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isPressed
              ? AppColors.error.withValues(alpha: 0.2)
              : (canDelete ? AppColors.error.withValues(alpha: 0.08) : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 20,
          color: canDelete ? AppColors.error : AppColors.textTertiary,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Event?',
          style: AppTextStyles.h3.copyWith(color: AppColors.textEmphasis),
        ),
        content: Text(
          'Lo yakin mau hapus "${widget.event.title}"?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MyEventsBloc>().add(DeleteMyEvent(widget.event.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus',
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }
}

/// Event menu button widget
class _EventMenuButton extends StatelessWidget {
  final Event event;
  final bool isActive;

  const _EventMenuButton({required this.event, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.more_vert,
          size: 18,
          color: AppColors.textEmphasis,
        ),
      ),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        if (value == 'archive') {
          context.read<MyEventsBloc>().add(ArchiveMyEvent(event.id));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'archive',
          child: Row(
            children: [
              const Icon(
                Icons.archive_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Arsipkan',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textEmphasis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty tab state widget
class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTabState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.secondary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(color: AppColors.textEmphasis),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Loading state widget
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
      ),
    );
  }
}

/// Error state widget
class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<MyEventsBloc>().add(const LoadMyEvents());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Coba Lagi',
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 64,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Event',
            style: AppTextStyles.h3.copyWith(color: AppColors.textEmphasis),
          ),
          const SizedBox(height: 8),
          Text(
            'Yuk bikin event seru sekarang!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Create event FAB
Widget _buildCreateEventFAB(BuildContext context) {
  return FloatingActionButton.extended(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateEventConversation(),
        ),
      ).then((_) {
        if (context.mounted) {
          context.read<MyEventsBloc>().add(const RefreshMyEvents());
        }
      });
    },
    backgroundColor: AppColors.secondary,
    icon: const Icon(Icons.add_rounded),
    label: Text(
      'Bikin Event',
      style: AppTextStyles.button.copyWith(
        color: AppColors.primary,
        letterSpacing: -0.3,
      ),
    ),
  );
}
