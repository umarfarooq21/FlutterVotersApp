/// Response from GET `/captain/{captain_id}/detail` (staging API).
class CaptainDetailResponse {
  final String captainId;
  final String joinedAt;
  final String lastActiveAt;
  final String location;
  final String name;
  final CaptainDetailMetrics metrics;
  final CaptainDetailRank rank;
  final List<CaptainDetailActivityItem> recentActivity;

  CaptainDetailResponse({
    required this.captainId,
    required this.joinedAt,
    required this.lastActiveAt,
    required this.location,
    required this.name,
    required this.metrics,
    required this.rank,
    required this.recentActivity,
  });

  factory CaptainDetailResponse.fromJson(Map<String, dynamic> json) {
    return CaptainDetailResponse(
      captainId: json['captain_id']?.toString() ?? '',
      joinedAt: json['joined_at']?.toString() ?? '',
      lastActiveAt: json['last_active_at']?.toString() ?? '',
      location: json['location']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      metrics: CaptainDetailMetrics.fromJson(json['metrics']),
      rank: CaptainDetailRank.fromJson(json['rank']),
      recentActivity: _parseActivities(json['recent_activity']),
    );
  }

  static List<CaptainDetailActivityItem> _parseActivities(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => CaptainDetailActivityItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class CaptainDetailMetrics {
  final int agreedToVote;
  final int agreedToVotePct;
  final int asked;
  final int askedPct;
  final int contactsAdded;
  final int conversionRatePct;

  CaptainDetailMetrics({
    required this.agreedToVote,
    required this.agreedToVotePct,
    required this.asked,
    required this.askedPct,
    required this.contactsAdded,
    required this.conversionRatePct,
  });

  factory CaptainDetailMetrics.fromJson(dynamic raw) {
    if (raw is! Map) {
      return CaptainDetailMetrics(
        agreedToVote: 0,
        agreedToVotePct: 0,
        asked: 0,
        askedPct: 0,
        contactsAdded: 0,
        conversionRatePct: 0,
      );
    }
    final m = Map<String, dynamic>.from(raw);
    return CaptainDetailMetrics(
      agreedToVote: _asInt(m['agreed_to_vote']) ?? 0,
      agreedToVotePct: _asInt(m['agreed_to_vote_pct']) ?? 0,
      asked: _asInt(m['asked']) ?? 0,
      askedPct: _asInt(m['asked_pct']) ?? 0,
      contactsAdded: _asInt(m['contacts_added']) ?? 0,
      conversionRatePct: _asInt(m['conversion_rate_pct']) ?? 0,
    );
  }
}

class CaptainDetailRank {
  final int current;
  final int delta;
  final String label;
  final int ofTotal;
  final int weekAgo;

  CaptainDetailRank({
    required this.current,
    required this.delta,
    required this.label,
    required this.ofTotal,
    required this.weekAgo,
  });

  factory CaptainDetailRank.fromJson(dynamic raw) {
    if (raw is! Map) {
      return CaptainDetailRank(
        current: 0,
        delta: 0,
        label: '',
        ofTotal: 0,
        weekAgo: 0,
      );
    }
    final m = Map<String, dynamic>.from(raw);
    return CaptainDetailRank(
      current: _asInt(m['current']) ?? 0,
      delta: _asInt(m['delta']) ?? 0,
      label: m['label']?.toString() ?? '',
      ofTotal: _asInt(m['of_total']) ?? 0,
      weekAgo: _asInt(m['week_ago']) ?? 0,
    );
  }
}

class CaptainDetailActivityItem {
  final String at;
  final int count;
  final String label;
  final String type;

  CaptainDetailActivityItem({
    required this.at,
    required this.count,
    required this.label,
    required this.type,
  });

  factory CaptainDetailActivityItem.fromJson(Map<String, dynamic> json) {
    return CaptainDetailActivityItem(
      at: json['at']?.toString() ?? '',
      count: _asInt(json['count']) ?? 0,
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}
