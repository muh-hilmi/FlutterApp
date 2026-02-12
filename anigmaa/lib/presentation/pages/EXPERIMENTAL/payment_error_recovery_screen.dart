// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum PaymentErrorType {
  insufficient,
  network,
  expired,
  declined,
  timeout,
  system,
}

class PaymentErrorRecoveryScreen extends StatefulWidget {
  final PaymentErrorType errorType;
  final String? eventName;
  final double? amount;
  final String? errorMessage;

  const PaymentErrorRecoveryScreen({
    super.key,
    required this.errorType,
    this.eventName,
    this.amount,
    this.errorMessage,
  });

  @override
  State<PaymentErrorRecoveryScreen> createState() =>
      _PaymentErrorRecoveryScreenState();
}

class _PaymentErrorRecoveryScreenState
    extends State<PaymentErrorRecoveryScreen> {
  bool _isRetrying = false;
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = [
    'GoPay',
    'OVO',
    'Dana',
    'BC Virtual Account',
    'QRIS',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = _paymentMethods.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Elements matching ErrorStateWidget
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 24,
                        ), // Added spacing to push content down a bit
                        _buildErrorIllustration(),
                        const SizedBox(height: 32), // Increased spacing
                        _buildErrorTitle(),
                        const SizedBox(height: 12),
                        _buildErrorMessage(),
                        const SizedBox(height: 32),
                        _buildPaymentSummary(),
                        const SizedBox(height: 24),
                        _buildPaymentMethodSelector(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Pembayaran Gagal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIllustration() {
    IconData icon;
    Color color;

    switch (widget.errorType) {
      case PaymentErrorType.insufficient:
        icon = LucideIcons.wallet;
        color = Colors.orange;
        break;
      case PaymentErrorType.network:
        icon = LucideIcons.wifiOff;
        color = Colors.blue;
        break;
      case PaymentErrorType.expired:
        icon = LucideIcons.clock;
        color = Colors.purple;
        break;
      case PaymentErrorType.declined:
        icon = LucideIcons.creditCard;
        color = Colors.red;
        break;
      case PaymentErrorType.timeout:
        icon = LucideIcons.timer;
        color = Colors.orange;
        break;
      case PaymentErrorType.system:
        icon = LucideIcons.server;
        color = Colors.grey;
        break;
    }

    return Container(
      width: 120, // Increased size
      height: 120, // Increased size
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: 50, color: color), // Increased icon size
      ),
    );
  }

  Widget _buildErrorTitle() {
    String title;

    switch (widget.errorType) {
      case PaymentErrorType.insufficient:
        title = 'Saldo Tidak Mencukupi';
        break;
      case PaymentErrorType.network:
        title = 'Koneksi Bermasalah';
        break;
      case PaymentErrorType.expired:
        title = 'Waktu Pembayaran Habis';
        break;
      case PaymentErrorType.declined:
        title = 'Pembayaran Ditolak';
        break;
      case PaymentErrorType.timeout:
        title = 'Waktu Habis';
        break;
      case PaymentErrorType.system:
        title = 'Sistem Sedang Sibuk';
        break;
    }

    return Text(
      title,
      style: const TextStyle(
        // Using GoogleFonts.plusJakartaSans not available here without import, stick to TextStyle but match properties
        fontSize: 20, // Matched ErrorStateWidget
        fontWeight: FontWeight.w700, // Matched ErrorStateWidget
        color: Color(0xFF2D3142), // Matched ErrorStateWidget
        letterSpacing: -0.5, // Matched ErrorStateWidget
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    String message = widget.errorMessage ?? _getDefaultMessage();

    return Text(
      message,
      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      textAlign: TextAlign.center,
    );
  }

  String _getDefaultMessage() {
    switch (widget.errorType) {
      case PaymentErrorType.insufficient:
        return 'Saldo atau limit pembayaran Anda tidak mencukupi. Silakan gunakan metode pembayaran lain atau top up saldo.';
      case PaymentErrorType.network:
        return 'Koneksi internet terputus saat memproses pembayaran. Silakan periksa koneksi Anda dan coba lagi.';
      case PaymentErrorType.expired:
        return 'Waktu pembayaran telah habis. Silakan coba lagi dengan membuat pesanan baru.';
      case PaymentErrorType.declined:
        return 'Pembayaran ditolak oleh penyedia layanan. Silakan gunakan metode pembayaran lain atau hubungi bank Anda.';
      case PaymentErrorType.timeout:
        return 'Permintaan pembayaran timeout. Server tidak merespon dalam waktu yang ditentukan.';
      case PaymentErrorType.system:
        return 'Kami mengalami gangguan sistem. Silakan coba lagi dalam beberapa saat.';
    }
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (widget.eventName != null) ...[
            _buildSummaryRow('Event', widget.eventName!),
            const Divider(height: 16),
          ],
          if (widget.amount != null)
            _buildSummaryRow(
              'Total',
              'Rp ${_formatAmount(widget.amount!)}',
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
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ganti Metode Pembayaran',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...List.generate(_paymentMethods.length, (index) {
          final method = _paymentMethods[index];
          final isSelected = _selectedPaymentMethod == method;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFBBC863)
                      : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? const Color(0xFFBBC863).withValues(alpha: 0.05)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                    color: isSelected
                        ? const Color(0xFFBBC863)
                        : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (method.contains('VA'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isRetrying ? null : _retryPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRetrying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Coba Lagi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _contactSupport,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hubungi Support',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Kembali ke Event',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  void _retryPayment() async {
    setState(() {
      _isRetrying = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });

      // Show success or navigate to payment processing
      _showRetrySuccess();
    }
  }

  void _showRetrySuccess() {
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
                color: const Color(0xFFD4EDDA),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, color: Color(0xFF155724)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memproses Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Color(0xFFBBC863)),
          ],
        ),
      ),
    );

    // Navigate to payment result after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close error screen
        // Navigate to success screen or back to event detail
      }
    });
  }

  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hubungi Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              LucideIcons.messageCircle,
              'Live Chat',
              'Chat dengan tim support kami',
              () {},
            ),
            _buildSupportOption(
              LucideIcons.mail,
              'Email',
              'support@flyerr.id',
              () {},
            ),
            _buildSupportOption(
              LucideIcons.phone,
              'Telepon',
              '+62 21 1234 5678',
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFBBC863).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFFBBC863)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: onTap,
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
