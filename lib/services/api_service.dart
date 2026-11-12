import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quiz_app/models/contact_details_steps_response.dart';
import 'package:quiz_app/models/contacts_catwise_response.dart';
import 'package:quiz_app/models/get_contacts_response.dart';
import 'package:quiz_app/models/leaderboard_response.dart';
import 'package:quiz_app/models/login_response.dart';
import 'package:quiz_app/models/captain_detail_response.dart';
import 'package:quiz_app/models/plan777_mobile_response.dart';
import 'package:quiz_app/models/relations_list_response.dart';
import 'package:quiz_app/models/fuzzy_search_response.dart';
import 'package:quiz_app/models/voter_impact_response.dart';


class ApiService {

  static const String _loginHost = 'api.amacvoters.org';//Production
  static const String _stagHost = 'apistag.amacvoters.org';//Stagging

  /// GET `loginMFA` with same query shape as:
  /// `times`, `email`, `password`, `username` (username mirrors email in API usage).
  static Future<LoginResponse?> login({
    required String email,
    required String password,
    String? username,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _loginHost,
      path: '/loginMFA',
      queryParameters: {
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'email': email,
        'password': password,
        'username': username ?? email,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return LoginResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print('Login parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('Login failed HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Login error: $e\n$st');
      return null;
    }
  }

  /// GET `getContactsCatWise` — contacts grouped by category.
  static Future<ContactsCatWiseResponse?> getContactsCatWise({
    required String userId,
    required String token,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _loginHost,
      path: '/getContactsCatWise',
      queryParameters: {
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'captainId': userId,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ContactsCatWiseResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print('getContactsCatWise parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print(
          'getContactsCatWise HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getContactsCatWise error: $e\n$st');
      return null;
    }
  }

  /// GET `getContacts` on staging — flat list of contacts for the captain.
  ///
  /// Query matches web client: `captainId`, `userId`, `token`, `times`.
  /// Sends `Authorization: Bearer` and `X-User-Id` like other staging calls.
  static Future<GetContactsResponse?> getContacts({
    required String userId,
    required String token,
    String? captainId,
  }) async {
    final cap = (captainId != null && captainId.isNotEmpty) ? captainId : userId;
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/getContacts',
      queryParameters: {
        'captainId': cap,
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return GetContactsResponse.fromDecoded(decoded);
        } catch (e) {
          // ignore: avoid_print
          print('getContacts parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('getContacts HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getContacts error: $e\n$st');
      return null;
    }
  }

  /// GET `getContactDetailsStepsNew` on staging — contact outreach steps & history.
  static Future<ContactDetailsStepsResponse?> getContactDetailsStepsNew({
    required int contactId,
    required String userId,
    required String token,
    int stepVersion = 6,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/getContactDetailsStepsNew',
      queryParameters: {
        'contactId': contactId.toString(),
        'stepVersion': stepVersion.toString(),
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'token': token,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ContactDetailsStepsResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print(
            'getContactDetailsStepsNew parse error: $e body: ${response.body}',
          );
          return null;
        }
      } else {
        // ignore: avoid_print
        print(
          'getContactDetailsStepsNew HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getContactDetailsStepsNew error: $e\n$st');
      return null;
    }
  }

  /// GET `getRelations` on staging — relationship labels for the captain.
  ///
  /// Query: `captainId`, `userId`, `token`, `times`. Returns a JSON array of
  /// `{ "id", "relation_name" }`.
  static Future<List<RelationItem>?> getRelations({
    required String userId,
    required String token,
    String? captainId,
  }) async {
    final cap = (captainId != null && captainId.isNotEmpty) ? captainId : userId;
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/getRelations',
      queryParameters: {
        'captainId': cap,
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return RelationItem.listFromDecoded(decoded);
        } catch (e) {
          // ignore: avoid_print
          print('getRelations parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('getRelations HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getRelations error: $e\n$st');
      return null;
    }
  }

  /// POST `editContactRelation` on staging — update a contact's relationship.
  ///
  /// Body: `{"ContactId":…,"RelationId":…,"Desc":"…"}` (Desc is the relation label).
  static Future<bool> editContactRelation({
    required int contactId,
    required int relationId,
    required String userId,
    required String token,
    required String description,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/editContactRelation',
      queryParameters: {
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'token': token,
      },
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
        body: jsonEncode({
          'ContactId': contactId,
          'RelationId': relationId,
          'Desc': description,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
      // ignore: avoid_print
      print(
        'editContactRelation HTTP ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e, st) {
      // ignore: avoid_print
      print('editContactRelation error: $e\n$st');
      return false;
    }
  }

  /// POST `deleteContact` on staging — remove a contact.
  ///
  /// Body: `{"ContactId":…}`.
  static Future<bool> deleteContact({
    required int contactId,
    required String userId,
    required String token,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/deleteContact',
      queryParameters: {
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'token': token,
      },
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
        body: jsonEncode({'ContactId': contactId}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      // ignore: avoid_print
      print('deleteContact HTTP ${response.statusCode}: ${response.body}');
      return false;
    } catch (e, st) {
      // ignore: avoid_print
      print('deleteContact error: $e\n$st');
      return false;
    }
  }

  /// GET `leaderboard/mobile` — leaderboard data for mobile.
  static Future<LeaderboardResponse?> getLeaderboard({
    required String userId,
    required String token,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/leaderboard/mobile',
      queryParameters: {
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'CaptainId': userId,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return LeaderboardResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print('getLeaderboard parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print(
          'getLeaderboard HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getLeaderboard error: $e\n$st');
      return null;
    }
  }

  /// POST `voterImpact` — personal goal / turnout stats for the captain.
  static Future<VoterImpactResponse?> voterImpact({
    required String userId,
    required String token,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _loginHost,
      path: '/voterImpact',
      queryParameters: {
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'CaptainId': userId}),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return VoterImpactResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print('voterImpact parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('voterImpact HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('voterImpact error: $e\n$st');
      return null;
    }
  }

  /// GET `plan777/mobile` — 2026 community goal / city progress (staging host).
  static Future<Plan777MobileResponse?> getPlan777Mobile({
    required String userId,
    required String token,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _loginHost,
      path: '/plan777/mobile',
      queryParameters: {
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'CaptainId': userId,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return Plan777MobileResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print('getPlan777Mobile parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print(
          'getPlan777Mobile HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getPlan777Mobile error: $e\n$st');
      return null;
    }
  }

  /// GET `fuzzySearchApp` on staging — voter-file matches for a contact name.
  ///
  /// Query: `captainId`, `userId`, `token`, `times`, `full_names`.
  static Future<List<FuzzySearchMatch>?> fuzzySearchApp({
    required String userId,
    required String token,
    required String fullNames,
    String? captainId,
  }) async {
    final cap = (captainId != null && captainId.isNotEmpty) ? captainId : userId;
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/fuzzySearchApp',
      queryParameters: {
        'captainId': cap,
        'userId': userId,
        'token': token,
        'full_names': fullNames.trim(),
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return FuzzySearchMatch.listFromDecoded(decoded);
        } catch (e) {
          // ignore: avoid_print
          print('fuzzySearchApp parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('fuzzySearchApp HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('fuzzySearchApp error: $e\n$st');
      return null;
    }
  }

  /// POST `saveContactNew` on staging — save a matched voter as a contact.
  ///
  /// Body fields mirror the web client: `CaptainId`, `VoterId`, `RelationId`,
  /// `Desc`, `Phone`, `City`, `ContactType`, `Name`, `VoterStatus`, `Address`.
  /// Returns the server message on HTTP 201, or `null` on failure.
  static Future<String?> saveContactNew({
    required String userId,
    required String token,
    required String captainId,
    required String voterId,
    required int relationId,
    required String desc,
    required String name,
    required String city,
    required String address,
    required String voterStatus,
    String phone = '',
    String contactType = 'Phonebook',
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: '/saveContactNew',
      queryParameters: {
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'token': token,
      },
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
        body: jsonEncode({
          'CaptainId': captainId,
          'VoterId': voterId,
          'RelationId': relationId,
          'Desc': desc,
          'Phone': phone,
          'City': city,
          'ContactType': contactType,
          'Name': name,
          'VoterStatus': voterStatus,
          'Address': address,
        }),
      );

      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            return data['message']?.toString() ?? 'Contact saved';
          }
          return 'Contact saved';
        } catch (e) {
          // ignore: avoid_print
          print('saveContactNew parse error: $e body: ${response.body}');
          return 'Contact saved';
        }
      }
      // ignore: avoid_print
      print('saveContactNew HTTP ${response.statusCode}: ${response.body}');
      return null;
    } catch (e, st) {
      // ignore: avoid_print
      print('saveContactNew error: $e\n$st');
      return null;
    }
  }

  /// GET `captain/{captainId}/detail` — captain profile (staging host).
  static Future<CaptainDetailResponse?> getCaptainDetail({
    required String captainId,
    required String userId,
    required String token,
  }) async {
    final path = '/captain/${Uri.encodeComponent(captainId)}/detail';
    final uri = Uri(
      scheme: 'https',
      host: _stagHost,
      path: path,
      queryParameters: {
        'userId': userId,
        'token': token,
        'times': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return CaptainDetailResponse.fromJson(data);
        } catch (e) {
          // ignore: avoid_print
          print('getCaptainDetail parse error: $e body: ${response.body}');
          return null;
        }
      } else {
        // ignore: avoid_print
        print(
          'getCaptainDetail HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('getCaptainDetail error: $e\n$st');
      return null;
    }
  }
}
