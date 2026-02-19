// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'transaction_widgets.dart' as widgets;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  final String _selectedEventFilter = 'all';
  late TabController _tabController;

  // REMOVED MOCK DATA - Ready for API integration
  // Once backend implements transaction endpoints, integrate with TransactionsBloc
  final List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: Replace with actual Bloc call when backend is ready
    // context.read<TransactionsBloc>().add(LoadUserTransactions());
    // context.read<TransactionsBloc>().add(LoadHostedEventTransactions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Transaction> get _filteredTransactions {
    var transactions = _transactions;

    // Filter by event
    if (_selectedEventFilter != 'all') {
      transactions = transactions.where((tx) => tx.eventId == _selectedEventFilter).toList();
    }

    // Filter by status
    switch (_selectedFilter) {
      case 'success':
        return transactions.where((tx) => tx.status == TransactionStatus.success).toList();
      case 'pending':
        return transactions.where((tx) =>
          tx.status == TransactionStatus.pending ||
          tx.status == TransactionStatus.processing
        ).toList();
      case 'failed':
        return transactions.where((tx) =>
          tx.status == TransactionStatus.failed ||
          tx.status == TransactionStatus.expired
        ).toList();
      case 'refunded':
        return transactions.where((tx) => tx.status == TransactionStatus.refunded).toList();
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Purchases'),
            Tab(text: 'Revenue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchasesTab(),
          _buildRevenueTab(),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _transactions.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long,
                  title: 'No transactions yet',
                  subtitle: 'Your event tickets will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _filteredTransactions[index];
                    return widgets.TransactionCard(
                      transaction: transaction,
                      onTap: () {
                        // TODO: Navigate to transaction details
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRevenueTab() {
    // TODO: Replace with actual data from Bloc
    final totalRevenue = 0;
    final platformFee = 0;
    final netRevenue = totalRevenue - platformFee;
    final totalTransactions = 0;
    final successfulTransactions = 0;
    const averageTicketPrice = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widgets.RevenueCard(
            totalRevenue: totalRevenue,
            platformFee: platformFee,
            netRevenue: netRevenue,
          ),
          const SizedBox(height: 24),
          Text(
            'Statistics',
            style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: widgets.StatCard(
                  label: 'Total Transactions',
                  value: totalTransactions.toString(),
                  icon: Icons.receipt,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: widgets.StatCard(
                  label: 'Successful',
                  value: successfulTransactions.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: widgets.StatCard(
                  label: 'Avg. Ticket Price',
                  value: NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(averageTicketPrice),
                  icon: Icons.trending_up,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: widgets.StatCard(
                  label: 'Events Hosted',
                  value: '0',
                  icon: Icons.event,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          widgets.FilterChip(
            label: 'All',
            value: 'all',
            selectedValue: _selectedFilter,
            onTap: (value) => setState(() => _selectedFilter = value),
          ),
          const SizedBox(width: 8),
          widgets.FilterChip(
            label: 'Success',
            value: 'success',
            selectedValue: _selectedFilter,
            onTap: (value) => setState(() => _selectedFilter = value),
          ),
          const SizedBox(width: 8),
          widgets.FilterChip(
            label: 'Pending',
            value: 'pending',
            selectedValue: _selectedFilter,
            onTap: (value) => setState(() => _selectedFilter = value),
          ),
          const SizedBox(width: 8),
          widgets.FilterChip(
            label: 'Failed',
            value: 'failed',
            selectedValue: _selectedFilter,
            onTap: (value) => setState(() => _selectedFilter = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(
              icon,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
