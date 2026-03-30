import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:assignment_tracker/theme/constants.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalizing your digital workspace.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),

              // Preferences Container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      trailing: CupertinoSwitch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeColor: Colors.teal, // The track color when ON
                        trackColor:
                            AppColors.element, // The track color when OFF
                        thumbColor: Colors.white, // The circular knob color
                      ),
                    ),

                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildSettingsRow(
                      icon: Icons.my_library_books_outlined,
                      iconBgColor: Colors.white,
                      iconColor: Colors.white,
                      title: 'Set Marks',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.arrow_forward_ios)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // System Section
              const Text(
                'SYSTEM',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildSettingsRow(
                  icon: Icons.cloud_outlined,
                  iconColor: AppColors.mutedText,
                  title: 'Backup',
                  titleColor: AppColors.mutedText,
                  subtitle: 'Coming soon in v2.0',
                  trailing: const Icon(
                    Icons.lock_outline,
                    color: AppColors.mutedText,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Information Section
              const Text(
                'INFORMATION',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildSettingsRow(
                  icon: Icons.info_outline,
                  title: 'About',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'v1.4.2',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText.withOpacity(0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              const SizedBox(height: 100), // Spacing for bottom nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    Color? iconBgColor,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Row(
        children: [
          // Icon
          Icon(icon, color: iconColor ?? AppColors.primaryText, size: 22),
          const SizedBox(width: 16),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Trailing widget
          trailing,
        ],
      ),
    );
  }
}
