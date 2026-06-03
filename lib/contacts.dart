import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/APIs/ResponseClasses/contacts_catwise_response.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:quiz_app/add_contacts.dart';
import 'package:quiz_app/APIs/api_service.dart';
import 'package:quiz_app/contact_details.dart';
import 'package:quiz_app/contact_name_format.dart';

/// Contacts list theme (match design mockup).
const Color _kContactsPrimaryBlue = Color(0xFF2563EB);
const Color _kContactsTitle = Color(0xFF0F172A);
const Color _kContactsSubtitle = Color(0xFF64748B);
const Color _kContactsSearchFill = Color(0xFFF3F4F6);
const Color _kContactsSearchIcon = Color(0xFF94A3B8);
const Color _kShimmerBase = Color(0xFFE5E7EB);
const Color _kShimmerHighlight = Color(0xFFF9FAFB);

class ContactSyncScreen extends StatefulWidget {
  const ContactSyncScreen({super.key});

  @override
  State<ContactSyncScreen> createState() => _ContactSyncScreenState();
}

enum ContactStatus { toContact, contacted, responded, followUp, noMatch }

enum ContactPriority { needsAttention, mediumPriority, likelyVoting }

class _UiContact {
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

  const _UiContact({
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

  factory _UiContact.fromApi(ApiContactItem a, ContactPriority priority) {
    return _UiContact(
      name: a.name.trim().isEmpty ? 'Unknown' : a.name.trim(),
      phone: a.phone.trim(),
      status: _statusFromApiItem(a),
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

ContactStatus _statusFromApiItem(ApiContactItem a) {
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

String _formatContactLocation(_UiContact c) {
  final parts = [
    c.address.trim(),
    c.city.trim(),
  ].where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '—';
  return parts.join(', ');
}

Color _priorityAvatarColor(ContactPriority p) {
  switch (p) {
    case ContactPriority.needsAttention:
      return const Color(0xFFD32F2F);
    case ContactPriority.mediumPriority:
      return const Color(0xFFF59E0B);
    case ContactPriority.likelyVoting:
      return const Color(0xFF10B981);
  }
}

class _ContactSyncScreenState extends State<ContactSyncScreen> {
  final _searchCtrl = TextEditingController();

  bool _isLoadingContacts = true;
  String? _loadError;
  List<_UiContact> _all = [];

  @override
  void initState() {
    super.initState();
    _loadContactsFromApi();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContactsFromApi() async {
    if (!mounted) return;
    setState(() {
      // Full-screen spinner only on first load (empty list); keep list visible on pull-to-refresh.
      if (_all.isEmpty) {
        _isLoadingContacts = true;
      }
      _loadError = null;
    });

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        if (!mounted) return;
        setState(() {
          _all = [];
          _isLoadingContacts = false;
          _loadError = 'Sign in to load your contacts.';
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _all = [];
          _isLoadingContacts = false;
          _loadError = 'Sign in to load your contacts.';
        });
        return;
      }

      final response = await ApiService.getContactsCatWise(
        userId: userId,
        token: token,
      );

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isLoadingContacts = false;
          _loadError = 'Could not load contacts. Pull to retry.';
        });
        return;
      }

      final ui = <_UiContact>[
        ...response.needsAttention.map(
          (e) => _UiContact.fromApi(e, ContactPriority.needsAttention),
        ),
        ...response.mediumPriority.map(
          (e) => _UiContact.fromApi(e, ContactPriority.mediumPriority),
        ),
        ...response.likelyVoting.map(
          (e) => _UiContact.fromApi(e, ContactPriority.likelyVoting),
        ),
      ];

      setState(() {
        _all = ui;
        _isLoadingContacts = false;
        _loadError = null;
      });
    } catch (e) {
      debugPrint('loadContactsFromApi: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingContacts = false;
        _loadError = 'Could not load contacts. Pull to retry.';
      });
    }
  }

  List<_UiContact> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasContacts = _filtered.isNotEmpty;

    final baseTheme = Theme.of(context);
    final contactsTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: contactsTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Contacts",
                            style: GoogleFonts.inter(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              height: 1.05,
                              color: _kContactsTitle,
                            ),
                          ),
                        ),
                        _PlusButton(
                          isLoading: false,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddContactsPage(),
                              ),
                            ).then((_) {
                              if (mounted) _loadContactsFromApi();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_isLoadingContacts && _all.isEmpty)
                      Shimmer.fromColors(
                        baseColor: _kShimmerBase,
                        highlightColor: _kShimmerHighlight,
                        period: const Duration(milliseconds: 1200),
                        child: Container(
                          height: 16,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      Text(
                        "${_all.length} contacts imported".toUpperCase(),
                        style: GoogleFonts.inter(
                          color: _kContactsSubtitle,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.4,
                        ),
                      ),
                    const SizedBox(height: 14),
                    _SearchField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, viewport) {
                    return RefreshIndicator(
                      onRefresh: _loadContactsFromApi,
                      color: _kContactsPrimaryBlue,
                      child: _isLoadingContacts && _all.isEmpty
                          ? _ContactsShimmerList(
                              viewportHeight: viewport.maxHeight,
                            )
                          : !hasContacts
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: viewport.maxHeight,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                      ),
                                      child: Text(
                                        _loadError ?? 'No contacts yet',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: _loadError != null
                                              ? const Color(0xFF6B7280)
                                              : Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final c = _filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ContactCard(
                                    contact: c,
                                    onTap: () =>
                                        _openContactDetails(context, c),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openContactDetails(BuildContext context, _UiContact c) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ContactDetailsPage(
          contactId: c.contactId,
          name: c.name,
          phone: c.phone,
          statusText: _statusText(c.status),
          isRegistered: c.isRegistered,
          initials: _initials(c.name),
          location: _formatContactLocation(c),
          relationship: c.relation,
        ),
      ),
    );
    if (mounted && deleted == true) {
      _loadContactsFromApi();
    }
  }
}

/// Approximate height of 8 skeleton cards + ListView top padding (keeps pull-to-refresh scrollable).
const double _kShimmerBlockEstimatedHeight = 700;

class _ContactsShimmerList extends StatelessWidget {
  final double viewportHeight;

  const _ContactsShimmerList({required this.viewportHeight});

  static const List<double> _titleWidths = [220, 160, 200, 176];

  @override
  Widget build(BuildContext context) {
    final tail = math.max(0.0, viewportHeight - _kShimmerBlockEstimatedHeight);

    return Shimmer.fromColors(
      baseColor: _kShimmerBase,
      highlightColor: _kShimmerHighlight,
      period: const Duration(milliseconds: 1200),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          for (var i = 0; i < 8; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContactCardSkeleton(
                titleWidth: _titleWidths[i % _titleWidths.length],
              ),
            ),
          ],
          SizedBox(height: tail),
        ],
      ),
    );
  }
}

