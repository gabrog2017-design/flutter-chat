import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setToken(String token) async =>
      _prefs!.setString('token', token);

  static String? getToken() => _prefs!.getString('token');

  static Future<void> setUserId(String id) async =>
      _prefs!.setString('userId', id);

  static String? getUserId() => _prefs!.getString('userId');

  static Future<void> setUsername(String u) async =>
      _prefs!.setString('username', u);

  static String? getUsername() => _prefs!.getString('username');

  static Future<void> setAvatar(String u) async =>
      _prefs!.setString('avatar', u);

  static String? getAvatar() => _prefs!.getString('avatar');

  static Future<void> setLanguage(String l) async =>
      _prefs!.setString('language', l);

  static String? getLanguage() => _prefs!.getString('language');

  static Future<void> clear() async => _prefs!.clear();

  static bool isLoggedIn() => getToken() != null;
}
