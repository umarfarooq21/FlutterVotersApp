import 'package:quiz_app/models/contacts_catwise_response.dart';

/// Response from staging `GET /getContacts` (JSON array of contact objects).
class GetContactsResponse {
  final List<ApiContactItem> contacts;

  const GetContactsResponse({required this.contacts});

  /// Handles a root-level JSON array (actual API shape) or wrapped lists.
  factory GetContactsResponse.fromDecoded(dynamic decoded) {
    if (decoded is List) {
      return GetContactsResponse(
        contacts: decoded
            .whereType<Map>()
            .map((e) => ApiContactItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in <String>[
        'contacts',
        'data',
        'Data',
        'Items',
        'items',
        'results',
      ]) {
        final raw = map[key];
        if (raw is List) {
          return GetContactsResponse(
            contacts: raw
                .whereType<Map>()
                .map(
                  (e) => ApiContactItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(),
          );
        }
      }
    }
    return GetContactsResponse(contacts: []);
  }
}
