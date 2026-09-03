import 'package:appwrite/appwrite.dart';
import 'appwrite.dart';
import 'kato_silent_user_service.dart';

/// Legacy/Convenience facade for silently logging user onboarding data in Appwrite.
/// Delegates directly to [KatoSilentUserService].
class AppwriteUserService {
  AppwriteUserService._();

  static const String databaseId = KatoSilentUserService.databaseId;
  static const String collectionId = KatoSilentUserService.collectionId;
  static const String prefKeyUserDocId = KatoSilentUserService.prefKeyUserDocId;

  /// Silently logs onboarding or updates last_active for the user in Appwrite.
  ///
  /// Executed completely in the background without blocking the UI flow.
  /// All network operations and potential exceptions are handled silently.
  static Future<void> logUserOnboarding([Databases? customDatabases]) async {
    await KatoSilentUserService.instance.registerKatoUserSilently(
      customDatabases ?? databases,
    );
  }
}

