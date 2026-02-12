// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../data/datasources/user_remote_datasource.dart';
import '../../../injection_container.dart' as di;
import '../../../main.dart' show navigatorKey;
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _locationEnabled = true;

  // REDNOTE: Language settings to be re-enabled in future release
  // Consider using localization package for better language support

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengaturan ⚙️',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              title: 'Preferensi Gue',
              children: [
                // REDNOTE: Dark mode feature to be implemented in future release
                // Consider using system theme controller with proper theme management
                _buildSwitchTile(
                  icon: Icons.location_on,
                  title: 'Layanan Lokasi',
                  subtitle: 'Biar gue tau event seru di sekitar lo',
                  value: _locationEnabled,
                  onChanged: (value) async {
                    if (value) {
                      // Request location permission when enabling
                      final permission = await LocationService.checkPermission();

                      if (permission == LocationPermission.denied) {
                        final newPermission = await LocationService.requestPermission();
                        if (newPermission == LocationPermission.denied) {
                          _showMessage('Izin lokasi diperlukan untuk fitur ini');
                          return;
                        }
                      } else if (permission == LocationPermission.deniedForever) {
                        _showLocationPermissionDialog();
                        return;
                      }

                      // Get current location
                      final position = await LocationService.getCurrentPosition();
                      if (position != null) {
                        _showMessage('Lokasi berhasil diaktifkan! 📍');
                      } else {
                        _showMessage('Gagal mendapatkan lokasi. Coba lagi ya!');
                      }
                    }

                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Notifikasi 🔔',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Dapetin notif langsung di HP lo',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    // TODO: Save notification preference to backend
                    // REDNOTE: Need to implement user preference synchronization
                  },
                ),
                // REDNOTE: Email notifications to be implemented in future release
                // Add email service integration before enabling this feature
                _buildNavigationTile(
                  icon: Icons.tune,
                  title: 'Atur Notifikasi',
                  subtitle: 'Sesuain notif sesuai keinginan lo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Privasi & Keamanan 🔒',
              children: [
                _buildNavigationTile(
                  icon: Icons.privacy_tip,
                  title: 'Pengaturan Privasi',
                  subtitle: 'Atur siapa aja yang bisa liat info lo',
                  onTap: () => _showMessage('Pengaturan Privasi segera hadir! 🔜'),
                ),
                _buildNavigationTile(
                  icon: Icons.security,
                  title: 'Keamanan Akun',
                  subtitle: 'Password & autentikasi dua faktor',
                  onTap: _navigateToSecurity,
                ),
                _buildNavigationTile(
                  icon: Icons.block,
                  title: 'User yang Diblokir',
                  subtitle: 'Kelola user yang udah lo blokir',
                  onTap: _navigateToBlockedUsers,
                ),
              ],
            ),
            // TODO: Data & Storage section hidden temporarily
            // _buildSection(
            //   title: 'Data & Storage 💾',
            //   children: [
            //     _buildNavigationTile(
            //       icon: Icons.download,
            //       title: 'Download Data Lo',
            //       subtitle: 'Ekspor semua data akun lo',
            //       onTap: _downloadData,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.storage,
            //       title: 'Storage & Data',
            //       subtitle: 'Kelola penyimpanan & penggunaan data',
            //       onTap: _navigateToStorage,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.clear,
            //       title: 'Bersihin Cache',
            //       subtitle: 'Kosongin space dengan hapus cache',
            //       onTap: _clearCache,
            //     ),
            //   ],
            // ),
            // TODO: Bantuan section hidden temporarily
            // _buildSection(
            //   title: 'Bantuan 💬',
            //   children: [
            //     _buildNavigationTile(
            //       icon: Icons.help,
            //       title: 'Pusat Bantuan',
            //       subtitle: 'Butuh bantuan? Yuk kesini!',
            //       onTap: _navigateToHelp,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.feedback,
            //       title: 'Kirim Feedback',
            //       subtitle: 'Bantu gue tingkatin app ini',
            //       onTap: _sendFeedback,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.bug_report,
            //       title: 'Lapor Bug',
            //       subtitle: 'Ada masalah teknis? Kabarin gue!',
            //       onTap: _reportBug,
            //     ),
            //   ],
            // ),
            _buildSection(
              title: 'Tentang App 📱',
              children: [
                _buildNavigationTile(
                  icon: Icons.info,
                  title: 'Tentang flyerr',
                  subtitle: 'Versi 1.0.0',
                  onTap: _showAbout,
                ),
                // TODO: Syarat & Ketentuan hidden temporarily
                // _buildNavigationTile(
                //   icon: Icons.description,
                //   title: 'Syarat & Ketentuan',
                //   subtitle: 'Baca ketentuan penggunaan app',
                //   onTap: _showTerms,
                // ),
                // TODO: Kebijakan Privasi hidden temporarily
                // _buildNavigationTile(
                //   icon: Icons.policy,
                //   title: 'Kebijakan Privasi',
                //   subtitle: 'Baca kebijakan privasi gue',
                //   onTap: _showPrivacyPolicy,
                // ),
              ],
            ),
            _buildSection(
              title: 'Akun 👤',
              children: [
                _buildNavigationTile(
                  icon: Icons.logout,
                  title: 'Keluar',
                  subtitle: 'Logout dari akun lo',
                  onTap: _signOut,
                  isDestructive: true,
                ),
                _buildNavigationTile(
                  icon: Icons.delete_forever,
                  title: 'Hapus Akun',
                  subtitle: 'Hapus akun lo secara permanen',
                  onTap: _deleteAccount,
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.black,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  // REDNOTE: Language selection feature temporarily disabled
// Will be re-enabled with proper localization support
// Widget _buildLanguageTile() { ... }
// void _showLanguageDialog() { ... }

  void _navigateToSecurity() {
    _showMessage('Keamanan Akun segera hadir! 🔜');
  }

  void _navigateToBlockedUsers() {
    _showMessage('Kelola user yang diblokir segera hadir! 🔜');
  }

  
  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang flyerr'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 1.0.0+1'),
            SizedBox(height: 16),
            Text(
              'flyerr adalah app lo buat nemuin & bikin event keren di komunitas lo! 🎉',
            ),
            SizedBox(height: 16),
            Text('© 2024 flyerr. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
  }

  
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Lokasi Diperlukan'),
        content: const Text(
          'Untuk menemukan event di sekitar lo, flyerr butuh akses ke lokasi. Silakan buka Pengaturan dan aktifkan izin lokasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti Saja'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Lo yakin mau logout? 🤔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Logout from app (clear tokens and user data)
        final authService = di.sl<AuthService>();
        await authService.logout();

        // Sign out from Google
        final googleAuthService = di.sl<GoogleAuthService>();
        await googleAuthService.signOut();

        // Use global navigator key for reliable navigation
        final globalContext = navigatorKey.currentContext;
        if (globalContext != null && globalContext.mounted) {
          Navigator.of(globalContext).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout gagal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Waduh, ini gabisa dibatalin ya! Semua data lo bakal kehapus permanen. 😱',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Menghapus akun...'),
          ],
        ),
      ),
    );

    try {
      // Call API to delete account
      final userDataSource = di.sl<UserRemoteDataSource>();
      await userDataSource.deleteAccount();

      // Clear local auth data
      final authService = di.sl<AuthService>();
      await authService.clearAuthData();

      // Sign out from Google
      final googleAuthService = di.sl<GoogleAuthService>();
      await googleAuthService.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Akun Berhasil Dihapus'),
            content: const Text(
              'Akun Anda telah dihapus secara permanen. Sampai jumpa! 👋',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus akun: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}