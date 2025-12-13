import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

part 'locale_provider.g.dart';

/// Locale provider - manages app language
/// Defaults to English ('en'), supports Turkish ('tr')
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const String _keyLocale = 'app_locale';

  @override
  String build() {
    // Load saved locale on initialization
    _loadLocale();
    return 'en'; // Default to English
  }

  /// Load locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_keyLocale) ?? 'en';
      state = savedLocale;
    } catch (e) {
      // If error, default to English
      state = 'en';
    }
  }

  /// Set locale and save to SharedPreferences
  Future<void> setLocale(String locale) async {
    // Validate locale
    if (locale != 'en' && locale != 'tr') {
      locale = 'en'; // Default to English if invalid
    }

    state = locale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocale, locale);
    } catch (e) {
      // If save fails, continue with the locale change
      // The locale is already updated in state
    }
  }

  /// Get current locale
  String get currentLocale => state;
}

/// Provider for AppStrings based on current locale
@riverpod
AppStrings appStrings(AppStringsRef ref) {
  final locale = ref.watch(localeNotifierProvider);
  return AppStrings(locale);
}

