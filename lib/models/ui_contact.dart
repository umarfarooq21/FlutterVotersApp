import 'package:quiz_app/models/contacts_catwise_response.dart';

enum ContactStatus { toContact, contacted, responded, followUp, noMatch }

enum ContactPriority { needsAttention, mediumPriority, likelyVoting }

class UiContact {
  final String name;
  final String phone;
  final ContactStatus status;
  final bool isRegistered;
  final ContactPriority priority;
  final int contactId;
  final int voterId;
  final String address;
  final String city;
  final String relation;

  const UiContact({
    required this.name,
    required this.phone,
    required this.status,
    required this.isRegistered,
    required this.priority,
    required this.contactId,
    required this.voterId,
    required this.address,
    required this.city,
    required this.relation,
  });

  factory UiContact.fromApi(ApiContactItem a, ContactPriority priority) {
    return UiContact(
      name: a.name.trim().isEmpty ? 'Unknown' : a.name.trim(),
      phone: a.phone.trim(),
      status: statusFromApiItem(a),
      isRegistered: a.voterStatus.toLowerCase().contains('registered'),
      priority: priority,
      contactId: a.contactId,
      voterId: a.voterId,
      address: a.address,
      city: a.city,
      relation: a.relation,
    );
  }
}

ContactStatus statusFromApiItem(ApiContactItem a) {
  final vr = a.voterResponse?.trim();
  if (vr != null && vr.isNotEmpty) {
    if (vr.toLowerCase() == 'leaning') {
      return ContactStatus.followUp;
    }
    return ContactStatus.responded;
  }
  if (a.outreachStatus == 1) {
    return ContactStatus.contacted;
  }
  return ContactStatus.toContact;
}

String formatContactLocation(UiContact c) {
  final parts = [
    c.address.trim(),
    c.city.trim(),
  ].where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '—';
  return parts.join(', ');
}
