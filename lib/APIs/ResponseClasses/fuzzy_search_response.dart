import 'package:quiz_app/contact_name_format.dart';

/// One voter-file match from staging `GET /fuzzySearchApp`.
class FuzzySearchMatch {
  final String stateVoterId;
  final String confidence;
  final String fullNames;
  final String regCity;
  final String fullAddress;
  final String voterStatus;
  final int? birthYear;
  final String phone;
  final bool alreadySavedForCaptain;
  final int? rowCount;

  const FuzzySearchMatch({
    required this.stateVoterId,
    required this.confidence,
    required this.fullNames,
    required this.regCity,
    required this.fullAddress,
    required this.voterStatus,
    this.birthYear,
    this.phone = '',
    this.alreadySavedForCaptain = false,
    this.rowCount,
  });

  factory FuzzySearchMatch.fromJson(Map<String, dynamic> json) {
    return FuzzySearchMatch(
      stateVoterId: json['statevoterid']?.toString() ?? '',
      confidence: json['confidence']?.toString().trim().toUpperCase() ?? '',
      fullNames: json['full_names']?.toString().trim() ?? '',
      regCity: json['regcity']?.toString().trim() ?? '',
      fullAddress: json['fulladdress']?.toString().trim() ?? '',
      voterStatus: json['voterstatus']?.toString().trim() ?? '',
      birthYear: _asInt(json['birthyear']),
      phone: json['phone']?.toString().trim() ?? '',
      alreadySavedForCaptain: json['already_saved_for_captain'] == true,
      rowCount: _asInt(json['row_count']),
    );
  }

  String get displayName => formatContactDisplayName(fullNames);

  String get displayLocation {
    final city = formatContactDisplayName(regCity);
    if (city.isEmpty || city == 'Unknown') return '—';
    return city;
  }

  String get displayAge {
    if (birthYear == null) return '—';
    return 'Age ${birthYear!}';
  }

  String get matchTag => confidence.isEmpty ? 'POSSIBLE' : confidence;

  static List<FuzzySearchMatch> listFromDecoded(dynamic decoded) {
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => FuzzySearchMatch.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.stateVoterId.isNotEmpty)
        .toList();
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
