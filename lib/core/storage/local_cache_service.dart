import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before use in main()');
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCacheService(prefs);
});

/// Layanan penyimpanan cache lokal non-sensitif (Onboarding, Preferensi, dsb).
class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static const String keyHasSeenOnboarding = 'tk_has_seen_onboarding';
  static const String keyLastSelectedCategory = 'tk_last_category';

  bool get hasSeenOnboarding => _prefs.getBool(keyHasSeenOnboarding) ?? false;

  Future<bool> setHasSeenOnboarding(bool value) async {
    return await _prefs.setBool(keyHasSeenOnboarding, value);
  }

  String? get lastSelectedCategory => _prefs.getString(keyLastSelectedCategory);

  Future<bool> setLastSelectedCategory(String category) async {
    return await _prefs.setString(keyLastSelectedCategory, category);
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}

