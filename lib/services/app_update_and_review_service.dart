import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper service for Google Play In-App Updates and In-App Reviews.
///
/// Ensures all calls are completely safe, non-blocking, and crash-proof.
class AppUpdateAndReviewService {
  AppUpdateAndReviewService._internal();
  static final AppUpdateAndReviewService _instance =
      AppUpdateAndReviewService._internal();
  static AppUpdateAndReviewService get instance => _instance;
  factory AppUpdateAndReviewService() => _instance;

  static const String prefKeyAppOpenCount = 'app_open_count';
  static const String prefKeyHasReviewed = 'has_reviewed';

  /// Initializes startup checks for in-app updates and reviews sequentially.
  Future<void> initStartupPrompts() async {
    await checkForInAppUpdate();
    await checkAndRequestInAppReview();
  }

  /// Checks Google Play for available app updates and triggers immediate update dialog.
  ///
  /// Safely handles non-Android platforms, emulator environments, and network issues.
  Future<void> checkForInAppUpdate() async {
    // In-App Updates are only supported natively on Android with Google Play Store
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          if (kDebugMode) {
            debugPrint('InAppUpdate: Immediate update available, starting update flow.');
          }
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          if (kDebugMode) {
            debugPrint('InAppUpdate: Flexible update available, starting update flow.');
          }
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        if (kDebugMode) {
          debugPrint('InAppUpdate: No update available or update not required.');
        }
      }
    } catch (e) {
      // Catch silently (e.g. Play Core not available, debug build, network offline)
      if (kDebugMode) {
        debugPrint('InAppUpdate: Silent check error (safe to ignore in debug/offline): $e');
      }
    }
  }

  /// Increments app open count and triggers native In-App Review dialog on the 3rd launch.
  ///
  /// Ensures the review dialog is requested only once by persisting `has_reviewed = true`.
  Future<void> checkAndRequestInAppReview() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Check if user has already been prompted / reviewed
      final bool hasReviewed = prefs.getBool(prefKeyHasReviewed) ?? false;
      if (hasReviewed) {
        if (kDebugMode) {
          debugPrint('InAppReview: User has already been prompted or reviewed.');
        }
        return;
      }

      // Increment launch counter
      final int currentCount = (prefs.getInt(prefKeyAppOpenCount) ?? 0) + 1;
      await prefs.setInt(prefKeyAppOpenCount, currentCount);

      if (kDebugMode) {
        debugPrint('InAppReview: App open count is $currentCount (target: 3)');
      }

      // Trigger review dialog on 3rd launch
      if (currentCount >= 3) {
        final InAppReview inAppReview = InAppReview.instance;
        final bool isAvailable = await inAppReview.isAvailable();

        if (isAvailable) {
          if (kDebugMode) {
            debugPrint('InAppReview: Requesting native in-app review dialog.');
          }
          await inAppReview.requestReview();
          await prefs.setBool(prefKeyHasReviewed, true);
        } else {
          if (kDebugMode) {
            debugPrint('InAppReview: Native review dialog is not available on this device/store.');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InAppReview: Silent review check error: $e');
      }
    }
  }
}
