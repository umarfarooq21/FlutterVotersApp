/// Response from staging `GET /getContactDetailsStepsNew`.
class ContactDetailsStepsResponse {
  final String address1;
  final String address2;
  final String city;
  final String originalPhone;
  final String originalPhoneName;
  final String registrationStatus;
  final VoteLikelihood? voteLikelihood;
  final List<CurrentElection> currentElections;
  final List<UpcomingElection> upcomingElections;
  final List<PastElectionItem> pastElections;
  final List<VotingHistoryYear> votingHistory;
  final int voterId;

  const ContactDetailsStepsResponse({
    required this.address1,
    required this.address2,
    required this.city,
    required this.originalPhone,
    required this.originalPhoneName,
    required this.registrationStatus,
    this.voteLikelihood,
    required this.currentElections,
    required this.upcomingElections,
    required this.pastElections,
    required this.votingHistory,
    required this.voterId,
  });

  static int? parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory ContactDetailsStepsResponse.fromJson(Map<String, dynamic> json) {
    return ContactDetailsStepsResponse(
      address1: json['address1']?.toString() ?? '',
      address2: json['address2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      originalPhone: json['OriginalPhone']?.toString() ?? '',
      originalPhoneName: json['OriginalPhoneName']?.toString() ?? '',
      registrationStatus: json['status']?.toString() ?? '',
      voteLikelihood: json['vote_likelihood'] is Map<String, dynamic>
          ? VoteLikelihood.fromJson(
              Map<String, dynamic>.from(json['vote_likelihood'] as Map),
            )
          : null,
      currentElections: _parseCurrent(json['current_elections']),
      upcomingElections: _parseUpcoming(json['upcoming_elections']),
      pastElections: _parsePast(json['past_elections']),
      votingHistory: _parseVotingHistory(json['voting_history']),
      voterId: ContactDetailsStepsResponse.parseInt(json['voter_id']) ?? 0,
    );
  }

  String get formattedAddress {
    final a1 = address1.trim();
    final a2 = address2.trim();
    if (a1.isEmpty && a2.isEmpty) return city.trim();
    if (a1.isEmpty) return a2;
    if (a2.isEmpty) return a1;
    return '$a1, $a2';
  }

  static List<CurrentElection> _parseCurrent(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => CurrentElection.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<UpcomingElection> _parseUpcoming(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => UpcomingElection.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<PastElectionItem> _parsePast(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => PastElectionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<VotingHistoryYear> _parseVotingHistory(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => VotingHistoryYear.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.year.compareTo(a.year));
  }

}

class VoteLikelihood {
  final String color;
  final String percentage;

  const VoteLikelihood({required this.color, required this.percentage});

  factory VoteLikelihood.fromJson(Map<String, dynamic> json) {
    return VoteLikelihood(
      color: json['color']?.toString() ?? 'grey',
      percentage: json['percentage']?.toString() ?? '0%',
    );
  }

  /// 0.0–1.0 for arc / slider; falls back to 0 if unparsable.
  double get fraction {
    final p = percentage.replaceAll('%', '').trim();
    final n = double.tryParse(p);
    if (n == null) return 0;
    return (n / 100).clamp(0.0, 1.0);
  }
}

class CurrentElection {
  final int electionId;
  final String electionName;
  final String status;
  final String? notes;
  final List<ContactStepGroup> step1;
  final List<ContactStepGroup> step2;
  final List<ContactStepGroup> step3;
  final List<ContactStepGroup> step4;
  final List<ContactStepGroup> step5;
  final List<ContactStepGroup> step6;

  const CurrentElection({
    required this.electionId,
    required this.electionName,
    required this.status,
    this.notes,
    required this.step1,
    required this.step2,
    required this.step3,
    required this.step4,
    required this.step5,
    required this.step6,
  });

  factory CurrentElection.fromJson(Map<String, dynamic> json) {
    return CurrentElection(
      electionId: ContactDetailsStepsResponse.parseInt(json['election_Id']) ?? 0,
      electionName: json['election_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      notes: json['Notes']?.toString(),
      step1: _parseStepList(json['step1']),
      step2: _parseStepList(json['step2']),
      step3: _parseStepList(json['step3']),
      step4: _parseStepList(json['step4']),
      step5: _parseStepList(json['step5']),
      step6: _parseStepList(json['step6']),
    );
  }

  static List<ContactStepGroup> _parseStepList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ContactStepGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  ContactStepGroup? firstOfStep(int n) {
    final list = switch (n) {
      1 => step1,
      2 => step2,
      3 => step3,
      4 => step4,
      5 => step5,
      6 => step6,
      _ => <ContactStepGroup>[],
    };
    return list.isEmpty ? null : list.first;
  }
}

class UpcomingElection {
  final int electionId;
  final String electionName;
  final String status;

  const UpcomingElection({
    required this.electionId,
    required this.electionName,
    required this.status,
  });

  factory UpcomingElection.fromJson(Map<String, dynamic> json) {
    return UpcomingElection(
      electionId: ContactDetailsStepsResponse.parseInt(json['election_Id']) ?? 0,
      electionName: json['election_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class PastElectionItem {
  final int electionId;
  final String electionName;
  final String status;
  final String contactedOn;
  final String archivedNotes;

  const PastElectionItem({
    required this.electionId,
    required this.electionName,
    required this.status,
    required this.contactedOn,
    required this.archivedNotes,
  });

  factory PastElectionItem.fromJson(Map<String, dynamic> json) {
    final outreach = json['outreach'];
    String contacted = '';
    if (outreach is Map) {
      contacted = outreach['date']?.toString() ?? '';
    }
    return PastElectionItem(
      electionId: ContactDetailsStepsResponse.parseInt(json['election_Id']) ?? 0,
      electionName: json['election_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      contactedOn: contacted,
      archivedNotes: json['archived_notes']?.toString() ?? '',
    );
  }
}

class ContactStepGroup {
  final String key;
  final int? status;
  final String title;
  final String subtitle;
  final List<StepOption> steps;

  const ContactStepGroup({
    required this.key,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  factory ContactStepGroup.fromJson(Map<String, dynamic> json) {
    return ContactStepGroup(
      key: json['key']?.toString() ?? '',
      status: ContactDetailsStepsResponse.parseInt(json['status']),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      steps: _parseSteps(json['steps']),
    );
  }

  static List<StepOption> _parseSteps(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => StepOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class StepOption {
  final String label;
  final int status;

  const StepOption({required this.label, required this.status});

  factory StepOption.fromJson(Map<String, dynamic> json) {
    return StepOption(
      label: json['label']?.toString() ?? '',
      status: ContactDetailsStepsResponse.parseInt(json['status']) ?? 0,
    );
  }
}

class VotingHistoryYear {
  final int year;
  final ElectionSlot? primary;
  final ElectionSlot? general;
  final dynamic specialRaw;

  const VotingHistoryYear({
    required this.year,
    this.primary,
    this.general,
    this.specialRaw,
  });

  factory VotingHistoryYear.fromJson(Map<String, dynamic> json) {
    return VotingHistoryYear(
      year: ContactDetailsStepsResponse.parseInt(json['year']) ?? 0,
      primary: json['primary'] is Map<String, dynamic>
          ? ElectionSlot.fromJson(json['primary'] as Map<String, dynamic>)
          : null,
      general: json['general'] is Map<String, dynamic>
          ? ElectionSlot.fromJson(json['general'] as Map<String, dynamic>)
          : null,
      specialRaw: json['special'],
    );
  }
}

class ElectionSlot {
  final String election;
  final String status;

  const ElectionSlot({required this.election, required this.status});

  factory ElectionSlot.fromJson(Map<String, dynamic> json) {
    return ElectionSlot(
      election: json['election']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
