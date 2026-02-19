// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _allNotifications = true;
  bool _eventReminders = true;
  bool _newEvents = true;
  bool _eventUpdates = true;
  bool _socialNotifications = true;
  bool _newFollowers = true;
  bool _eventInvites = true;
  bool _messages = true;
  bool _marketingEmails = false;
  bool _weeklyDigest = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  String _reminderTiming = '1 jam sebelumnya';
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';

  final List<String> _reminderOptions = [
    '15 menit sebelumnya',
    '30 menit sebelumnya',
    '1 jam sebelumnya',
    '2 jam sebelumnya',
    '1 hari sebelumnya',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Pengaturan Notifikasi 🔔',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              title: 'Umum 📲',
              children: [
                _buildSwitchTile(
                  title: 'Semua Notifikasi',
                  subtitle: 'Tombol utama buat semua notif',
                  value: _allNotifications,
                  onChanged: (value) {
                    setState(() {
                      _allNotifications = value;
                      if (!value) {
                        _eventReminders = false;
                        _newEvents = false;
                        _eventUpdates = false;
                        _socialNotifications = false;
                        _newFollowers = false;
                        _eventInvites = false;
                        _messages = false;
                      }
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Event 🎉',
              children: [
                _buildSwitchTile(
                  title: 'Pengingat Event',
                  subtitle: 'Dapetin notif sebelum event dimulai',
                  value: _eventReminders && _allNotifications,
                  onChanged: _allNotifications ? (value) {
                    setState(() {
                      _eventReminders = value;
                    });
                  } : null,
                ),
                _buildReminderTimingTile(),
                _buildSwitchTile(
                  title: 'Event Baru',
                  subtitle: 'Notif buat event baru di area lo',
                  value: _newEvents && _allNotifications,
                  onChanged: _allNotifications ? (value) {
                    setState(() {
                      _newEvents = value;
                    });
                  } : null,
                ),
                _buildSwitchTile(
                  title: 'Update Event',
                  subtitle: 'Perubahan event yang lo ikutin',
                  value: _eventUpdates && _allNotifications,
                  onChanged: _allNotifications ? (value) {
                    setState(() {
                      _eventUpdates = value;
                    });
                  } : null,
                ),
              ],
            ),
            _buildSection(
              title: 'Sosial 👥',
              children: [
                _buildSwitchTile(
                  title: 'Notifikasi Sosial',
                  subtitle: 'Notif dari jaringan sosial lo',
                  value: _socialNotifications && _allNotifications,
                  onChanged: _allNotifications ? (value) {
                    setState(() {
                      _socialNotifications = value;
                      if (!value) {
                        _newFollowers = false;
                        _eventInvites = false;
                        _messages = false;
                      }
                    });
                  } : null,
                ),
                _buildSwitchTile(
                  title: 'Follower Baru',
                  subtitle: 'Kalo ada yang follow lo',
                  value: _newFollowers && _socialNotifications && _allNotifications,
                  onChanged: (_allNotifications && _socialNotifications) ? (value) {
                    setState(() {
                      _newFollowers = value;
                    });
                  } : null,
                ),
                _buildSwitchTile(
                  title: 'Undangan Event',
                  subtitle: 'Kalo lo diundang ke event',
                  value: _eventInvites && _socialNotifications && _allNotifications,
                  onChanged: (_allNotifications && _socialNotifications) ? (value) {
                    setState(() {
                      _eventInvites = value;
                    });
                  } : null,
                ),
                _buildSwitchTile(
                  title: 'Pesan Masuk',
                  subtitle: 'Pesan langsung dari user lain',
                  value: _messages && _socialNotifications && _allNotifications,
                  onChanged: (_allNotifications && _socialNotifications) ? (value) {
                    setState(() {
                      _messages = value;
                    });
                  } : null,
                ),
              ],
            ),
            _buildSection(
              title: 'Email 📧',
              children: [
                _buildSwitchTile(
                  title: 'Email Marketing',
                  subtitle: 'Konten promo & penawaran menarik',
                  value: _marketingEmails,
                  onChanged: (value) {
                    setState(() {
                      _marketingEmails = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Ringkasan Mingguan',
                  subtitle: 'Rangkuman event & aktivitas setiap minggu',
                  value: _weeklyDigest,
                  onChanged: (value) {
                    setState(() {
                      _weeklyDigest = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Suara & Getar 🔊',
              children: [
                _buildSwitchTile(
                  title: 'Suara',
                  subtitle: 'Bunyiin suara buat notif',
                  value: _soundEnabled && _allNotifications,
                  onChanged: _allNotifications ? (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  } : null,
                ),
                _buildSwitchTile(
                  title: 'Getar',
                  subtitle: 'HP getar kalo ada notif',
                  value: _vibrationEnabled && _allNotifications,
                  onChanged: _allNotifications ? (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  } : null,
                ),
              ],
            ),
            _buildSection(
              title: 'Jam Hening 😴',
              children: [
                _buildQuietHoursTile(
                  title: 'Mulai',
                  time: _quietHoursStart,
                  onChanged: (time) {
                    setState(() {
                      _quietHoursStart = time;
                    });
                  },
                ),
                _buildQuietHoursTile(
                  title: 'Selesai',
                  time: _quietHoursEnd,
                  onChanged: (time) {
                    setState(() {
                      _quietHoursEnd = time;
                    });
                  },
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
            style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Container(
          color: AppColors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          color: onChanged != null ? AppColors.textEmphasis : AppColors.textTertiary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildReminderTimingTile() {
    return ListTile(
      title: Text(
        'Waktu Pengingat',
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          color: (_allNotifications && _eventReminders) ? AppColors.textEmphasis : AppColors.textTertiary,
        ),
      ),
      subtitle: Text(
        _reminderTiming,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
      ),
      onTap: (_allNotifications && _eventReminders) ? _showReminderTimingDialog : null,
    );
  }

  Widget _buildQuietHoursTile({
    required String title,
    required String time,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textEmphasis,
        ),
      ),
      subtitle: Text(
        time,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.access_time,
        color: AppColors.textTertiary,
      ),
      onTap: () => _showTimePicker(time, onChanged),
    );
  }

  void _showReminderTimingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Waktu Pengingat'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _reminderOptions.length,
            itemBuilder: (context, index) {
              final option = _reminderOptions[index];
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _reminderTiming,
                onChanged: (value) {
                  setState(() {
                    _reminderTiming = value!;
                  });
                  Navigator.pop(context);
                },
                fillColor: WidgetStateProperty.all(AppColors.primary),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(String currentTime, ValueChanged<String> onChanged) async {
    final timeParts = currentTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(formattedTime);
    }
  }
}
