import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assignment_tracker/services/notification_helper.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment_tracker/screens/marks_setting_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = true;
  bool _ringed = true;
  bool _darkModeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _loadRingSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await NotificationHelper.areNotificationsEnabled();
    final ringEnabled = await NotificationHelper.isRingEnabled();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = enabled;
      _ringed = ringEnabled;
    });
  }

  Future<void> _loadRingSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _ringed = prefs.getBool('ring_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    await NotificationHelper.setNotificationsEnabled(value);
  }

  Future<void> _toggleRingSetting(bool value) async {
    setState(() {
      _ringed = value;
    });
    await NotificationHelper.setRingEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.h),
              // Header
              Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                'Personalizing your digital workspace.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 34.h),

              // Preferences Container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(21.r),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      trailing: CupertinoSwitch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: const Color.fromARGB(
                          194,
                          43,
                          203,
                          11,
                        ), // The track color when ON
                        trackColor:
                            AppColors.element, // The track color when OFF
                        thumbColor: Colors.white, // The circular knob color
                      ),
                    ),

                    Divider(color: Colors.white.withOpacity(0.05), height: 1),

                    _buildSettingsRow(
                      icon: Icons.phonelink_ring_rounded,
                      title: 'Ring',
                      trailing: CupertinoSwitch(
                        value: _ringed,
                        onChanged: _toggleRingSetting,
                        activeColor: const Color.fromARGB(194, 43, 203, 11),
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
                        children: [
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MarksSettingScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // System Section
              Text(
                'SYSTEM',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: _buildSettingsRow(
                  icon: Icons.cloud_outlined,
                  iconColor: AppColors.mutedText,
                  title: 'Backup',
                  titleColor: AppColors.mutedText,
                  subtitle: 'Coming soon in v2.0',
                  trailing: Icon(
                    Icons.lock_outline,
                    color: AppColors.mutedText,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Information Section
              Text(
                'INFORMATION',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: _buildSettingsRow(
                  icon: Icons.info_outline,
                  title: 'About',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v1.4.2',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText.withOpacity(0.5),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 48.h),

              SizedBox(height: 100.h), // Spacing for bottom nav bar
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 16.0.h),
        child: Row(
          children: [
            // Icon
            Icon(icon, color: iconColor ?? AppColors.primaryText, size: 18.7.w),
            SizedBox(width: 16.w),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? AppColors.primaryText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.sp,
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
      ),
    );
  }
}
