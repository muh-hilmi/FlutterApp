import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/event.dart';

/// Screen displaying comprehensive analytics summary for completed events
/// Features:
/// - Event header with completion status
/// - Statistik Inti: tickets sold vs capacity, check-in rate, total revenue
/// - Additional insights
/// - Documentation section
/// - Feedback/review section
/// - Related posts section
class EventSummaryScreen extends StatefulWidget {
  final Event event;

  const EventSummaryScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventSummaryScreen> createState() => _EventSummaryScreenState();
}

class _EventSummaryScreenState extends State<EventSummaryScreen> {
  // TODO: Load actual check-in data from backend
  // For now, assume all attendees checked in
  int get checkedInCount => widget.event.attendeeIds.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventHeader(context),
            const SizedBox(height: 24),
            _buildCoreStatisticsSection(context),
            const SizedBox(height: 24),
            _buildAdditionalInsightsSection(context),
            const SizedBox(height: 24),
            _buildDocumentationSection(context),
            const SizedBox(height: 24),
            _buildFeedbackSection(context),
            const SizedBox(height: 24),
            _buildRelatedPostsSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      key: const Key('event_summary_app_bar'),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        key: const Key('event_summary_back_button'),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF1A1A1A),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Ringkasan Event',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A1A),
        ),
      ),
      actions: [
        IconButton(
          key: const Key('event_summary_share_button'),
          icon: const Icon(
            Icons.share_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () {
            // TODO: Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur share akan segera hadir!'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    final event = widget.event;

    return Container(
      key: Key('event_summary_header_${event.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFBBC863).withValues(alpha: 0.8),
            const Color(0xFFBBC863).withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SELESAI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            event.title,
            key: Key('event_summary_title_${event.id}'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Date & Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                _formatEventDate(event.startTime, event.endTime),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.location.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreStatisticsSection(BuildContext context) {
    final event = widget.event;
    final ticketsSold = event.ticketsSold;
    final capacity = event.maxAttendees;
    final occupancyRate = capacity > 0 ? (ticketsSold / capacity * 100).round() : 0;

    final checkinRate = ticketsSold > 0
        ? (checkedInCount / ticketsSold * 100).round()
        : 0;

    final totalRevenue = event.isFree
        ? 0.0
        : (event.price ?? 0.0) * ticketsSold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Inti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Tickets Sold vs Capacity
          _buildStatCard(
            context,
            key: Key('event_summary_tickets_card_${event.id}'),
            icon: Icons.confirmation_number_rounded,
            iconColor: const Color(0xFFBBC863),
            title: 'Tiket Terjual vs Kapasitas',
            value: '$ticketsSold/$capacity',
            subtitle: '$occupancyRate% terisi',
            progress: capacity > 0 ? ticketsSold / capacity : 0,
            progressColor: occupancyRate >= 80
                ? Colors.green
                : occupancyRate >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
          const SizedBox(height: 12),

          // Check-in Rate
          _buildStatCard(
            context,
            key: Key('event_summary_checkin_card_${event.id}'),
            icon: Icons.how_to_reg_rounded,
            iconColor: Colors.blue,
            title: 'Check-in Rate',
            value: '$checkinRate%',
            subtitle: '$checkedInCount dari $ticketsSold tiket',
            progress: ticketsSold > 0 ? checkedInCount / ticketsSold : 0,
            progressColor: checkinRate >= 80
                ? Colors.green
                : checkinRate >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
          const SizedBox(height: 12),

          // Total Revenue
          _buildRevenueCard(
            context,
            key: Key('event_summary_revenue_card_${event.id}'),
            isFree: event.isFree,
            revenue: totalRevenue,
            pricePerTicket: event.price,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context, {
    required Key key,
    required bool isFree,
    required double revenue,
    double? pricePerTicket,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFree
            ? Colors.grey[100]
            : const Color(0xFFBBC863).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? Colors.grey[200]!
              : const Color(0xFFBBC863).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFree
                      ? Colors.grey[300]
                      : const Color(0xFFBBC863).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFree ? Icons.money_off_rounded : Icons.payments_rounded,
                  size: 20,
                  color: isFree ? Colors.grey[600] : const Color(0xFFBBC863),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (!isFree && pricePerTicket != null)
                      Text(
                        'Harga tiket: ${formatter.format(pricePerTicket)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                isFree ? 'GRATIS' : formatter.format(revenue),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isFree ? Colors.grey[700] : const Color(0xFFBBC863),
                ),
              ),
            ],
          ),
          if (!isFree) ...[
            const SizedBox(height: 12),
            Text(
              'Pendapatan kotor dari penjualan tiket. Belum dipotong biaya platform.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInsightsSection(BuildContext context) {
    final event = widget.event;
    final interestedCount = event.interestedCount;
    final waitlistCount = event.waitlistCount;
    final spotsLeft = event.spotsLeft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight Tambahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Interest metric
          _buildInsightTile(
            context,
            key: Key('event_summary_interest_tile_${event.id}'),
            icon: Icons.favorite_border_rounded,
            iconColor: Colors.red,
            title: 'Minat',
            value: '$interestedCount orang',
            description: 'User yang tertarik dengan event ini',
          ),

          if (waitlistCount > 0) ...[
            const SizedBox(height: 8),
            _buildInsightTile(
              context,
              key: Key('event_summary_waitlist_tile_${event.id}'),
              icon: Icons.list_alt_rounded,
              iconColor: Colors.orange,
              title: 'Waitlist',
              value: '$waitlistCount orang',
              description: 'User yang masuk waitlist saat penuh',
            ),
          ],

          const SizedBox(height: 8),
          _buildInsightTile(
            context,
            key: Key('event_summary_capacity_tile_${event.id}'),
            icon: Icons.event_seat_rounded,
            iconColor: Colors.purple,
            title: 'Kapasitas Tersisa',
            value: spotsLeft > 0 ? '$spotsLeft kursi' : 'Penuh',
            description: spotsLeft > 0
                ? 'Ada ruang untuk lebih banyak peserta'
                : 'Event terisi penuh',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String description,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dokumentasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              TextButton.icon(
                key: const Key('event_summary_add_doc_button'),
                onPressed: () {
                  // TODO: Implement photo/video upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur upload dokumentasi akan segera hadir!'),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Tambah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBBC863),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state for documentation
          Container(
            key: Key('event_summary_doc_empty_${widget.event.id}'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum Ada Dokumentasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload foto & video momen seru event ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Example: If there were photos, show them in a grid
          // GridView.count(
          //   crossAxisCount: 3,
          //   shrinkWrap: true,
          //   physics: const NeverScrollableScrollPhysics(),
          //   mainAxisSpacing: 8,
          //   crossAxisSpacing: 8,
          //   children: [
          //     ...documentationPhotos.map((photo) => ClipRRect(
          //       borderRadius: BorderRadius.circular(8),
          //       child: Image.network(photo.url, fit: BoxFit.cover),
          //     )),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback & Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),

          // Empty state for feedback
          Container(
            key: Key('event_summary_feedback_empty_${widget.event.id}'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum Ada Review',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review dari peserta akan muncul di sini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Example: If there were reviews, show them
          // ...reviews.map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildRelatedPostsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Postingan Terkait',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),

          // Empty state for related posts
          Container(
            key: Key('event_summary_posts_empty_${widget.event.id}'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum Ada Postingan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Postingan terkait event ini akan muncul di sini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Example: If there were posts, show them
          // ...relatedPosts.map((post) => _buildPostCard(post)),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime start, DateTime end) {
    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final startDay = localStart.day;
    final startMonth = months[localStart.month - 1];
    final startYear = localStart.year;

    // Check if same day
    if (localStart.day == localEnd.day && localStart.month == localEnd.month && localStart.year == localEnd.year) {
      final startHour = localStart.hour.toString().padLeft(2, '0');
      final startMinute = localStart.minute.toString().padLeft(2, '0');
      final endHour = localEnd.hour.toString().padLeft(2, '0');
      final endMinute = localEnd.minute.toString().padLeft(2, '0');

      return '$startDay $startMonth $startYear, $startHour:$startMinute - $endHour:$endMinute';
    }

    // Different days
    final endDay = localEnd.day;
    final endMonth = months[localEnd.month - 1];

    return '$startDay $startMonth - $endDay $endMonth $startYear';
  }
}
