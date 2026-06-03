/// Response from POST `/voterImpact`.
class VoterImpactResponse {
  final int confirmedVoters;
  final int contactsAdded;
  final int followUpsNeeded;
  final int goal;
  final int outreachSent;
  final String status;
  final String voterTurnoutProgress;

  VoterImpactResponse({
    required this.confirmedVoters,
    required this.contactsAdded,
    required this.followUpsNeeded,
    required this.goal,
    required this.outreachSent,
    required this.status,
    required this.voterTurnoutProgress,
  });

  factory VoterImpactResponse.fromJson(Map<String, dynamic> json) {
    return VoterImpactResponse(
      confirmedVoters: _asInt(json['confirmed_voters']) ?? 0,
      contactsAdded: _asInt(json['contacts_added']) ?? 0,
      followUpsNeeded: _asInt(json['follow_ups_needed']) ?? 0,
      goal: _asInt(json['goal']) ?? 0,
      outreachSent: _asInt(json['outreach_sent']) ?? 0,
      status: json['status']?.toString() ?? '',
      voterTurnoutProgress: json['voter_turnout_progress']?.toString() ?? '0%',
    );
  }

  /// Parses `voter_turnout_progress` like `"12.5%"`; falls back to confirmed/goal.
  double turnoutFraction() {
    final raw = voterTurnoutProgress.trim();
    if (raw.endsWith('%')) {
      final n =
          double.tryParse(raw.substring(0, raw.length - 1).trim());
      if (n != null) return (n / 100).clamp(0.0, 1.0);
    }
    if (goal > 0) {
      return (confirmedVoters / goal).clamp(0.0, 1.0);
    }
    return 0;
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}
