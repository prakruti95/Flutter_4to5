import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _firstTimeKey = 'first_time';

  // Singleton instance
  static SharedPrefService? _instance;
  static SharedPreferences? _preferences;
  static late SharedPreferences _prefs;
  SharedPrefService._internal();

  static Future<SharedPrefService> getInstance() async {
    if (_instance == null) {
      _instance = SharedPrefService._internal();
      _preferences = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // User Login Status
  Future<bool> isUserLoggedIn() async {
    return _preferences?.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> setUserLoggedIn(bool value) async {
    await _preferences?.setBool(_isLoggedInKey, value);
  }

  // First Time App Open
  Future<bool> isFirstTime() async {
    return _preferences?.getBool(_firstTimeKey) ?? true;
  }

  Future<void> setFirstTime(bool value) async {
    await _preferences?.setBool(_firstTimeKey, value);
  }

  // User Data
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
  }) async {
    await _preferences?.setString(_userIdKey, userId);
    await _preferences?.setString(_userEmailKey, email);
    await _preferences?.setString(_userNameKey, name);
    await setUserLoggedIn(true);
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'userId': _preferences?.getString(_userIdKey),
      'email': _preferences?.getString(_userEmailKey),
      'name': _preferences?.getString(_userNameKey),
    };
  }

  Future<String?> getUserId() async {
    return _preferences?.getString(_userIdKey);
  }

  Future<String?> getUserEmail() async {
    return _preferences?.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    return _preferences?.getString(_userNameKey);
  }

  // Clear all data on logout
  Future<void> clearAllData() async {
    await _preferences?.clear();
  }

  // Logout user
  Future<void> logout() async {
    await setUserLoggedIn(false);
    await _preferences?.remove(_userIdKey);
    await _preferences?.remove(_userEmailKey);
    await _preferences?.remove(_userNameKey);
  }
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

}