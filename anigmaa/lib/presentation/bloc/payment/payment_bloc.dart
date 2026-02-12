import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/payment_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;

  PaymentBloc({required PaymentRepository paymentRepository})
    : _paymentRepository = paymentRepository,
      super(const PaymentState.initial()) {
    on<InitiatePayment>(_onInitiatePayment);
    on<ProcessPayment>(_onProcessPayment);
    on<PaymentSuccess>(_onPaymentSuccess);
    on<PaymentFailed>(_onPaymentFailed);
    on<ResetPaymentState>(_onResetPaymentState);
  }

  Future<void> _onInitiatePayment(
    InitiatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.loading, errorMessage: null));

    try {
      final paymentResult = await _paymentRepository.initiatePayment(
        eventId: event.event.id,
        amount: event.totalAmount,
        paymentMethod: event.paymentMethod.name,
      );

      print('PaymentBloc: Received paymentResult: $paymentResult');

      final newState = state.copyWith(
        status: PaymentStatus.initiated,
        paymentUrl: paymentResult['payment_url'],
        transactionId: paymentResult['transaction_id'],
        event: event.event,
      );

      print('PaymentBloc: New state - status: ${newState.status}, paymentUrl: ${newState.paymentUrl}, transactionId: ${newState.transactionId}');

      emit(newState);
    } catch (error) {
      print('PaymentBloc: Error - $error');
      emit(
        state.copyWith(
          status: PaymentStatus.error,
          errorMessage: _getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(status: PaymentStatus.processing, errorMessage: null));

    try {
      final result = await _paymentRepository.processPayment(
        transactionId: event.transactionId,
        paymentToken: event.paymentToken,
      );

      if (result['success'] == true) {
        emit(
          state.copyWith(
            status: PaymentStatus.success,
            transactionId: result['transaction_id'],
            paymentUrl: result['receipt_url'],
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PaymentStatus.error,
            errorMessage: result['message'] ?? 'Pembayaran gagal',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: PaymentStatus.error,
          errorMessage: _getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onPaymentSuccess(
    PaymentSuccess event,
    Emitter<PaymentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PaymentStatus.success,
        transactionId: event.transactionId,
        paymentUrl: event.receiptUrl,
      ),
    );
  }

  Future<void> _onPaymentFailed(
    PaymentFailed event,
    Emitter<PaymentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PaymentStatus.error,
        errorMessage: event.errorMessage,
      ),
    );
  }

  Future<void> _onResetPaymentState(
    ResetPaymentState event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentState.initial());
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('connection')) {
      return 'Koneksi internet bermasalah. Cek koneksi kamu ya! 📡';
    } else if (error.toString().toLowerCase().contains('timeout')) {
      return 'Server lagi lelet nih. Coba lagi yuk! ⏱️';
    } else if (error.toString().contains('401')) {
      return 'Sesi kamu habis. Yuk login lagi! 🔐';
    } else if (error.toString().toLowerCase().contains('payment') &&
        error.toString().toLowerCase().contains('failed')) {
      return 'Pembayaran gagal. Coba metode pembayaran lain ya! 💳';
    } else if (error.toString().toLowerCase().contains('insufficient')) {
      return 'Saldo tidak mencukupi. Isi ulang dulu ya! 💰';
    } else if (error.toString().toLowerCase().contains('invalid')) {
      return 'Detail pembayaran tidak valid. Silakan coba lagi.';
    } else {
      return 'Ada kendala saat pembayaran. Coba lagi ya! 😅 (${error.toString()})'; // Show raw error for debug
    }
  }
}
