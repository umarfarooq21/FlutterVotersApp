class LeaderboardResponse {
  final int committed;
  final int contacts;
  final int messaged;
  final String goal;
  final int goalProgress;
  final int year;
  final LeaderboardVotersProgress voters;
  final List<LeaderboardCaptainEntry> leaderboard;

  LeaderboardResponse({
    required this.committed,
    required this.contacts,
    required this.messaged,
    required this.goal,
    required this.goalProgress,
    required this.year,
    required this.voters,
    required this.leaderboard,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      committed: _asInt(json['committed']) ?? 0,
      contacts: _asInt(json['contacts']) ?? 0,
      messaged: _asInt(json['messaged']) ?? 0,
      goal: json['goal']?.toString() ?? '',
      goalProgress: _asInt(json['goal_progress']) ?? 0,
      year: _asInt(json['year']) ?? DateTime.now().year,
      voters: LeaderboardVotersProgress.fromJson(json['voters']),
      leaderboard: _parseLeaderboard(json['leaderboard']),
    );
  }

  static List<LeaderboardCaptainEntry> _parseLeaderboard(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (e) => LeaderboardCaptainEntry.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  double get gaugeFraction {
    const maxPoints = 7;
    return (goalProgress / maxPoints).clamp(0.0, 1.0);
  }

  double get votersCompleteFraction {
    final t = voters.total;
    if (t <= 0) return 0;
    return (voters.completed / t).clamp(0.0, 1.0);
  }
}

class LeaderboardVotersProgress {
  final int completed;
  final int total;

  LeaderboardVotersProgress({
    required this.completed,
    required this.total,
  });

  factory LeaderboardVotersProgress.fromJson(dynamic raw) {
    if (raw is! Map) {
      return LeaderboardVotersProgress(completed: 0, total: 0);
    }
    final m = Map<String, dynamic>.from(raw);
    return LeaderboardVotersProgress(
      completed: _asInt(m['completed']) ?? 0,
      total: _asInt(m['total']) ?? 0,
    );
  }
}

class LeaderboardCaptainEntry {
  /// Present on staging `leaderboard/mobile`; required for `/captain/{id}/detail`.
  final String captainId;
  final String captain;
  final String location;
  final int committed;
  final int points;
  final int rank;

  LeaderboardCaptainEntry({
    this.captainId = '',
    required this.captain,
    required this.location,
    required this.committed,
    required this.points,
    required this.rank,
  });

  factory LeaderboardCaptainEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardCaptainEntry(
      captainId: json['captain_id']?.toString().trim() ??
          json['captainId']?.toString().trim() ??
          '',
      captain: json['captain']?.toString().trim() ?? '',
      location: json['location']?.toString().trim() ?? '',
      committed: _asInt(json['committed']) ?? 0,
      points: _asInt(json['points']) ?? 0,
      rank: _asInt(json['rank']) ?? 0,
    );
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}
