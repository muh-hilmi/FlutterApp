import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/ticket_model.dart';
import '../models/ticket_transaction_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getEventTickets(String eventId);
  Future<TicketModel> getTicketById(String id);
  Future<TicketTransactionModel> purchaseTicket(
    String ticketId,
    Map<String, dynamic> paymentData,
  );
  /// Purchase ticket via backend API (for both free and paid events)
  Future<Map<String, dynamic>> purchaseTicketViaAPI({
    required String eventId,
    String? paymentMethod,
  });
  Future<List<TicketModel>> getMyTickets();
  Future<TicketTransactionModel> getTicketTransactionById(String transactionId);
  Future<TicketModel> checkInTicket(String eventId, String attendanceCode);
  Future<TicketModel> createTicket(Map<String, dynamic> ticketData);
  Future<TicketModel> updateTicket(String id, Map<String, dynamic> ticketData);
  Future<void> deleteTicket(String id);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final DioClient dioClient;

  TicketRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<TicketModel>> getEventTickets(String eventId) async {
    try {
      final response = await dioClient.get('/events/$eventId/tickets');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => TicketModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch event tickets');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<TicketModel> getTicketById(String id) async {
    try {
      final response = await dioClient.get('/tickets/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return TicketModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch ticket');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<TicketTransactionModel> purchaseTicket(
    String ticketId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await dioClient.post(
        '/tickets/purchase',
        data: {
          'ticketId': ticketId,
          ...paymentData,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return TicketTransactionModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to purchase ticket');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> purchaseTicketViaAPI({
    required String eventId,
    String? paymentMethod,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'event_id': eventId,
      };

      // Only include payment_method if not null (null for free events)
      if (paymentMethod != null) {
        requestData['payment_method'] = paymentMethod;
      }

      final response = await dioClient.post(
        '/tickets/purchase',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return data as Map<String, dynamic>;
      } else {
        throw ServerFailure('Failed to purchase ticket: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    try {
      final response = await dioClient.get('/tickets/my-tickets');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => TicketModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Failed to fetch user tickets');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<TicketTransactionModel> getTicketTransactionById(String transactionId) async {
    try {
      final response = await dioClient.get('/tickets/transactions/$transactionId');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return TicketTransactionModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch ticket transaction');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<TicketModel> checkInTicket(String eventId, String attendanceCode) async {
    try {
      final response = await dioClient.post(
        '/tickets/check-in',
        data: {
          'attendance_code': attendanceCode,
          'event_id': eventId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return TicketModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Failed to check in ticket');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<TicketModel> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final response = await dioClient.post(
        '/tickets',
        data: ticketData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return TicketModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to create ticket');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<TicketModel> updateTicket(String id, Map<String, dynamic> ticketData) async {
    try {
      final response = await dioClient.put(
        '/tickets/$id',
        data: ticketData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return TicketModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update ticket');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    try {
      final response = await dioClient.post('/tickets/$id/cancel');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to cancel ticket');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Failure _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Server error';
        if (statusCode == 401) {
          return AuthenticationFailure(message);
        } else if (statusCode == 403) {
          return AuthorizationFailure(message);
        } else if (statusCode == 404) {
          return NotFoundFailure(message);
        } else if (statusCode == 409) {
          // 409 CONFLICT - User already purchased/joined
          // Use message from backend, but provide a friendly default
          return ServerFailure(message);
        } else {
          return ServerFailure(message);
        }
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection');
      default:
        return ServerFailure('Unexpected error occurred');
    }
  }
}
