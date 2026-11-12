import 'package:flutter/foundation.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/services/auth_storage.dart';

/// Derives a readable display name from an email address.
/// e.g. "shaheryar.khan@inabia.com" → "Shaheryar Khan"
String displayNameFromEmail(String email) {
  final local = email.split('@').first;
  return local
      .split(RegExp(r'[._\-+]'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');
}

class AuthController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      errorMessage = 'Please enter email & password';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      if (result == null) {
        errorMessage = 'Login failed';
        isLoading = false;
        notifyListeners();
        return false;
      }

      await AuthStorage.saveSession(
        accessToken: result.accessToken,
        userId: result.userId,
      );
      await AuthStorage.saveUserInfo(
        email: trimmedEmail,
        name: displayNameFromEmail(trimmedEmail),
      );

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('AuthController.login: $e\n$st');
      errorMessage = 'Login failed';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthStorage.clearSession();
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  Future<bool> hasSession() => AuthStorage.hasSession();
}
