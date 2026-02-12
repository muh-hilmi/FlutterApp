import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import '../models/ticket_transaction_model.dart';

/// Local data source for tickets using SharedPreferences
///
/// For production, replace with Firebase/REST API
class TicketLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _ticketsKey = 'TICKETS';
  static const String _transactionsKey = 'TICKET_TRANSACTIONS';

  TicketLocalDataSource({required this.sharedPreferences});

  /// Save a ticket
  Future<void> saveTicket(TicketModel ticket) async {
    final tickets = await getAllTickets();
    tickets.removeWhere((t) => t.id == ticket.id);
    tickets.add(ticket);

    final ticketsJson = tickets.map((t) => t.toJson()).toList();
    await sharedPreferences.setString(_ticketsKey, json.encode(ticketsJson));
  }

  /// Get all tickets
  Future<List<TicketModel>> getAllTickets() async {
    final ticketsString = sharedPreferences.getString(_ticketsKey);
    if (ticketsString == null) return [];

    final List<dynamic> ticketsJson = json.decode(ticketsString);
    return ticketsJson.map((json) => TicketModel.fromJson(json)).toList();
  }

  /// Get tickets for a user
  Future<List<TicketModel>> getUserTickets(String userId) async {
    final tickets = await getAllTickets();
    return tickets.where((t) => t.userId == userId).toList();
  }

  /// Get tickets for an event
  Future<List<TicketModel>> getEventTickets(String eventId) async {
    final tickets = await getAllTickets();
    return tickets.where((t) => t.eventId == eventId).toList();
  }

  /// Get ticket by ID
  Future<TicketModel?> getTicketById(String ticketId) async {
    final tickets = await getAllTickets();
    try {
      return tickets.firstWhere((t) => t.id == ticketId);
    } catch (e) {
      return null;
    }
  }

  /// Get ticket by attendance code
  Future<TicketModel?> getTicketByCode(String attendanceCode) async {
    final tickets = await getAllTickets();
    try {
      return tickets.firstWhere((t) => t.attendanceCode == attendanceCode);
    } catch (e) {
      return null;
    }
  }

  /// Update a ticket
  Future<void> updateTicket(TicketModel ticket) async {
    await saveTicket(ticket);
  }

  /// Delete a ticket
  Future<void> deleteTicket(String ticketId) async {
    final tickets = await getAllTickets();
    tickets.removeWhere((t) => t.id == ticketId);

    final ticketsJson = tickets.map((t) => t.toJson()).toList();
    await sharedPreferences.setString(_ticketsKey, json.encode(ticketsJson));
  }

  /// Save a transaction
  Future<void> saveTransaction(TicketTransactionModel transaction) async {
    final transactions = await getAllTransactions();
    transactions.removeWhere((t) => t.id == transaction.id);
    transactions.add(transaction);

    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await sharedPreferences.setString(
      _transactionsKey,
      json.encode(transactionsJson),
    );
  }

  /// Get all transactions
  Future<List<TicketTransactionModel>> getAllTransactions() async {
    final transactionsString = sharedPreferences.getString(_transactionsKey);
    if (transactionsString == null) return [];

    final List<dynamic> transactionsJson = json.decode(transactionsString);
    return transactionsJson
        .map((json) => TicketTransactionModel.fromJson(json))
        .toList();
  }

  /// Get transactions for a user
  Future<List<TicketTransactionModel>> getUserTransactions(
    String userId,
  ) async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => t.userId == userId).toList();
  }

  /// Get transaction by ID
  Future<TicketTransactionModel?> getTransactionById(
    String transactionId,
  ) async {
    final transactions = await getAllTransactions();
    try {
      return transactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all tickets (for testing)
  Future<void> clearAllTickets() async {
    await sharedPreferences.remove(_ticketsKey);
  }

  /// Clear all transactions (for testing)
  Future<void> clearAllTransactions() async {
    await sharedPreferences.remove(_transactionsKey);
  }
}
