import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment_tracker/services/kato_silent_user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KatoSilentUserService Unit Tests', () {
    test('Country detection returns full country name and never 2-letter codes', () async {
      final service = KatoSilentUserService.instance;
      final country = await service.detectFullCountryName();

      // Country must not be empty
      expect(country.isNotEmpty, isTrue);

      // Must not be a 2-letter country code
      expect(country.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(country), isFalse);

      // Verify known mapping integrity
      expect(KatoSilentUserService.databaseId, 'main');
      expect(KatoSilentUserService.collectionId, 'kato_user_info');
    });

    test('SharedPreferences mock stores and detects user registration keys', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(KatoSilentUserService.prefKeyUserDocId), isNull);

      await prefs.setString(KatoSilentUserService.prefKeyUserDocId, 'doc_test_123');
      expect(prefs.getString(KatoSilentUserService.prefKeyUserDocId), 'doc_test_123');
    });
  });
}
