import 'package:shared_preferences/shared_preferences.dart';

/// Keys for persisted login session (matches API field names for clarity).
class AuthStorage {
  AuthStorage._();

  static const String _keyAccessToken = 'access_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEmail = 'user_email';
  static const String _keyName = 'user_name';

  static Future<void> saveSession({
    required String accessToken,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyUserId, userId);
  }

  static Future<void> saveUserInfo({
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    final id = await getUserId();
    return (token != null && token.isNotEmpty) &&
        (id != null && id.isNotEmpty);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
  }
}
