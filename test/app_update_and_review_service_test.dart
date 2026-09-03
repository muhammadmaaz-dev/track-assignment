import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment_tracker/services/app_update_and_review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppUpdateAndReviewService Tests', () {
    test('Review counter increments and tracks preferences correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppUpdateAndReviewService.prefKeyAppOpenCount), isNull);
      expect(prefs.getBool(AppUpdateAndReviewService.prefKeyHasReviewed), isNull);

      final service = AppUpdateAndReviewService.instance;

      // First run: increments to 1
      await service.checkAndRequestInAppReview();
      expect(prefs.getInt(AppUpdateAndReviewService.prefKeyAppOpenCount), 1);
      expect(prefs.getBool(AppUpdateAndReviewService.prefKeyHasReviewed) ?? false, isFalse);

      // Second run: increments to 2
      await service.checkAndRequestInAppReview();
      expect(prefs.getInt(AppUpdateAndReviewService.prefKeyAppOpenCount), 2);
      expect(prefs.getBool(AppUpdateAndReviewService.prefKeyHasReviewed) ?? false, isFalse);

      // If already reviewed, counter should not increment further
      await prefs.setBool(AppUpdateAndReviewService.prefKeyHasReviewed, true);
      await service.checkAndRequestInAppReview();
      expect(prefs.getInt(AppUpdateAndReviewService.prefKeyAppOpenCount), 2);
    });
  });
}
