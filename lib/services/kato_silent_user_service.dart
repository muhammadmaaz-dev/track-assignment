import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appwrite.dart';

/// Singleton service for completely silent, non-blocking user onboarding registration in Appwrite.
class KatoSilentUserService {
  // Singleton pattern
  KatoSilentUserService._internal();
  static final KatoSilentUserService _instance = KatoSilentUserService._internal();
  static KatoSilentUserService get instance => _instance;
  factory KatoSilentUserService() => _instance;

  static const String databaseId = appwriteDatabaseId;
  static const String collectionId = appwriteCollectionId;
  static const String prefKeyIsRegistered = 'is_kato_user_registered';
  static const String prefKeyUserDocId = 'kato_appwrite_user_doc_id';
  static const String _legacyKey1 = 'kato_user_doc_id';
  static const String _legacyKey2 = 'appwrite_user_doc_id';


  /// Silently registers a new user or updates `last_active` for an existing user.
  ///
  /// Completely non-blocking and safe to call in fire-and-forget mode.
  /// All network operations are wrapped in try-catch blocks to guarantee zero UI interruption.
  Future<void> registerKatoUserSilently([Databases? customDatabases]) async {
    final targetDatabases = customDatabases ?? databases;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve existing document ID across current and legacy preference keys
      String? existingDocId = prefs.getString(prefKeyUserDocId) ??
          prefs.getString(_legacyKey1) ??
          prefs.getString(_legacyKey2);

      final String nowUtcIso = DateTime.now().toUtc().toIso8601String();

      // --- CASE 1: User Already Registered Locally -> Update last_active ---
      if (existingDocId != null && existingDocId.trim().isNotEmpty) {
        existingDocId = existingDocId.trim();
        try {
          // ignore: deprecated_member_use
          await targetDatabases.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: existingDocId,
            data: {
              'last_active': nowUtcIso,
            },
          );

          if (kDebugMode) {
            debugPrint(
              'KatoSilentUserService: Successfully updated last_active for user $existingDocId',
            );
          }
          return;
        } on AppwriteException catch (e) {
          if (kDebugMode) {
            debugPrint(
              'KatoSilentUserService: updateDocument error [${e.code}]: ${e.message}',
            );
          }
          // If document was removed/not found on server (404), fall through to re-register
          if (e.code == 404) {
            await prefs.remove(prefKeyUserDocId);
            await prefs.remove(_legacyKey1);
            await prefs.remove(_legacyKey2);
            await prefs.remove(prefKeyIsRegistered);
          } else {
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('KatoSilentUserService: updateDocument error: $e');
          }
          return;
        }
      }

      // --- CASE 2: Not Registered -> Create New User Document ---
      // 1. Auto-generate sequential name ("user1", "user2") with fallback to "user_" + timestamp
      final String userName = await _generateUserName(targetDatabases);

      // 2. Auto-detect full country name (e.g. "Pakistan", "United States", NOT "PK", "US")
      final String fullCountryName = await detectFullCountryName();

