import 'package:flutter/foundation.dart';
import 'package:quiz_app/models/ui_contact.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/services/auth_storage.dart';

class ContactsController extends ChangeNotifier {
  bool isLoadingContacts = true;
  String? loadError;
  List<UiContact> all = [];
  String searchQuery = '';

  List<UiContact> get filtered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q),
        )
        .toList();
  }

  void setSearchQuery(String value) {
    if (searchQuery == value) return;
    searchQuery = value;
    notifyListeners();
  }

  Future<void> loadContacts() async {
    if (all.isEmpty) {
      isLoadingContacts = true;
    }
    loadError = null;
    notifyListeners();

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        all = [];
        isLoadingContacts = false;
        loadError = 'Sign in to load your contacts.';
        notifyListeners();
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        all = [];
        isLoadingContacts = false;
        loadError = 'Sign in to load your contacts.';
        notifyListeners();
        return;
      }

      final response = await ApiService.getContactsCatWise(
        userId: userId,
        token: token,
      );

      if (response == null) {
        isLoadingContacts = false;
        loadError = 'Could not load contacts. Pull to retry.';
        notifyListeners();
        return;
      }

      all = <UiContact>[
        ...response.needsAttention.map(
          (e) => UiContact.fromApi(e, ContactPriority.needsAttention),
        ),
        ...response.mediumPriority.map(
          (e) => UiContact.fromApi(e, ContactPriority.mediumPriority),
        ),
        ...response.likelyVoting.map(
          (e) => UiContact.fromApi(e, ContactPriority.likelyVoting),
        ),
      ];
      isLoadingContacts = false;
      loadError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ContactsController.loadContacts: $e');
      isLoadingContacts = false;
      loadError = 'Could not load contacts. Pull to retry.';
      notifyListeners();
    }
  }
}
