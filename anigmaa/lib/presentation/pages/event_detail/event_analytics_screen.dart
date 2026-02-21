// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/services/analytics_service.dart';
import '../../../injection_container.dart';
import '../../../domain/entities/event.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

/// 📊 Modern Event Analytics Screen
///
/// Shows event performance metrics even with zero data
class EventAnalyticsScreen extends StatefulWidget {
  final String eventId;
  final Event? event;

  const EventAnalyticsScreen({super.key, required this.eventId, this.event});

  @override
  State<EventAnalyticsScreen> createState() => _EventAnalyticsScreenState();
}

class _EventAnalyticsScreenState extends State<EventAnalyticsScreen> {
  final AnalyticsService _analyticsService = sl<AnalyticsService>();
  EventAnalyticsModel? _analytics;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final analyticsData = await _analyticsService.getEventAnalytics(
        widget.eventId,
      );

      // analyticsData is non-nullable, null caching handled by Exception
      _analytics = analyticsData;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      // On error, create empty analytics instead of showing error
      setState(() {
        _analytics = _createEmptyAnalytics();
        _loading = false;
      });
    }
  }

  EventAnalyticsModel _createEmptyAnalytics() {
    final event = widget.event;
    return EventAnalyticsModel(
      eventId: widget.eventId,
      eventTitle: event?.title ?? 'Event',
      eventStatus: event?.status.name ?? 'upcoming',
      startTime: event?.startTime ?? DateTime.now(),
      endTime: event?.endTime ?? DateTime.now().add(const Duration(hours: 2)),
      price: event?.price ?? 0,
      isFree: event?.isFree ?? true,
      maxAttendees: event?.maxAttendees ?? 0,
      ticketsSold: 0,
      ticketsCheckedIn: 0,
      attendanceRate: 0.0,
      checkInRate: 0.0,
      revenue: const RevenueStatsModel(
        totalRevenue: 0,
        netRevenue: 0,
        pendingRevenue: 0,
        refundedRevenue: 0,
        expectedRevenue: 0,
      ),
      transactions: const TransactionStatsModel(
        totalTransactions: 0,
        successfulTransactions: 0,
        pendingTransactions: 0,
        failedTransactions: 0,
        refundedTransactions: 0,
      ),
      paymentMethods: [],
      timelineStats: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1A1A1A),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analitik Event',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _analytics == null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFBBC863),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventHeader(),
                    const SizedBox(height: 24),
                    _buildRevenueCards(),
                    const SizedBox(height: 24),
                    _buildTransactionStats(),
                    const SizedBox(height: 24),
                    _buildAttendanceStats(),
                    const SizedBox(height: 24),
                    if (_analytics!.paymentMethods.isNotEmpty)
                      _buildPaymentMethods(),
                    if (_analytics!.paymentMethods.isNotEmpty)
                      const SizedBox(height: 24),
                    if (_analytics!.timelineStats.isNotEmpty)
                      _buildSalesTimeline(),
                    const SizedBox(height: 24),
                    _buildTipsCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFBBC863),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Gagal memuat data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
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
                  Icons.event_rounded,
                  size: 20,
                  color: Color(0xFFBBC863),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _analytics!.eventTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_analytics!.eventStatus),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _analytics!.eventStatus.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getStatusTextColor(
                                _analytics!.eventStatus,
                              ),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (!_analytics!.isFree) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatter.format(_analytics!.price),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFBBC863,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'GRATIS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFBBC863),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${dateFormat.format(_analytics!.startTime)} - ${dateFormat.format(_analytics!.endTime)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFF3B82F6).withValues(alpha: 0.1);
      case 'ongoing':
        return const Color(0xFF10B981).withValues(alpha: 0.1);
      case 'completed':
        return const Color(0xFF6B7280).withValues(alpha: 0.1);
      case 'ended':
        return const Color(0xFF6B7280).withValues(alpha: 0.1);
      case 'cancelled':
        return const Color(0xFFEF4444).withValues(alpha: 0.1);
      default:
        return AppColors.textTertiary.withValues(alpha: 0.1);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFF3B82F6);
      case 'ongoing':
        return const Color(0xFF10B981);
      case 'completed':
      case 'ended':
        return const Color(0xFF6B7280);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return AppColors.textTertiary;
    }
  }

  Widget _buildRevenueCards() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💰 Pendapatan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildRevenueCard(
              'Total Pendapatan',
              formatter.format(_analytics!.revenue.totalRevenue),
              const Color(0xFF10B981),
              Icons.monetization_on_rounded,
            ),
            _buildRevenueCard(
              'Pendapatan Bersih',
              formatter.format(_analytics!.revenue.netRevenue),
              const Color(0xFF3B82F6),
              Icons.account_balance_wallet_rounded,
            ),
            _buildRevenueCard(
              'Pending',
              formatter.format(_analytics!.revenue.pendingRevenue),
              const Color(0xFFF59E0B),
              Icons.pending_actions_rounded,
            ),
            _buildRevenueCard(
              'Refund',
              formatter.format(_analytics!.revenue.refundedRevenue),
              const Color(0xFFEF4444),
              Icons.refresh_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStats() {
    return Container(
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
            '💳 Transaksi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildTransactionRow(
            'Total Transaksi',
            _analytics!.transactions.totalTransactions,
            AppColors.textTertiary,
            Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 16),
          _buildTransactionRow(
            'Sukses',
            _analytics!.transactions.successfulTransactions,
            Colors.green,
            Icons.check_circle_rounded,
          ),
          const SizedBox(height: 16),
          _buildTransactionRow(
            'Pending',
            _analytics!.transactions.pendingTransactions,
            Colors.orange,
            Icons.pending_rounded,
          ),
          const SizedBox(height: 16),
          _buildTransactionRow(
            'Gagal',
            _analytics!.transactions.failedTransactions,
            Colors.red,
            Icons.cancel_rounded,
          ),
          const SizedBox(height: 16),
          _buildTransactionRow(
            'Refund',
            _analytics!.transactions.refundedTransactions,
            Colors.purple,
            Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: count > 0
                ? color.withValues(alpha: 0.1)
                : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: count > 0 ? color : AppColors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStats() {
    return Container(
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
            '🎫 Kehadiran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceProgress(
                  'Tiket Terjual',
                  '${_analytics!.ticketsSold} / ${_analytics!.maxAttendees}',
                  _analytics!.ticketsSold,
                  _analytics!.maxAttendees,
                  const Color(0xFFBBC863),
                  _analytics!.attendanceRate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceProgress(
                  'Checked In',
                  '${_analytics!.ticketsCheckedIn} / ${_analytics!.ticketsSold}',
                  _analytics!.ticketsCheckedIn,
                  _analytics!.ticketsSold,
                  const Color(0xFF3B82F6),
                  _analytics!.checkInRate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceProgress(
    String label,
    String fraction,
    int current,
    int total,
    Color color,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          fraction,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    if (_analytics!.paymentMethods.isEmpty) {
      return const SizedBox();
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
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
            '💳 Metode Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          ..._analytics!.paymentMethods.map((method) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          Colors.primaries[method.method.hashCode %
                              Colors.primaries.length],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        method.count.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.method.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatter.format(method.totalAmount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${method.percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFBBC863),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSalesTimeline() {
    if (_analytics!.timelineStats.isEmpty) {
      return const SizedBox();
    }

    return Container(
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
            '📈 Grafik Penjualan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < _analytics!.timelineStats.length) {
                          final date = _analytics!.timelineStats[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceAlt,
                      dashArray: [5, 5],
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: _analytics!.timelineStats.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.ticketsSold.toDouble(),
                        color: const Color(0xFFBBC863),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                          bottom: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final hasSales = _analytics!.ticketsSold > 0;
    final hasRevenue = _analytics!.revenue.totalRevenue > 0;

    String tip;
    IconData icon;
    Color color;

    if (!hasSales && !hasRevenue) {
      tip =
          'Promosikan event kamu di media sosial untuk menarik lebih banyak peserta! '
          'Gunakan foto menarik dan deskripsi yang jelas.';
      icon = Icons.campaign_rounded;
      color = const Color(0xFFF59E0B);
    } else if (_analytics!.attendanceRate < 50) {
      tip =
          'Kirim pengingat kepada peserta yang sudah membeli tiket untuk '
          'mengingatkan mereka check-in pada hari H.';
      icon = Icons.notifications_active_rounded;
      color = const Color(0xFF3B82F6);
    } else if (_analytics!.checkInRate < 80) {
      tip =
          'Persiapakan sistem check-in yang efisien untuk '
          'mengurangi antrean di lokasi event.';
      icon = Icons.qr_code_scanner_rounded;
      color = const Color(0xFFBBC863);
    } else {
      tip =
          'Event kamu berjalan sangat baik! '
          'Pertimbangkan untuk membuat event rutin setiap bulan.';
      icon = Icons.emoji_events_rounded;
      color = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Untuk Kamu 💡',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textEmphasis,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