      // 3. Create document in Appwrite collection
      // ignore: deprecated_member_use
      final document = await targetDatabases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'name': userName,
          'country': fullCountryName,
          'joining_date': nowUtcIso,
          'last_active': nowUtcIso,
        },
      );

      // 4. Persist registered document ID locally
      await prefs.setString(prefKeyUserDocId, document.$id);
      await prefs.setString(_legacyKey1, document.$id);
      await prefs.setBool(prefKeyIsRegistered, true);

      if (kDebugMode) {
        debugPrint(
          'KatoSilentUserService: Registered new user [ID: ${document.$id}, Name: $userName, Country: $fullCountryName]',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'KatoSilentUserService: Silent user registration error (safe to ignore offline): $e',
        );
      }
    }
  }

  /// Generates a sequential name like "user1", "user2", or unique "user_" + timestamp.
  Future<String> _generateUserName(Databases targetDatabases) async {
    final String fallbackTimestampName =
        'user_${DateTime.now().millisecondsSinceEpoch}';
    try {
      // Query collection count to determine sequential user number
      // ignore: deprecated_member_use
      final docsList = await targetDatabases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.limit(1)],
      );
      final int nextSequentialNumber = docsList.total + 1;
      return 'user$nextSequentialNumber';
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'KatoSilentUserService: Query total count failed ($e). Using unique fallback: $fallbackTimestampName',
        );
      }
      return fallbackTimestampName;
    }
  }

  /// Auto-detects user's FULL country name (e.g. "Pakistan", "United States").
  ///
  /// Never returns a 2-letter country code like "PK" or "US".
  /// Falls back to "Unknown" if unavailable.
  Future<String> detectFullCountryName() async {
    // 1. Try resolving full country name via system locale (fast, offline-safe, zero permissions)
    try {
      final code = _extractDeviceCountryCode();
      if (code != null && code.isNotEmpty) {
        final fullName = _countryCodeToFullName(code);
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KatoSilentUserService: Failed to resolve country from locale: $e');
      }
    }

    // 2. Secondary fallback: lightweight IP geolocation lookup with short 2s timeout
    if (!kIsWeb) {
      try {
        final httpClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 2);
        final request = await httpClient
            .getUrl(Uri.parse('https://ipapi.co/country_name/'))
            .timeout(const Duration(seconds: 2));
        final response =
            await request.close().timeout(const Duration(seconds: 2));

        if (response.statusCode == HttpStatus.ok) {
          final body = await response.transform(utf8.decoder).join();
          final trimmed = body.trim();
          if (trimmed.isNotEmpty &&
              !trimmed.contains('error') &&
              !trimmed.contains('{') &&
              trimmed.length > 2) {
            return trimmed;
          }
        }
      } catch (_) {
        // Silently ignore network timeouts/offline errors
      }
    }

    // 3. Fallback to Unknown as required
    return 'Unknown';
  }

  /// Extracts the 2-letter ISO country code from device settings/locale.
  String? _extractDeviceCountryCode() {
    try {
      // A. Primary locale
      final primaryLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (primaryLocale.countryCode != null &&
          primaryLocale.countryCode!.trim().isNotEmpty) {
        return primaryLocale.countryCode!.trim().toUpperCase();
      }

      // B. Preferred locales list
      final locales = WidgetsBinding.instance.platformDispatcher.locales;
      for (final loc in locales) {
        if (loc.countryCode != null && loc.countryCode!.trim().isNotEmpty) {
          return loc.countryCode!.trim().toUpperCase();
        }
      }

      // C. Platform localeName (e.g. "en_PK", "ur_PK", "en_US")
      if (!kIsWeb) {
        final localeName = Platform.localeName;
        if (localeName.contains('_') || localeName.contains('-')) {
          final parts = localeName.split(RegExp(r'[_-]'));
          for (final part in parts.reversed) {
            final trimmed = part.trim().toUpperCase();
            if (trimmed.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(trimmed)) {
              return trimmed;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KatoSilentUserService: Error reading device country code: $e');
      }
    }
    return null;
  }

  /// Maps an ISO 3166-1 alpha-2 country code to its FULL country name.
  /// Returns null if not found.
  String? _countryCodeToFullName(String code) {
    return _countryCodeToNameMap[code.toUpperCase()];
  }

  /// Comprehensive ISO 3166-1 alpha-2 country code to full country name lookup.
  static const Map<String, String> _countryCodeToNameMap = {
    'AD': 'Andorra',
    'AE': 'United Arab Emirates',
    'AF': 'Afghanistan',
    'AG': 'Antigua and Barbuda',
    'AI': 'Anguilla',
    'AL': 'Albania',
    'AM': 'Armenia',
    'AO': 'Angola',
    'AQ': 'Antarctica',
    'AR': 'Argentina',
    'AS': 'American Samoa',
    'AT': 'Austria',
    'AU': 'Australia',
    'AW': 'Aruba',
    'AX': 'Åland Islands',
    'AZ': 'Azerbaijan',
    'BA': 'Bosnia and Herzegovina',
    'BB': 'Barbados',
    'BD': 'Bangladesh',
    'BE': 'Belgium',
    'BF': 'Burkina Faso',
    'BG': 'Bulgaria',
    'BH': 'Bahrain',
    'BI': 'Burundi',
    'BJ': 'Benin',
    'BL': 'Saint Barthélemy',
    'BM': 'Bermuda',
    'BN': 'Brunei',
    'BO': 'Bolivia',
    'BQ': 'Caribbean Netherlands',
    'BR': 'Brazil',
    'BS': 'Bahamas',
    'BT': 'Bhutan',
    'BV': 'Bouvet Island',
    'BW': 'Botswana',
    'BY': 'Belarus',
    'BZ': 'Belize',
    'CA': 'Canada',
    'CC': 'Cocos (Keeling) Islands',
    'CD': 'Democratic Republic of the Congo',
    'CF': 'Central African Republic',
    'CG': 'Congo',
    'CH': 'Switzerland',
    'CI': 'Ivory Coast',
    'CK': 'Cook Islands',
    'CL': 'Chile',
    'CM': 'Cameroon',
    'CN': 'China',
    'CO': 'Colombia',
    'CR': 'Costa Rica',
    'CU': 'Cuba',
    'CV': 'Cape Verde',
    'CW': 'Curaçao',
    'CX': 'Christmas Island',
    'CY': 'Cyprus',
    'CZ': 'Czech Republic',
    'DE': 'Germany',
    'DJ': 'Djibouti',
    'DK': 'Denmark',
    'DM': 'Dominica',
    'DO': 'Dominican Republic',
    'DZ': 'Algeria',
    'EC': 'Ecuador',
    'EE': 'Estonia',
    'EG': 'Egypt',
    'EH': 'Western Sahara',
    'ER': 'Eritrea',
    'ES': 'Spain',
    'ET': 'Ethiopia',
    'FI': 'Finland',
    'FJ': 'Fiji',
    'FK': 'Falkland Islands',
    'FM': 'Micronesia',
    'FO': 'Faroe Islands',
    'FR': 'France',
    'GA': 'Gabon',
    'GB': 'United Kingdom',
    'GD': 'Grenada',
    'GE': 'Georgia',
    'GF': 'French Guiana',
    'GG': 'Guernsey',
    'GH': 'Ghana',
    'GI': 'Gibraltar',
    'GL': 'Greenland',
    'GM': 'Gambia',
    'GN': 'Guinea',
    'GP': 'Guadeloupe',
    'GQ': 'Equatorial Guinea',
    'GR': 'Greece',
    'GS': 'South Georgia',
    'GT': 'Guatemala',
    'GU': 'Guam',
    'GW': 'Guinea-Bissau',
    'GY': 'Guyana',
    'HK': 'Hong Kong',
    'HM': 'Heard Island and McDonald Islands',
    'HN': 'Honduras',
    'HR': 'Croatia',
    'HT': 'Haiti',
    'HU': 'Hungary',
    'ID': 'Indonesia',
    'IE': 'Ireland',
    'IL': 'Israel',
    'IM': 'Isle of Man',
    'IN': 'India',
    'IO': 'British Indian Ocean Territory',
    'IQ': 'Iraq',
    'IR': 'Iran',
    'IS': 'Iceland',
    'IT': 'Italy',
    'JE': 'Jersey',
    'JM': 'Jamaica',
    'JO': 'Jordan',
    'JP': 'Japan',
    'KE': 'Kenya',
    'KG': 'Kyrgyzstan',
    'KH': 'Cambodia',
    'KI': 'Kiribati',
    'KM': 'Comoros',
    'KN': 'Saint Kitts and Nevis',
    'KP': 'North Korea',
    'KR': 'South Korea',
    'KW': 'Kuwait',
    'KY': 'Cayman Islands',
    'KZ': 'Kazakhstan',
    'LA': 'Laos',
    'LB': 'Lebanon',
    'LC': 'Saint Lucia',
    'LI': 'Liechtenstein',
    'LK': 'Sri Lanka',
    'LR': 'Liberia',
    'LS': 'Lesotho',
    'LT': 'Lithuania',
    'LU': 'Luxembourg',
    'LV': 'Latvia',
    'LY': 'Libya',
    'MA': 'Morocco',
    'MC': 'Monaco',
    'MD': 'Moldova',
    'ME': 'Montenegro',
    'MF': 'Saint Martin',
    'MG': 'Madagascar',
    'MH': 'Marshall Islands',
    'MK': 'North Macedonia',
    'ML': 'Mali',
    'MM': 'Myanmar',
    'MN': 'Mongolia',
    'MO': 'Macau',
    'MP': 'Northern Mariana Islands',
    'MQ': 'Martinique',
    'MR': 'Mauritania',
    'MS': 'Montserrat',
    'MT': 'Malta',
    'MU': 'Mauritius',
    'MV': 'Maldives',
    'MW': 'Malawi',
    'MX': 'Mexico',
    'MY': 'Malaysia',
    'MZ': 'Mozambique',
    'NA': 'Namibia',
    'NC': 'New Caledonia',
    'NE': 'Niger',
    'NF': 'Norfolk Island',
    'NG': 'Nigeria',
    'NI': 'Nicaragua',
    'NL': 'Netherlands',
    'NO': 'Norway',
    'NP': 'Nepal',
    'NR': 'Nauru',
    'NU': 'Niue',
    'NZ': 'New Zealand',
    'OM': 'Oman',
    'PA': 'Panama',
    'PE': 'Peru',
    'PF': 'French Polynesia',
    'PG': 'Papua New Guinea',
    'PH': 'Philippines',
    'PK': 'Pakistan',
    'PL': 'Poland',
    'PM': 'Saint Pierre and Miquelon',
    'PN': 'Pitcairn Islands',
    'PR': 'Puerto Rico',
    'PS': 'Palestine',
    'PT': 'Portugal',
    'PW': 'Palau',
    'PY': 'Paraguay',
    'QA': 'Qatar',
    'RE': 'Réunion',
    'RO': 'Romania',
    'RS': 'Serbia',
    'RU': 'Russia',
    'RW': 'Rwanda',
    'SA': 'Saudi Arabia',
    'SB': 'Solomon Islands',
    'SC': 'Seychelles',
    'SD': 'Sudan',
    'SE': 'Sweden',
    'SG': 'Singapore',
    'SH': 'Saint Helena',
    'SI': 'Slovenia',
    'SJ': 'Svalbard and Jan Mayen',
    'SK': 'Slovakia',
    'SL': 'Sierra Leone',
    'SM': 'San Marino',
    'SN': 'Senegal',
    'SO': 'Somalia',
    'SR': 'Suriname',
    'SS': 'South Sudan',
    'ST': 'São Tomé and Príncipe',
    'SV': 'El Salvador',
    'SX': 'Sint Maarten',
    'SY': 'Syria',
    'SZ': 'Eswatini',
    'TC': 'Turks and Caicos Islands',
    'TD': 'Chad',
    'TF': 'French Southern Territories',
    'TG': 'Togo',
    'TH': 'Thailand',
    'TJ': 'Tajikistan',
    'TK': 'Tokelau',
    'TL': 'Timor-Leste',
    'TM': 'Turkmenistan',
    'TN': 'Tunisia',
    'TO': 'Tonga',
    'TR': 'Turkey',
    'TT': 'Trinidad and Tobago',
    'TV': 'Tuvalu',
    'TW': 'Taiwan',
    'TZ': 'Tanzania',
    'UA': 'Ukraine',
    'UG': 'Uganda',
    'UM': 'United States Minor Outlying Islands',
    'US': 'United States',
    'UY': 'Uruguay',
    'UZ': 'Uzbekistan',
    'VA': 'Vatican City',
    'VC': 'Saint Vincent and the Grenadines',
    'VE': 'Venezuela',
    'VG': 'British Virgin Islands',
    'VI': 'United States Virgin Islands',
    'VN': 'Vietnam',
    'VU': 'Vanuatu',
    'WF': 'Wallis and Futuna',
    'WS': 'Samoa',
    'XK': 'Kosovo',
    'YE': 'Yemen',
    'YT': 'Mayotte',
    'ZA': 'South Africa',
    'ZM': 'Zambia',
    'ZW': 'Zimbabwe',
  };
}
