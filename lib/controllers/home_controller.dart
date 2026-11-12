import 'package:flutter/foundation.dart';
import 'package:quiz_app/controllers/auth_controller.dart';
import 'package:quiz_app/services/auth_storage.dart';

class HomeController extends ChangeNotifier {
  int currentIndex = 0;

  String displayName = 'User';
  String displayEmail = '';

  void setIndex(int index) {
    if (currentIndex == index) return;
    currentIndex = index;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final results = await Future.wait([
      AuthStorage.getName(),
      AuthStorage.getEmail(),
    ]);
    final storedName = results[0];
    final storedEmail = results[1];

    displayName = (storedName != null && storedName.trim().isNotEmpty)
        ? storedName.trim()
        : 'User';
    displayEmail = (storedEmail != null && storedEmail.trim().isNotEmpty)
        ? storedEmail.trim()
        : '';
    notifyListeners();
  }

  Future<void> logout(AuthController auth) async {
    await auth.logout();
    currentIndex = 0;
    displayName = 'User';
    displayEmail = '';
    notifyListeners();
  }
}
