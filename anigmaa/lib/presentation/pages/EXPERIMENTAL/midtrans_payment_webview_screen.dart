// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29
// TODO: DUPLIKAT dengan midtrans_payment_screen.dart - REVIEW NANTI!

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/utils/app_logger.dart';

/// Midtrans Payment WebView Screen
///
/// Shows the Midtrans Snap payment page in a WebView
class MidtransPaymentWebViewScreen extends StatefulWidget {
  final String snapUrl;
  final String orderId;
  final int amount;

  const MidtransPaymentWebViewScreen({
    super.key,
    required this.snapUrl,
    required this.orderId,
    required this.amount,
  });

  @override
  State<MidtransPaymentWebViewScreen> createState() =>
      _MidtransPaymentWebViewScreenState();
}

class _MidtransPaymentWebViewScreenState
    extends State<MidtransPaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            // WebView started: $url
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            // WebView finished: $url

            // Check for payment completion via URL
            _checkPaymentStatus(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Navigation request: ${request.url}

            // Check for finish callback
            if (request.url.contains('finish') ||
                request.url.contains('success')) {
              // Payment completed
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }

            // Check for error callback
            if (request.url.contains('error') ||
                request.url.contains('deny') ||
                request.url.contains('cancel')) {
              // Payment failed/cancelled
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            // WebView resource error: ${error.description}
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  void _checkPaymentStatus(String url) {
    // Inject JavaScript to check payment status
    _controller.runJavaScript('''
      (function() {
        // Check if payment success message is visible
        const successElements = document.querySelectorAll('[class*="success"], [class*="Success"], [id*="success"]');
        if (successElements.length > 0) {
          window.flutter_inappwebview.callHandler('paymentSuccess');
        }

        // Check for payment completed
        const statusElement = document.querySelector('.payment-status, [data-status]');
        if (statusElement) {
          const status = statusElement.getAttribute('data-status') || statusElement.textContent;
          if (status && (status.includes('success') || status.includes('completed'))) {
            window.flutter_inappwebview.callHandler('paymentSuccess');
          }
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        centerTitle: true,
        backgroundColor: const Color(0xFFBBC863),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFBBC863)),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order: ${widget.orderId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFFBBC863),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selesaikan pembayaran Anda',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Jangan tutup halaman ini sebelum pembayaran selesai',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBBC863)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _checkStatusManually(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBBC863),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cek Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Return failed
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _checkStatusManually() {
    // Inject JavaScript to check current status
    _controller.runJavaScript('''
      (function() {
        // Look for payment status indicators
        const statusSelectors = [
          '.payment-status',
          '[data-status]',
          '.status',
          '#status'
        ];

        for (const selector of statusSelectors) {
          const element = document.querySelector(selector);
          if (element) {
            return element.textContent || element.getAttribute('data-status') || '';
          }
        }

        // Check URL as fallback
        return window.location.href;
      })();
    ''');
    // Status check triggered
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memeriksa status pembayaran...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