class _ContactCardSkeleton extends StatelessWidget {
  final double titleWidth;

  const _ContactCardSkeleton({required this.titleWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: titleWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 28,
                  width: 132,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _PlusButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _kContactsPrimaryBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final iconBtnStyle = IconButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return Container(
      decoration: BoxDecoration(
        color: _kContactsSearchFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _kContactsTitle,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, color: _kContactsSearchIcon),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 48,
          ),
          suffixIcon: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                style: iconBtnStyle,
                onPressed: () {},
                icon: const Icon(Icons.swap_vert, color: _kContactsSearchIcon),
                iconSize: 22,
                tooltip: 'Sort',
              ),
              IconButton(
                style: iconBtnStyle,
                onPressed: () {},
                icon: const Icon(
                  Icons.filter_alt_outlined,
                  color: _kContactsSearchIcon,
                ),
                iconSize: 22,
                tooltip: 'Filter',
              ),
              const SizedBox(width: 6),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 88,
            minHeight: 48,
          ),
          hintText: "Search contacts...",
          hintStyle: GoogleFonts.inter(
            color: _kContactsSearchIcon,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final _UiContact contact;
  final VoidCallback onTap;

  const _ContactCard({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(contact.name);
    final avatarFill = _priorityAvatarColor(contact.priority);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarFill,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatContactDisplayName(contact.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kContactsTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(status: contact.status),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ContactStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF1E40AF);
    const bg = Color(0xFFEFF6FF);
    late final String text;
    late final IconData icon;

    switch (status) {
      case ContactStatus.toContact:
        text = "Ask to vote";
        icon = Icons.chat_bubble_outline;
        break;
      case ContactStatus.contacted:
        text = "Ballot nudge";
        icon = Icons.chat_bubble_outline;
        break;
      case ContactStatus.responded:
        text = "Record stance";
        icon = Icons.edit_outlined;
        break;
      case ContactStatus.followUp:
        text = "Follow up";
        icon = Icons.schedule_outlined;
        break;
      case ContactStatus.noMatch:
        text = "No match";
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final list = parts.toList();
  if (list.isEmpty) return "?";
  final first = list.first;
  final last = list.length > 1 ? list.last : "";
  final a = first.isNotEmpty ? first[0] : "?";
  final b = last.isNotEmpty ? last[0] : "";
  return (a + b).toUpperCase();
}

String _statusText(ContactStatus status) {
  switch (status) {
    case ContactStatus.toContact:
      return "Ask to vote";
    case ContactStatus.contacted:
      return "Ballot nudge";
    case ContactStatus.responded:
      return "Record stance";
    case ContactStatus.followUp:
      return "Follow up";
    case ContactStatus.noMatch:
      return "No match";
  }
}
