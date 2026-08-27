import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment_tracker/screens/main_screen.dart';
import 'package:assignment_tracker/theme/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;

  Future<void> _handleGetStarted() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Request notification permission if not yet granted
      final bool isAllowed =
          await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      // 2. Mark onboarding as completed in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);

      // 3. Navigate to MainScreen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error during onboarding completion: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // App Icon with Rounded Corners and Subtle Glow
              Center(
                child: Container(
                  width: 96.w,
                  height: 96.w,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(26.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.06),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // App Name & Tagline
              Text(
                'Kato',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your distraction-free task & assignment companion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 1),

              // Feature Highlights Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.block_outlined,
                      title: 'No Ads. Ever.',
                      subtitle:
                          'Completely distraction-free with zero popups or banners.',
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      height: 24.h,
                    ),
                    _buildFeatureRow(
                      icon: Icons.lock_outline_rounded,
                      title: '100% Offline & Private',
                      subtitle:
                          'Your tasks, marks, and attachments never leave your device.',
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      height: 24.h,
                    ),
                    _buildFeatureRow(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Free Forever & Open Source',
                      subtitle:
                          'No subscriptions, paywalls, or feature locks.',
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      height: 24.h,
                    ),
                    _buildFeatureRow(
                      icon: Icons.notifications_active_outlined,
                      title: 'Smart Reminders',
                      subtitle:
                          'Custom alerts and countdowns so deadlines never surprise you.',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Fully Rounded Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20.sp,
                              color: Colors.black,
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 14.h),

              // Privacy Footer Note
              Text(
                'By getting started, you enable local reminders on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText.withValues(alpha: 0.7),
                  fontSize: 11.sp,
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.sp,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
