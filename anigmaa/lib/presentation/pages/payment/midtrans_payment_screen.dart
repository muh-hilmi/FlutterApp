// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../data/models/midtrans_payment_model.dart';
import '../../../../data/services/midtrans_payment_service.dart';
import '../../bloc/midtrans_payment/midtrans_payment_bloc.dart';
import '../../../domain/entities/event.dart';
import '../tickets/post_payment_ticket_screen.dart';
import '../../widgets/tickets/celebration_bottom_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Midtrans In-App Payment Screen
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => MidtransPaymentScreen(
///       orderId: 'ORDER-123',
///       amount: 50000,
///       itemName: 'Tiket Event Musik',
///       itemId: 'TICKET-001',
///       event: event, // Optional - for post-payment flow
///     ),
///   ),
/// );
/// ```
class MidtransPaymentScreen extends StatelessWidget {
  final String orderId;
  final double amount;
  final String itemName;
  final String itemId;
  final Event? event; // Added for post-payment flow

  const MidtransPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.itemName,
    required this.itemId,
    this.event,
  });

  @override
  Widget build(BuildContext context) {
    // Get user data from your auth state or pass as parameter
    final firstName = 'John'; // Replace with actual user data
    final lastName = 'Doe';
    final email = 'john@example.com';
    final phone = '+628123456789';

    final paymentService = MidtransPaymentService(
      baseUrl: 'http://localhost:8123', // Backend URL
      authToken: '', // Will be set from auth state
    );

    return BlocProvider(
      create: (_) => MidtransPaymentBloc(paymentService),
      child: _PaymentContent(
        orderId: orderId,
        amount: amount,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        itemName: itemName,
        itemId: itemId,
        event: event,
      ),
    );
  }
}

class _PaymentContent extends StatefulWidget {
  final String orderId;
  final double amount;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String itemName;
  final String itemId;
  final Event? event;

  const _PaymentContent({
    required this.orderId,
    required this.amount,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.itemName,
    required this.itemId,
    this.event,
  });

  @override
  State<_PaymentContent> createState() => _PaymentContentState();
}

class _PaymentContentState extends State<_PaymentContent> {
  @override
  void initState() {
    super.initState();
    // Start payment flow automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiatePayment();
    });
  }

  void _initiatePayment() {
    final request = PaymentInitRequest(
      orderId: widget.orderId,
      amount: widget.amount,
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      phone: widget.phone,
      itemName: widget.itemName,
      itemId: widget.itemId,
    );

    context.read<MidtransPaymentBloc>().add(InitiatePaymentEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MidtransPaymentBloc, PaymentState>(
      listener: (context, state) {
        // Handle payment result
        if (state is PaymentSuccess) {
          _showSuccessDialog(state);
        } else if (state is PaymentFailed) {
          _showErrorDialog(state);
        } else if (state is PaymentPending) {
          _showPendingDialog(state);
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Pembayaran'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<MidtransPaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return _buildLoadingState();
        }

        if (state is PaymentError) {
          return _buildErrorState(state.message);
        }

        if (state is PaymentTokenLoaded) {
          // Show WebView for payment
          return _PaymentWebView(
            snapUrl: state.redirectUrl,
            orderId: state.orderId,
            onPaymentResult: _handlePaymentResult,
          );
        }

        // Default: show payment details
        return _buildPaymentDetails();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            'Memproses pembayaran...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jangan tutup aplikasi',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.alertCircle, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Terjadi Kesalahan',
              style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initiatePayment,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          _buildOrderSummary(),
          const SizedBox(height: 24),
          // Payment Methods
          _buildPaymentMethods(),
          const SizedBox(height: 24),
          // Info Section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Pesanan',
                style: AppTextStyles.bodyMediumBold,
              ),
            ],
          ),
          const Divider(height: 20),
          _buildSummaryRow('Item', widget.itemName),
          _buildSummaryRow('Order ID', widget.orderId),
          const Divider(height: 16),
          _buildSummaryRow(
            'Total Pembayaran',
            _formatAmount(widget.amount),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            color: isBold ? AppColors.secondary : AppColors.textEmphasis,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran Tersedia',
          style: AppTextStyles.bodyMediumBold,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPaymentMethodChip('QRIS', LucideIcons.qrCode),
            _buildPaymentMethodChip('GoPay', LucideIcons.wallet),
            _buildPaymentMethodChip('ShopeePay', LucideIcons.shoppingBag),
            _buildPaymentMethodChip('BCA VA', LucideIcons.landmark),
            _buildPaymentMethodChip('Mandiri VA', LucideIcons.creditCard),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pembayaran aman dengan enkripsi SSL',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentResult(bool success) {
    final bloc = context.read<MidtransPaymentBloc>();
    if (success) {
      bloc.add(CheckPaymentStatusEvent(widget.orderId));
    } else {
      bloc.handlePaymentResult(
        orderId: widget.orderId,
        success: false,
        errorMessage: 'Payment cancelled or failed',
      );
    }
  }

  void _showSuccessDialog(PaymentSuccess state) {
    // If event is provided, use new celebration flow
    if (widget.event != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCelebrationAndTicket(state);
      });
      return;
    }

    // Fallback to old dialog for non-event payments
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.check, size: 32, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text(
              'Pembayaran Berhasil!',
              style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${state.orderId}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (state.transactionId != null)
              Text(
                'Transaction ID: ${state.transactionId}',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCelebrationAndTicket(PaymentSuccess state) {
    final eventId = widget.event!.id;
    final eventName = widget.event!.title;
    final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    showCelebrationBottomSheet(
      context: context,
      eventName: eventName,
      eventId: eventId,
      ticketId: ticketId,
      onViewTicket: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostPaymentTicketScreen(
              event: widget.event!,
              ticketId: ticketId,
            ),
          ),
        );
      },
      onFindFriends: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostPaymentTicketScreen(
              event: widget.event!,
              ticketId: ticketId,
            ),
          ),
        );
      },
      onShare: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostPaymentTicketScreen(
              event: widget.event!,
              ticketId: ticketId,
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(PaymentFailed state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.xCircle, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Pembayaran Gagal',
              style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _initiatePayment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingDialog(PaymentPending state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.clock, size: 32, color: AppColors.warning),
            ),
            const SizedBox(height: 16),
            Text(
              'Pembayaran Pending',
              style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Selesaikan pembayaran Anda. Order ID: ${state.orderId}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, false); // Return pending
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cek Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

/// WebView for Midtrans Snap payment
class _PaymentWebView extends StatefulWidget {
  final String snapUrl;
  final String orderId;
  final Function(bool) onPaymentResult;

  const _PaymentWebView({
    required this.snapUrl,
    required this.orderId,
    required this.onPaymentResult,
  });

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) {
            // Check for payment finish callback
            if (request.url.contains('flyerr://payment/finish')) {
              widget.onPaymentResult(true);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('flyerr://payment/error')) {
              widget.onPaymentResult(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Payment progress header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceAlt,
              child: Row(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menunggu Pembayaran',
                          style: AppTextStyles.bodyMediumBold,
                        ),
                        Text(
                          'Order ID: ${widget.orderId}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _showCancelDialog();
                    },
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
      ],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
          'Pembayaran Anda belum selesai. Apakah Anda yakin ingin membatalkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentResult(false);
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

/// Helper function to navigate and get payment result
///
/// Usage:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => MidtransPaymentScreen(...),
///   ),
/// );
///
/// if (result == true) {
///   // Payment successful
/// } else if (result == false) {
///   // Payment pending
/// } else {
///   // Payment failed or cancelled
/// }
/// ```
