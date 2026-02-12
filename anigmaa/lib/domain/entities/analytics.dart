import 'package:equatable/equatable.dart';

class EventAnalytics extends Equatable {
  final String eventId;
  final String eventTitle;
  final String eventStatus;
  final DateTime startTime;
  final DateTime endTime;
  final double? price;
  final bool isFree;
  final int maxAttendees;
  final int ticketsSold;
  final int ticketsCheckedIn;
  final double attendanceRate;
  final double checkInRate;
  final RevenueStats revenue;
  final TransactionStats transactions;
  final List<PaymentMethodStats> paymentMethods;
  final List<TimelineStats> timelineStats;

  const EventAnalytics({
    required this.eventId,
    required this.eventTitle,
    required this.eventStatus,
    required this.startTime,
    required this.endTime,
    this.price,
    required this.isFree,
    required this.maxAttendees,
    required this.ticketsSold,
    required this.ticketsCheckedIn,
    required this.attendanceRate,
    required this.checkInRate,
    required this.revenue,
    required this.transactions,
    required this.paymentMethods,
    required this.timelineStats,
  });

  @override
  List<Object?> get props => [
        eventId,
        eventTitle,
        eventStatus,
        startTime,
        endTime,
        price,
        isFree,
        maxAttendees,
        ticketsSold,
        ticketsCheckedIn,
        attendanceRate,
        checkInRate,
        revenue,
        transactions,
        paymentMethods,
        timelineStats,
      ];
}

class RevenueStats extends Equatable {
  final double totalRevenue;
  final double pendingRevenue;
  final double refundedRevenue;
  final double expectedRevenue;
  final double netRevenue;

  const RevenueStats({
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.refundedRevenue,
    required this.expectedRevenue,
    required this.netRevenue,
  });

  @override
  List<Object> get props => [
        totalRevenue,
        pendingRevenue,
        refundedRevenue,
        expectedRevenue,
        netRevenue,
      ];
}

class TransactionStats extends Equatable {
  final int totalTransactions;
  final int successfulTransactions;
  final int pendingTransactions;
  final int failedTransactions;
  final int refundedTransactions;

  const TransactionStats({
    required this.totalTransactions,
    required this.successfulTransactions,
    required this.pendingTransactions,
    required this.failedTransactions,
    required this.refundedTransactions,
  });

  @override
  List<Object> get props => [
        totalTransactions,
        successfulTransactions,
        pendingTransactions,
        failedTransactions,
        refundedTransactions,
      ];
}

class PaymentMethodStats extends Equatable {
  final String method;
  final int count;
  final double totalAmount;
  final double percentage;

  const PaymentMethodStats({
    required this.method,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });

  @override
  List<Object> get props => [method, count, totalAmount, percentage];
}

class TimelineStats extends Equatable {
  final DateTime date;
  final int ticketsSold;
  final double revenue;
  final int transactions;

  const TimelineStats({
    required this.date,
    required this.ticketsSold,
    required this.revenue,
    required this.transactions,
  });

  @override
  List<Object> get props => [date, ticketsSold, revenue, transactions];
}

class TransactionDetail extends Equatable {
  final String transactionId;
  final String ticketId;
  final String buyerName;
  final String buyerEmail;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime purchasedAt;
  final DateTime? completedAt;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  const TransactionDetail({
    required this.transactionId,
    required this.ticketId,
    required this.buyerName,
    required this.buyerEmail,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.purchasedAt,
    this.completedAt,
    required this.isCheckedIn,
    this.checkedInAt,
  });

  @override
  List<Object?> get props => [
        transactionId,
        ticketId,
        buyerName,
        buyerEmail,
        amount,
        paymentMethod,
        status,
        purchasedAt,
        completedAt,
        isCheckedIn,
        checkedInAt,
      ];
}

class HostRevenueSummary extends Equatable {
  final String hostId;
  final int totalEvents;
  final int completedEvents;
  final int upcomingEvents;
  final int totalTicketsSold;
  final double totalRevenue;
  final double totalRefunded;
  final double netRevenue;
  final double averageTicketPrice;
  final EventRevenueSummary? topEvent;
  final List<MonthlyRevenue> revenueByMonth;
  final List<CategoryRevenue> revenueByCategory;

  const HostRevenueSummary({
    required this.hostId,
    required this.totalEvents,
    required this.completedEvents,
    required this.upcomingEvents,
    required this.totalTicketsSold,
    required this.totalRevenue,
    required this.totalRefunded,
    required this.netRevenue,
    required this.averageTicketPrice,
    this.topEvent,
    required this.revenueByMonth,
    required this.revenueByCategory,
  });

  @override
  List<Object?> get props => [
        hostId,
        totalEvents,
        completedEvents,
        upcomingEvents,
        totalTicketsSold,
        totalRevenue,
        totalRefunded,
        netRevenue,
        averageTicketPrice,
        topEvent,
        revenueByMonth,
        revenueByCategory,
      ];
}

class EventRevenueSummary extends Equatable {
  final String eventId;
  final String title;
  final String category;
  final String status;
  final DateTime startTime;
  final double? price;
  final bool isFree;
  final int maxAttendees;
  final int ticketsSold;
  final double revenue;
  final double refundedAmount;
  final double netRevenue;
  final double fillRate;

  const EventRevenueSummary({
    required this.eventId,
    required this.title,
    required this.category,
    required this.status,
    required this.startTime,
    this.price,
    required this.isFree,
    required this.maxAttendees,
    required this.ticketsSold,
    required this.revenue,
    required this.refundedAmount,
    required this.netRevenue,
    required this.fillRate,
  });

  @override
  List<Object?> get props => [
        eventId,
        title,
        category,
        status,
        startTime,
        price,
        isFree,
        maxAttendees,
        ticketsSold,
        revenue,
        refundedAmount,
        netRevenue,
        fillRate,
      ];
}

class MonthlyRevenue extends Equatable {
  final int year;
  final int month;
  final int eventsCount;
  final int ticketsSold;
  final double revenue;

  const MonthlyRevenue({
    required this.year,
    required this.month,
    required this.eventsCount,
    required this.ticketsSold,
    required this.revenue,
  });

  @override
  List<Object> get props => [year, month, eventsCount, ticketsSold, revenue];
}

class CategoryRevenue extends Equatable {
  final String category;
  final int eventsCount;
  final int ticketsSold;
  final double revenue;

  const CategoryRevenue({
    required this.category,
    required this.eventsCount,
    required this.ticketsSold,
    required this.revenue,
  });

  @override
  List<Object> get props => [category, eventsCount, ticketsSold, revenue];
}
