// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/services/analytics_service.dart';
import '../../../injection_container.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final AnalyticsService _analyticsService = sl<AnalyticsService>();
  HostRevenueSummaryModel? _summary;
  bool _loading = true;
  String _selectedPeriod = 'all';
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
      final summary = await _analyticsService.getHostRevenueSummary(
        period: _selectedPeriod,
      );
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Host 🎯'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua Waktu')),
                DropdownMenuItem(
                    value: 'this_month', child: Text('Bulan Ini')),
                DropdownMenuItem(
                    value: 'last_month', child: Text('Bulan Lalu')),
                DropdownMenuItem(value: 'this_year', child: Text('Tahun Ini')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _summary == null
                  ? const Center(child: Text('Waduh... belum ada data nih 😅'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(),
                            const SizedBox(height: 24),
                            _buildRevenueChart(),
                            const SizedBox(height: 24),
                            _buildTopEvent(),
                            const SizedBox(height: 24),
                            _buildCategoryBreakdown(),
                            const SizedBox(height: 24),
                            _buildMyEventsButton(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummaryCards() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Revenue',
          formatter.format(_summary!.totalRevenue),
          Icons.monetization_on,
          AppColors.success,
        ),
        _buildStatCard(
          'Net Revenue',
          formatter.format(_summary!.netRevenue),
          Icons.account_balance_wallet,
          AppColors.info,
        ),
        _buildStatCard(
          'Total Event',
          '${_summary!.totalEvents}',
          Icons.event,
          AppColors.warning,
        ),
        _buildStatCard(
          'Tiket Terjual',
          '${_summary!.totalTicketsSold}',
          Icons.confirmation_number,
          AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_summary!.revenueByMonth.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Bulanan 📈',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toInt()}K',
                            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < _summary!.revenueByMonth.length) {
                            final month = _summary!.revenueByMonth[index].month;
                            return Text(
                              DateFormat('MMM').format(DateTime(2024, month)),
                              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _summary!.revenueByMonth.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value.revenue,
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.info.withValues(alpha: 0.1),
                      ),
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

  Widget _buildTopEvent() {
    if (_summary!.topEvent == null) {
      return const SizedBox();
    }

    final event = _summary!.topEvent!;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Terlaris 🔥',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                event.title,
                style: AppTextStyles.bodyMediumBold,
              ),
              subtitle: Text(
                '${event.ticketsSold} tiket terjual • ${formatter.format(event.netRevenue)}',
              ),
              trailing: Chip(
                label: Text('${event.fillRate.toStringAsFixed(1)}% terisi'),
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/event-analytics',
                  arguments: event.eventId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_summary!.revenueByCategory.isEmpty) {
      return const SizedBox();
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Per Kategori 💰',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._summary!.revenueByCategory.map((category) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.primaries[
                      category.category.hashCode % Colors.primaries.length],
                  child: Text(
                    category.eventsCount.toString(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
                title: Text(
                  category.category.toUpperCase(),
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${category.ticketsSold} tiket'),
                trailing: Text(
                  formatter.format(category.revenue),
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMyEventsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/host-events-list');
        },
        icon: const Icon(Icons.list),
        label: const Text('Lihat Semua Event Gue'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
