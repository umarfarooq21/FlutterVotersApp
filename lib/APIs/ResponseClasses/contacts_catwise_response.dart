class ContactsCatWiseResponse {
  final List<ApiContactItem> needsAttention;
  final List<ApiContactItem> mediumPriority;
  final List<ApiContactItem> likelyVoting;

  ContactsCatWiseResponse({
    required this.needsAttention,
    required this.mediumPriority,
    required this.likelyVoting,
  });

  factory ContactsCatWiseResponse.fromJson(Map<String, dynamic> json) {
    return ContactsCatWiseResponse(
      needsAttention: _parseList(json['needs_attention']),
      mediumPriority: _parseList(json['medium_priority']),
      likelyVoting: _parseList(json['likely_voting']),
    );
  }

  static List<ApiContactItem> _parseList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ApiContactItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class ApiContactItem {
  final String address;
  final String city;
  final int contactId;
  final String createdAt;
  final String? description;
  final dynamic messageStatus;
  final String name;
  final int? outreachStatus;
  final String phone;
  final String relation;
  final int relationId;
  final int voterId;
  final String? voterResponse;
  final String voterStatus;

  ApiContactItem({
    required this.address,
    required this.city,
    required this.contactId,
    required this.createdAt,
    this.description,
    this.messageStatus,
    required this.name,
    this.outreachStatus,
    required this.phone,
    required this.relation,
    required this.relationId,
    required this.voterId,
    this.voterResponse,
    required this.voterStatus,
  });

  factory ApiContactItem.fromJson(Map<String, dynamic> json) {
    return ApiContactItem(
      address: json['Address']?.toString() ?? '',
      city: json['City']?.toString() ?? '',
      contactId: _asInt(json['ContactId']) ?? 0,
      createdAt: json['CreatedAt']?.toString() ?? '',
      description: json['Description']?.toString(),
      messageStatus: json['MessageStatus'],
      name: json['Name']?.toString() ?? '',
      outreachStatus: _asInt(json['OutreachStatus']),
      phone: json['Phone']?.toString() ?? '',
      relation: json['Relation']?.toString() ?? '',
      relationId: _asInt(json['RelationId']) ?? 0,
      voterId: _asInt(json['VoterId']) ?? 0,
      voterResponse: json['VoterResponse']?.toString(),
      voterStatus: json['VoterStatus']?.toString() ?? '',
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
