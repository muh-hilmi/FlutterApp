import '../../domain/entities/analytics.dart';

class EventAnalyticsModel extends EventAnalytics {
  const EventAnalyticsModel({
    required super.eventId,
    required super.eventTitle,
    required super.eventStatus,
    required super.startTime,
    required super.endTime,
    super.price,
    required super.isFree,
    required super.maxAttendees,
    required super.ticketsSold,
    required super.ticketsCheckedIn,
    required super.attendanceRate,
    required super.checkInRate,
    required super.revenue,
    required super.transactions,
    required super.paymentMethods,
    required super.timelineStats,
  });

  factory EventAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return EventAnalyticsModel(
      eventId: json['event_id'] ?? '',
      eventTitle: json['event_title'] ?? '',
      eventStatus: json['event_status'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      price: json['price']?.toDouble(),
      isFree: json['is_free'] ?? true,
      maxAttendees: json['max_attendees'] ?? 0,
      ticketsSold: json['tickets_sold'] ?? 0,
      ticketsCheckedIn: json['tickets_checked_in'] ?? 0,
      attendanceRate: (json['attendance_rate'] ?? 0).toDouble(),
      checkInRate: (json['check_in_rate'] ?? 0).toDouble(),
      revenue: RevenueStatsModel.fromJson(json['revenue'] ?? {}),
      transactions: TransactionStatsModel.fromJson(json['transactions'] ?? {}),
      paymentMethods: (json['payment_methods'] as List<dynamic>?)
              ?.map((e) => PaymentMethodStatsModel.fromJson(e))
              .toList() ??
          [],
      timelineStats: (json['timeline_stats'] as List<dynamic>?)
              ?.map((e) => TimelineStatsModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RevenueStatsModel extends RevenueStats {
  const RevenueStatsModel({
    required super.totalRevenue,
    required super.pendingRevenue,
    required super.refundedRevenue,
    required super.expectedRevenue,
    required super.netRevenue,
  });

  factory RevenueStatsModel.fromJson(Map<String, dynamic> json) {
    return RevenueStatsModel(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      pendingRevenue: (json['pending_revenue'] ?? 0).toDouble(),
      refundedRevenue: (json['refunded_revenue'] ?? 0).toDouble(),
      expectedRevenue: (json['expected_revenue'] ?? 0).toDouble(),
      netRevenue: (json['net_revenue'] ?? 0).toDouble(),
    );
  }
}

class TransactionStatsModel extends TransactionStats {
  const TransactionStatsModel({
    required super.totalTransactions,
    required super.successfulTransactions,
    required super.pendingTransactions,
    required super.failedTransactions,
    required super.refundedTransactions,
  });

  factory TransactionStatsModel.fromJson(Map<String, dynamic> json) {
    return TransactionStatsModel(
      totalTransactions: json['total_transactions'] ?? 0,
      successfulTransactions: json['successful_transactions'] ?? 0,
      pendingTransactions: json['pending_transactions'] ?? 0,
      failedTransactions: json['failed_transactions'] ?? 0,
      refundedTransactions: json['refunded_transactions'] ?? 0,
    );
  }
}

class PaymentMethodStatsModel extends PaymentMethodStats {
  const PaymentMethodStatsModel({
    required super.method,
    required super.count,
    required super.totalAmount,
    required super.percentage,
  });

  factory PaymentMethodStatsModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStatsModel(
      method: json['method'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class TimelineStatsModel extends TimelineStats {
  const TimelineStatsModel({
    required super.date,
    required super.ticketsSold,
    required super.revenue,
    required super.transactions,
  });

  factory TimelineStatsModel.fromJson(Map<String, dynamic> json) {
    return TimelineStatsModel(
      date: DateTime.parse(json['date']),
      ticketsSold: json['tickets_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? 0,
    );
  }
}

class TransactionDetailModel extends TransactionDetail {
  const TransactionDetailModel({
    required super.transactionId,
    required super.ticketId,
    required super.buyerName,
    required super.buyerEmail,
    required super.amount,
    required super.paymentMethod,
    required super.status,
    required super.purchasedAt,
    super.completedAt,
    required super.isCheckedIn,
    super.checkedInAt,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionDetailModel(
      transactionId: json['transaction_id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      buyerName: json['buyer_name'] ?? '',
      buyerEmail: json['buyer_email'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      purchasedAt: DateTime.parse(json['purchased_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      isCheckedIn: json['is_checked_in'] ?? false,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'])
          : null,
    );
  }
}

class HostRevenueSummaryModel extends HostRevenueSummary {
  const HostRevenueSummaryModel({
    required super.hostId,
    required super.totalEvents,
    required super.completedEvents,
    required super.upcomingEvents,
    required super.totalTicketsSold,
    required super.totalRevenue,
    required super.totalRefunded,
    required super.netRevenue,
    required super.averageTicketPrice,
    super.topEvent,
    required super.revenueByMonth,
    required super.revenueByCategory,
  });

  factory HostRevenueSummaryModel.fromJson(Map<String, dynamic> json) {
    return HostRevenueSummaryModel(
      hostId: json['host_id'] ?? '',
      totalEvents: json['total_events'] ?? 0,
      completedEvents: json['completed_events'] ?? 0,
      upcomingEvents: json['upcoming_events'] ?? 0,
      totalTicketsSold: json['total_tickets_sold'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalRefunded: (json['total_refunded'] ?? 0).toDouble(),
      netRevenue: (json['net_revenue'] ?? 0).toDouble(),
      averageTicketPrice: (json['average_ticket_price'] ?? 0).toDouble(),
      topEvent: json['top_event'] != null
          ? EventRevenueSummaryModel.fromJson(json['top_event'])
          : null,
      revenueByMonth: (json['revenue_by_month'] as List<dynamic>?)
              ?.map((e) => MonthlyRevenueModel.fromJson(e))
              .toList() ??
          [],
      revenueByCategory: (json['revenue_by_category'] as List<dynamic>?)
              ?.map((e) => CategoryRevenueModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EventRevenueSummaryModel extends EventRevenueSummary {
  const EventRevenueSummaryModel({
    required super.eventId,
    required super.title,
    required super.category,
    required super.status,
    required super.startTime,
    super.price,
    required super.isFree,
    required super.maxAttendees,
    required super.ticketsSold,
    required super.revenue,
    required super.refundedAmount,
    required super.netRevenue,
    required super.fillRate,
  });

  factory EventRevenueSummaryModel.fromJson(Map<String, dynamic> json) {
    return EventRevenueSummaryModel(
      eventId: json['event_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      price: json['price']?.toDouble(),
      isFree: json['is_free'] ?? true,
      maxAttendees: json['max_attendees'] ?? 0,
      ticketsSold: json['tickets_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      refundedAmount: (json['refunded_amount'] ?? 0).toDouble(),
      netRevenue: (json['net_revenue'] ?? 0).toDouble(),
      fillRate: (json['fill_rate'] ?? 0).toDouble(),
    );
  }
}

class MonthlyRevenueModel extends MonthlyRevenue {
  const MonthlyRevenueModel({
    required super.year,
    required super.month,
    required super.eventsCount,
    required super.ticketsSold,
    required super.revenue,
  });

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueModel(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      eventsCount: json['events_count'] ?? 0,
      ticketsSold: json['tickets_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class CategoryRevenueModel extends CategoryRevenue {
  const CategoryRevenueModel({
    required super.category,
    required super.eventsCount,
    required super.ticketsSold,
    required super.revenue,
  });

  factory CategoryRevenueModel.fromJson(Map<String, dynamic> json) {
    return CategoryRevenueModel(
      category: json['category'] ?? '',
      eventsCount: json['events_count'] ?? 0,
      ticketsSold: json['tickets_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}
