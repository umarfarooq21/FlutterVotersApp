/// Response from GET `/plan777/mobile` (staging API).
class Plan777MobileResponse {
  final List<Plan777CityProgress> cityProgress;
  final String goal;
  /// Overall completion percentage (e.g. 4.3 for 4.3%).
  final double voterCompletionPercent;
  final Plan777VotersBucket voters;
  final int year;

  Plan777MobileResponse({
    required this.cityProgress,
    required this.goal,
    required this.voterCompletionPercent,
    required this.voters,
    required this.year,
  });

  factory Plan777MobileResponse.fromJson(Map<String, dynamic> json) {
    return Plan777MobileResponse(
      cityProgress: _parseCities(json['cityProgress']),
      goal: json['goal']?.toString() ?? '',
      voterCompletionPercent: _asDouble(json['voterCompletion']) ?? 0,
      voters: Plan777VotersBucket.fromJson(json['voters']),
      year: _asInt(json['year']) ?? DateTime.now().year,
    );
  }

  static List<Plan777CityProgress> _parseCities(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Plan777CityProgress.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  double get gaugeArcFraction {
    final t = voters.total;
    if (t <= 0) return 0;
    return (voters.completed / t).clamp(0.0, 1.0);
  }

  /// Tagline under screen title (compact “×” form).
  String get subtitleTagline {
    final g = goal.trim();
    if (g.isEmpty) return '7 points × 7 cities × 7 cycles';
    return g
        .replaceAll('+', '')
        .replaceAll(RegExp(r'\s+across\s+', caseSensitive: false), ' × ')
        .replaceAll(RegExp(r'\s+over\s+', caseSensitive: false), ' × ')
        .trim();
  }
}

class Plan777VotersBucket {
  final int completed;
  final int total;

  Plan777VotersBucket({required this.completed, required this.total});

  factory Plan777VotersBucket.fromJson(dynamic raw) {
    if (raw is! Map) return Plan777VotersBucket(completed: 0, total: 0);
    final m = Map<String, dynamic>.from(raw);
    return Plan777VotersBucket(
      completed: _asInt(m['completed']) ?? 0,
      total: _asInt(m['total']) ?? 0,
    );
  }
}

class Plan777CityProgress {
  final String city;
  final String cityVoterType;
  /// Display as city progress % (e.g. 3.5).
  final double percentageOfTotalVoters;
  final int totalVoters;
  final int voterCompletion;

  Plan777CityProgress({
    required this.city,
    required this.cityVoterType,
    required this.percentageOfTotalVoters,
    required this.totalVoters,
    required this.voterCompletion,
  });

  factory Plan777CityProgress.fromJson(Map<String, dynamic> json) {
    return Plan777CityProgress(
      city: json['city']?.toString().trim() ?? '',
      cityVoterType: json['cityVoterType']?.toString().trim() ?? '',
      percentageOfTotalVoters:
          _asDouble(json['percentageOfTotalVoters']) ?? 0,
      totalVoters: _asInt(json['totalVoters']) ?? 0,
      voterCompletion: _asInt(json['voterCompletion']) ?? 0,
    );
  }

  String get subtitleLabel {
    final t = cityVoterType.trim();
    final label =
        t.isEmpty ? '' : '${t[0].toUpperCase()}${t.length > 1 ? t.substring(1).toLowerCase() : ''}';
    final n = _fmtInt(totalVoters);
    return '$n ${label.isEmpty ? 'registered' : label} voters';
  }

  double get linearProgress =>
      totalVoters <= 0 ? 0.0 : (voterCompletion / totalVoters).clamp(0.0, 1.0);
}

String _fmtInt(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}
