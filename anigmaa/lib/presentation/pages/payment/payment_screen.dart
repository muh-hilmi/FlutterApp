import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/transaction.dart';
import '../../bloc/payment/payment_bloc.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/app_logger.dart';
import '../tickets/post_payment_ticket_screen.dart';
import '../../widgets/tickets/celebration_bottom_sheet.dart';
import '../../../injection_container.dart';
import '../EXPERIMENTAL/midtrans_payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Event event;

  const PaymentScreen({super.key, required this.event});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late PaymentBloc _paymentBloc;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.qris;

  @override
  void initState() {
    super.initState();
    _paymentBloc = sl<PaymentBloc>();
    // Reset state to ensure clean slate for new payment
    _paymentBloc.add(const ResetPaymentState());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _paymentBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            AppLogger().info('PaymentBloc Listener: status=${state.status}, isInitiated=${state.isInitiated}, paymentUrl=${state.paymentUrl}');

            if (state.isInitiated && state.paymentUrl != null) {
              final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
              AppLogger().info('NAVIGATING TO WEBVIEW: ${state.paymentUrl}, isCurrent=$isCurrent');

              if (isCurrent) {
                AppLogger().info('Navigating to MidtransPaymentWebViewScreen...');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MidtransPaymentWebViewScreen(
                      snapUrl: state.paymentUrl!,
                      orderId: state.transactionId ?? '',
                      amount: widget.event.price?.toInt() ?? 0,
                    ),
                  ),
                ).then((result) {
                  AppLogger().info('Payment WebView result: $result');
                  if (result == true) {
                    // Payment successful
                    if (!mounted) return;
                    context.read<PaymentBloc>().add(
                      PaymentSuccess(transactionId: state.transactionId ?? ''),
                    );
                  } else if (result == false) {
                    // Payment failed or cancelled
                    if (!mounted) return;
                    context.read<PaymentBloc>().add(
                      PaymentFailed('Payment dibatalkan atau gagal'),
                    );
                  }
                });
              } else {
                AppLogger().warning('Navigation blocked: route is not current');
              }
            } else if (state.isSuccess) {
              _showSuccessDialog();
            } else if (state.isError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? 'Terjadi kesalahan saat pembayaran',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Custom AppBar
                _buildAppBar(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Summary Card
                        _buildEventSummaryCard(),

                        const SizedBox(height: 24),

                        // Payment Methods
                        _buildPaymentMethodsSection(state),

                        const SizedBox(height: 24),

                        // Price Details
                        _buildPriceDetailsSection(),

                        const SizedBox(height: 32),

                        // Pay Button
                        _buildPayButton(state),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF2D3142),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Pembayaran Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSummaryCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image Placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.event_rounded,
                  size: 40,
                  color: Color(0xFFBBC863),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFFBBC863),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.event.startTime.toLocal().day}/${widget.event.startTime.toLocal().month}/${widget.event.startTime.toLocal().year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFFBBC863),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.event.location.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C757D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(PaymentState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
          ),
        ),

        const SizedBox(height: 12),

        // QRIS Option (via Midtrans)
        _buildPaymentOption(
          title: 'QRIS',
          subtitle: 'Scan QR untuk bayar',
          icon: Icons.qr_code,
          color: Colors.purple,
          isSelected: _selectedPaymentMethod == PaymentMethod.qris,
          onTap: () =>
              setState(() => _selectedPaymentMethod = PaymentMethod.qris),
        ),

        const SizedBox(height: 8),

        // GoPay Option (via Midtrans)
        _buildPaymentOption(
          title: 'GoPay',
          subtitle: 'Bayar dengan GoPay',
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          isSelected: _selectedPaymentMethod == PaymentMethod.gopay,
          onTap: () =>
              setState(() => _selectedPaymentMethod = PaymentMethod.gopay),
        ),

        const SizedBox(height: 8),

        // ShopeePay Option (via Midtrans)
        _buildPaymentOption(
          title: 'ShopeePay',
          subtitle: 'Bayar dengan ShopeePay',
          icon: Icons.shopping_bag,
          color: Colors.orange,
          isSelected: _selectedPaymentMethod == PaymentMethod.shopeePay,
          onTap: () =>
              setState(() => _selectedPaymentMethod = PaymentMethod.shopeePay),
        ),

        const SizedBox(height: 8),

        // DANA Option (via Midtrans)
        _buildPaymentOption(
          title: 'DANA',
          subtitle: 'Bayar dengan DANA',
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
          isSelected: _selectedPaymentMethod == PaymentMethod.dana,
          onTap: () =>
              setState(() => _selectedPaymentMethod = PaymentMethod.dana),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBBC863)
                : const Color(0xFFE9ECEF),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0x0FBBC863)
                  : const Color(0x0F000000),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFFBBC863)
                          : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFBBC863),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetailsSection() {
    final price = widget.event.price ?? 0;
    final paymentFee = _getPaymentFee();
    final appFee = _getAppFee(price.toInt());
    final total = price + paymentFee + appFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3142),
            ),
          ),

          const SizedBox(height: 12),

          _buildPriceRow('Harga Tiket Event', price.toInt()),
          if (paymentFee > 0)
            _buildPriceRow('Biaya Layanan Pembayaran', paymentFee),
          _buildPriceRow('Biaya Layanan Aplikasi (5%)', appFee),

          const Divider(height: 20, color: Color(0xFFE9ECEF)),

          _buildPriceRow('Total Dibayar', total.toInt(), isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal
                  ? const Color(0xFF2D3142)
                  : const Color(0xFF6C757D),
            ),
          ),
          Text(
            CurrencyFormatter.formatToRupiah(amount.toDouble()),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              color: isTotal
                  ? const Color(0xFFBBC863)
                  : const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(PaymentState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBBC863),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(
            0xFFBBC863,
          ).withValues(alpha: 0.5),
        ),
        child: state.isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Memproses...'),
                ],
              )
            : Text(
                'Bayar ${CurrencyFormatter.formatToRupiah((widget.event.price ?? 0).toDouble() + _calculateFee(widget.event.price?.toInt() ?? 0))}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  void _initiatePayment() {
    final price = widget.event.price ?? 0;
    final fee = _calculateFee(price.toInt());
    final totalAmount = price + fee;

    // Use _paymentBloc directly instead of context.read
    _paymentBloc.add(
      InitiatePayment(
        event: widget.event,
        paymentMethod: _selectedPaymentMethod,
        totalAmount: totalAmount.toInt(),
      ),
    );
  }

  void _showSuccessDialog() {
    // Show celebration bottom sheet with new post-payment flow
    showCelebrationBottomSheet(
      context: context,
      eventName: widget.event.title,
      eventId: widget.event.id,
      onViewTicket: () {
        // Navigate to ticket screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostPaymentTicketScreen(event: widget.event),
          ),
        );
      },
      onFindFriends: () {
        // Navigate to ticket screen, friends feature can be added later
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostPaymentTicketScreen(event: widget.event),
          ),
        );
      },
      onShare: () {
        // Navigate to ticket screen, share can be implemented later
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PostPaymentTicketScreen(event: widget.event),
          ),
        );
      },
    );
  }

  int _calculateFee(int amount) {
    // 1. Payment Service Fee (Midtrans MDR - Fixed)
    // QRIS: 0.7%
    // GoPay: 2%
    // ShopeePay: 2%
    // DANA: 1.5%
    int paymentFee = 0;
    switch (_selectedPaymentMethod) {
      case PaymentMethod.qris:
        paymentFee = (amount * 0.007).ceil(); // 0.7%
        break;
      case PaymentMethod.gopay:
        paymentFee = (amount * 0.02).ceil(); // 2%
        break;
      case PaymentMethod.shopeePay:
        paymentFee = (amount * 0.02).ceil(); // 2%
        break;
      case PaymentMethod.dana:
        paymentFee = (amount * 0.015).ceil(); // 1.5%
        break;
      default:
        paymentFee = 0;
    }

    // 2. App Service Fee (5%)
    int appFee = (amount * 0.05).ceil();

    return paymentFee + appFee;
  }

  int _getPaymentFee() {
    final amount = widget.event.price?.toInt() ?? 0;
    switch (_selectedPaymentMethod) {
      case PaymentMethod.qris:
        return (amount * 0.007).ceil(); // 0.7%
      case PaymentMethod.gopay:
        return (amount * 0.02).ceil(); // 2%
      case PaymentMethod.shopeePay:
        return (amount * 0.02).ceil(); // 2%
      case PaymentMethod.dana:
        return (amount * 0.015).ceil(); // 1.5%
      default:
        return 0;
    }
  }

  int _getAppFee(int amount) {
    return (amount * 0.05).ceil();
  }
}
