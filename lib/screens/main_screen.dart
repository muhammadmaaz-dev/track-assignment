import 'package:assignment_tracker/screens/history_screen.dart';
import 'package:assignment_tracker/screens/home_screen.dart';
import 'package:assignment_tracker/screens/setting_screen.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:telegram_nav_bar/telegram_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,

        extendBody: true,

        body: IndexedStack(index: _currentIndex, children: _screens),

        // FAB has been entirely removed
        bottomNavigationBar: TelegramNavBar(
          margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 7.h),
          borderRadius: BorderRadius.circular(27.r),
          showTopDivider: false,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            TelegramNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            TelegramNavItem(
              icon: Icons.history_toggle_off,
              activeIcon: Icons.history_sharp,
              label: 'History',
            ),
            TelegramNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
