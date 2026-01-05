import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola preferensi pengguna menggunakan SharedPreferences.
/// Saat ini digunakan untuk menyimpan dan mengambil nama pengguna.
class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  SharedPreferences? _prefs;

  PreferencesService._init();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Menyimpan nama pengguna
  Future<bool> saveUserName(String name) async {
    if (_prefs == null) {
      await init();
    }
    return await _prefs!.setString('user_name', name);
  }

  String? getUserName() {
    return _prefs?.getString('user_name');
  }

  // Clear all preferences
  Future<bool> clearAll() async {
    if (_prefs == null) {
      await init();
    }
    return await _prefs!.clear();
  }
}
