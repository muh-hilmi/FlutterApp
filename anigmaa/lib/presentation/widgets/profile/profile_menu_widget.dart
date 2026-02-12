import 'package:flutter/material.dart';
import '../../../injection_container.dart' as di;
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../main.dart' show navigatorKey;
import 'package:google_fonts/google_fonts.dart';

class ProfileMenuWidget {
  static void showMenuBottomSheet(
    BuildContext context, {
    bool isOwnProfile = true,
    VoidCallback? onShareProfile,
    VoidCallback? onBlockUser,
    VoidCallback? onReportUser,
    VoidCallback? onMyEvents,
    VoidCallback? onMyTickets,
    VoidCallback? onTransactions,
    VoidCallback? onSavedItems,
    VoidCallback? onQRCode,
    VoidCallback? onSettings,
    VoidCallback? onLogout,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Penting untuk mengontrol scroll
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (isOwnProfile) ...[
              _buildMenuSheetItem(
                icon: Icons.event,
                title: 'Event Saya',
                onTap: onMyEvents,
              ),
              _buildMenuSheetItem(
                icon: Icons.confirmation_number,
                title: 'Tiket Gue',
                onTap: onMyTickets,
              ),
              _buildMenuSheetItem(
                icon: Icons.receipt_long,
                title: 'Transaksi',
                onTap: onTransactions,
              ),
              _buildMenuSheetItem(
                icon: Icons.bookmark,
                title: 'Tersimpan',
                onTap: onSavedItems,
              ),
              _buildMenuSheetItem(
                icon: Icons.qr_code,
                title: 'QR Code Gue',
                onTap: onQRCode,
              ),
              _buildMenuSheetItem(
                icon: Icons.settings,
                title: 'Pengaturan',
                onTap: onSettings,
              ),
              const Divider(),
              _buildMenuSheetItem(
                icon: Icons.bug_report,
                title: '🔧 Hapus Data Auth (Debug)',
                iconColor: Colors.orange,
                textColor: Colors.orange,
                onTap: () async {
                  Navigator.pop(context);
                  final authService = di.sl<AuthService>();
                  await authService.clearAuthData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Auth data cleared! Reload app to test 401 handler',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              _buildMenuSheetItem(
                icon: Icons.logout,
                title: 'Keluar',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: onLogout,
              ),
            ] else ...[
              _buildMenuSheetItem(
                icon: Icons.share,
                title: 'Bagikan Profil',
                onTap: onShareProfile,
              ),
              _buildMenuSheetItem(
                icon: Icons.block,
                title: 'Blokir Pengguna',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: onBlockUser,
              ),
              _buildMenuSheetItem(
                icon: Icons.report,
                title: 'Laporkan',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: onReportUser,
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
        ),
      ),
    );
  }

  static Widget _buildMenuSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[800], size: 24),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Keluar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin mau keluar?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleLogout(context);
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleLogout(BuildContext context) async {
    try {
      final authService = di.sl<AuthService>();
      final googleAuthService = di.sl<GoogleAuthService>();

      await googleAuthService.signOut();
      await authService.logout();

      // Use global navigator key for reliable navigation
      final globalContext = navigatorKey.currentContext;
      if (globalContext != null && globalContext.mounted) {
        Navigator.of(
          globalContext,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      final globalContext = navigatorKey.currentContext ?? context;
      if (globalContext.mounted) {
        ScaffoldMessenger.of(globalContext).showSnackBar(
          SnackBar(
            content: Text('Logout gagal. Coba lagi ya! 😅'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
