import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart' show LoadEventById;
import '../../bloc/events/events_state.dart';
import '../../bloc/my_events/my_events_bloc.dart';
import '../../bloc/my_events/my_events_state.dart';
import '../edit_event/edit_event_screen.dart';
import 'host_qna_screen.dart';
import '../event_participants/event_participants_screen.dart';
import '../../../injection_container.dart' as di;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Event Management Dashboard — Tab-based interface for event hosts.
///
/// Tabs: Edit · Peserta · Q&A · Analitik
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
    _eventsBloc = di.sl<EventsBloc>();
    _loadEventData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventData() async {
    // Try cache first (faster)
    final myEventsState = di.sl<MyEventsBloc>().state;
    if (myEventsState is MyEventsLoaded) {
      try {
        final event = myEventsState.events.firstWhere(
          (e) => e.id == widget.eventId,
        );
        if (mounted) setState(() => _event = event);
        return;
      } catch (_) {}
    }
    _eventsBloc.add(LoadEventById(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: _eventsBloc)],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            if (state is EventsLoaded) {
              try {
                final event = state.events.firstWhere(
                  (e) => e.id == widget.eventId,
                );
                if (_event == null || _event!.id != event.id) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _event = event);
                  });
                }
              } catch (_) {}
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildEditTab(state),
                EventParticipantsScreen(
                  eventId: widget.eventId,
                  maxAttendees: _event?.maxAttendees,
                ),
                HostQnAScreen(
                  eventId: widget.eventId,
                  eventTitle: _event?.title,
                ),
                _buildAnalyticsTab(state),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kelola Event', style: AppTextStyles.h3),
          if (_event?.title != null)
            Text(
              _event!.title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            labelStyle: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.secondary, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            tabs: const [
              Tab(text: 'Edit'),
              Tab(text: 'Peserta'),
              Tab(text: 'Q&A'),
              Tab(text: 'Analitik'),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit Tab ─────────────────────────────────────────────────────────────

  Widget _buildEditTab(EventsState state) {
    if (_event != null) return EditEventScreen(event: _event!);
    if (state is EventsError) return _buildErrorState(state.message);
    return _buildLoadingState();
  }

  // ─── Analytics Tab ────────────────────────────────────────────────────────

  Widget _buildAnalyticsTab(EventsState state) {
    if (_event == null) {
      if (state is EventsError) return _buildErrorState(state.message);
      return _buildLoadingState();
    }

    final event = _event!;
    final ticketsSold = event.attendeeIds.length;
    final maxTickets = event.maxAttendees ?? 0;
    final occupancyRate = maxTickets > 0 ? ticketsSold / maxTickets : 0.0;
    final revenue = (event.price ?? 0) * ticketsSold;
    final isFree = event.isFree || (event.price == null || event.price == 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Ringkasan', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Data tiket dan kehadiran event kamu',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),

          // Stat cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Tiket Terjual',
                  value: '$ticketsSold',
                  sub: maxTickets > 0 ? 'dari $maxTickets tiket' : 'tak terbatas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Pendapatan',
                  value: isFree ? 'Gratis' : _formatCurrency(revenue),
                  sub: isFree
                      ? 'event gratis'
                      : '${_formatCurrency(event.price ?? 0)}/tiket',
                ),
              ),
            ],
          ),

          // Capacity progress bar
          if (maxTickets > 0) ...[
            const SizedBox(height: 12),
            _buildCapacityCard(ticketsSold, maxTickets, occupancyRate),
          ],

          // Event detail info
          const SizedBox(height: 12),
          _buildEventInfoCard(event),

          // Coming soon note
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Grafik & analitik lengkap akan hadir di versi berikutnya!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(letterSpacing: -1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            sub,
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityCard(int sold, int max, double rate) {
    final percent = (rate * 100).toStringAsFixed(0);
    Color barColor = AppColors.secondary;
    if (rate >= 0.9) barColor = AppColors.error;
    else if (rate >= 0.7) barColor = AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kapasitas',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rate >= 1.0
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rate >= 1.0 ? 'Penuh!' : '$percent% terisi',
                  style: AppTextStyles.caption.copyWith(
                    color: rate >= 1.0 ? AppColors.error : AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$sold dari $max kursi terisi',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard(Event event) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dt = event.startTime;
    final dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} WIB';
    final isFree = event.isFree || (event.price == null || event.price == 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Event',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Tanggal & Waktu',
            '$dateStr • $timeStr',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Lokasi',
            event.location.name,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _buildInfoRow(
            Icons.sell_outlined,
            'Harga Tiket',
            isFree ? 'Gratis' : 'Rp ${event.price!.toStringAsFixed(0)}',
          ),
          if (event.maxAttendees != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            _buildInfoRow(
              Icons.people_outline,
              'Kapasitas',
              '${event.maxAttendees} peserta',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared States ────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Gagal memuat event', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _eventsBloc.add(LoadEventById(widget.eventId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}
