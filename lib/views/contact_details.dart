import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/models/contact_details_steps_response.dart';
import 'package:quiz_app/models/relations_list_response.dart';
import 'package:quiz_app/services/auth_storage.dart';
import 'package:quiz_app/views/message_template.dart';
import 'package:shimmer/shimmer.dart';

class ContactDetailsPage extends StatefulWidget {
  final int contactId;
  final int stepVersion;
  final String name;
  final String phone;
  final String statusText;
  final bool isRegistered;
  final String initials;
  final String location;
  final String relationship;
  /// Shown under phone when non-empty (e.g. from enriched contact data).
  final String email;

  const ContactDetailsPage({
    super.key,
    required this.contactId,
    this.stepVersion = 6,
    required this.name,
    required this.phone,
    required this.statusText,
    required this.isRegistered,
    required this.initials,
    this.location = "Dearborn, MI",
    this.relationship = "Friend",
    this.email = '',
  });

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  /// Used until `getRelations` succeeds (or if the call fails).
  static const List<String> _kFallbackRelationNames = [
    "Friend",
    "Spouse",
    "Parent",
    "Sibling",
    "Cousin",
    "Relative",
    "Roommate",
  ];

  late List<RelationItem> _relationChoices;
  late String _selectedRelationship;
  bool _loading = true;
  ContactDetailsStepsResponse? _details;
  String? _loadError;
  bool _relationUpdateInFlight = false;

  static List<RelationItem> _fallbackRelationItems() {
    return [
      for (var i = 0; i < _kFallbackRelationNames.length; i++)
        RelationItem(id: -(i + 1), relationName: _kFallbackRelationNames[i]),
    ];
  }

  @override
  void initState() {
    super.initState();
    _relationChoices = _fallbackRelationItems();
    final rel = widget.relationship.trim();
    _selectedRelationship = _relationChoices.any((e) => e.relationName == rel)
        ? rel
        : _relationChoices.first.relationName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
      _loadRelations();
    });
  }

  Future<void> _loadRelations() async {
    final userId = await AuthStorage.getUserId();
    final token = await AuthStorage.getAccessToken();
    if (!mounted) return;
    if (userId == null ||
        token == null ||
        userId.isEmpty ||
        token.isEmpty) {
      return;
    }
    final list = await ApiService.getRelations(userId: userId, token: token);
    if (!mounted || list == null || list.isEmpty) return;
    list.sort((a, b) => a.id.compareTo(b.id));
    setState(() {
      _relationChoices = list;
      if (!_relationChoices.any((e) => e.relationName == _selectedRelationship)) {
        final w = widget.relationship.trim();
        if (_relationChoices.any((e) => e.relationName == w)) {
          _selectedRelationship = w;
        } else {
          _selectedRelationship = _relationChoices.first.relationName;
        }
      }
    });
  }

  Future<void> _onRelationPicked(RelationItem choice) async {
    if (choice.relationName == _selectedRelationship) return;

    final prev = _selectedRelationship;
    setState(() => _selectedRelationship = choice.relationName);

    if (widget.contactId <= 0 || choice.id <= 0) {
      if (mounted && choice.id <= 0 && widget.contactId > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Relationships are still loading. Try again in a moment.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        );
        setState(() => _selectedRelationship = prev);
      }
      return;
    }

    final userId = await AuthStorage.getUserId();
    final token = await AuthStorage.getAccessToken();
    if (!mounted) return;
    if (userId == null ||
        token == null ||
        userId.isEmpty ||
        token.isEmpty) {
      setState(() => _selectedRelationship = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign in to update the relationship.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _relationUpdateInFlight = true);
    final ok = await ApiService.editContactRelation(
      contactId: widget.contactId,
      relationId: choice.id,
      userId: userId,
      token: token,
      description: choice.relationName,
    );
    if (!mounted) return;
    setState(() => _relationUpdateInFlight = false);

    if (!ok) {
      setState(() => _selectedRelationship = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update relationship.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Relationship updated.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _onOverflowMenuSelected(String value) async {
    if (value == 'Delete contact') {
      await _confirmAndDeleteContact();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> _confirmAndDeleteContact() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete contact?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will remove ${widget.name} from your contacts. This cannot be undone.',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (widget.contactId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete: missing contact id.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    final userId = await AuthStorage.getUserId();
    final token = await AuthStorage.getAccessToken();
    if (!mounted) return;
    if (userId == null ||
        token == null ||
        userId.isEmpty ||
        token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign in to delete this contact.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    final ok = await ApiService.deleteContact(
      contactId: widget.contactId,
      userId: userId,
      token: token,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete contact.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _loadDetails() async {
    if (widget.contactId <= 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final userId = await AuthStorage.getUserId();
    final token = await AuthStorage.getAccessToken();
    if (!mounted) return;
    if (userId == null ||
        token == null ||
        userId.isEmpty ||
        token.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = 'Sign in to load contact details.';
      });
      return;
    }
    final res = await ApiService.getContactDetailsStepsNew(
      contactId: widget.contactId,
      userId: userId,
      token: token,
      stepVersion: widget.stepVersion,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _details = res;
      if (res == null) {
        _loadError = 'Could not load contact details.';
      } else {
        _loadError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        widget.name.trim().split(RegExp(r"\s+")).firstOrNull ??
        widget.name.trim();
    final d = _details;
    final voteFraction = d?.voteLikelihood?.fraction ?? 0.35;
    final pctLabel = d?.voteLikelihood?.percentage ??
        '${(voteFraction * 100).round()}%';
    final voteArcColor = _voteLikelihoodArcColor(d?.voteLikelihood?.color);
    final pctTextColor = voteArcColor;

    final displayAddress = (d != null && d.formattedAddress.trim().isNotEmpty)
        ? d.formattedAddress
        : widget.location;
    final displayPhone = (d != null && d.originalPhone.trim().isNotEmpty)
        ? d.originalPhone
        : (widget.phone.isNotEmpty ? widget.phone : "(425) 555-0654");
    final displayEmail = widget.email.trim();

    final baseTheme = Theme.of(context);
    final detailsTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    void openMessages() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MessageTemplatePage(recipientName: widget.name),
        ),
      );
    }

    final electionColumn = _buildElectionColumn(firstName, d);
    final pastBlocks = _buildPastElectionTiles(d);

    return Theme(
      data: detailsTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black,
          ),
          title: Text(
            widget.name,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            _PrimaryCircleIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: openMessages,
            ),
            const SizedBox(width: 8),
            _GreyCircleIconButton(icon: Icons.phone_outlined, onPressed: () {}),
            const SizedBox(width: 8),
            _GreyOverflowMenu(
              onSelected: _onOverflowMenuSelected,
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _loading
              ? const _ContactDetailsShimmer()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    if (_loadError != null) ...[
                      Material(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _loadError!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  setState(() {
                                    _loading = true;
                                    _loadError = null;
                                  });
                                  await _loadDetails();
                                },
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ContactInfoRow(
                                  icon: Icons.location_on_outlined,
                                  text: displayAddress,
                                ),
                                const SizedBox(height: 8),
                                _ContactInfoRow(
                                  icon: Icons.phone_outlined,
                                  text: displayPhone,
                                ),
                                if (displayEmail.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _ContactInfoRow(
                                    icon: Icons.email_outlined,
                                    text: displayEmail,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Vote likelihood",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _SemicircularProgress(
                                value: voteFraction,
                                progressColor: voteArcColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pctLabel,
                                style: GoogleFonts.inter(
                                  color: pctTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                        _RelationshipDropdown(
                          selected: _selectedRelationship,
                          relations: _relationChoices,
                          busy: _relationUpdateInFlight,
                          onSelected: _onRelationPicked,
                        ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      text: "Message $firstName",
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: openMessages,
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle("CURRENT ELECTIONS"),
                    const SizedBox(height: 10),
                    electionColumn,
                    const SizedBox(height: 22),
                    const _SectionTitle("VOTING HISTORY"),
                    const SizedBox(height: 10),
                    _CardContainer(
                      child: _VotingHistoryTable(apiRows: d?.votingHistory),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle("PAST ELECTIONS"),
                    const SizedBox(height: 10),
                    ...pastBlocks,
                  ],
                ),
        ),
      ),
    );
  }

  Color _voteLikelihoodArcColor(String? apiColor) {
    final c = (apiColor ?? '').toLowerCase();
    if (c.contains('green')) return const Color(0xFF22C55E);
    if (c.contains('yellow') || c.contains('amber')) {
      return const Color(0xFFEAB308);
    }
    return const Color(0xFFDC2626);
  }

  Widget _buildElectionColumn(String firstName, ContactDetailsStepsResponse? d) {
    if (d != null &&
        (d.currentElections.isNotEmpty || d.upcomingElections.isNotEmpty)) {
      final rows = <Widget>[];
      for (var i = 0; i < d.currentElections.length; i++) {
        final e = d.currentElections[i];
        if (i > 0) {
          rows.add(const Divider(height: 1, thickness: 1));
        }
        rows.add(
          _ElectionCollapsibleCard(
            title: e.electionName,
            pillLabel: e.status.toUpperCase(),
            initiallyExpanded: i == 0,
            expandedChild: _ApiElectionStepsBody(
              election: e,
              firstName: firstName,
            ),
          ),
        );
      }
      for (var j = 0; j < d.upcomingElections.length; j++) {
        final u = d.upcomingElections[j];
        rows.add(const Divider(height: 1, thickness: 1));
        rows.add(
          _ElectionCollapsibleCard(
            title: u.electionName,
            pillLabel: u.status.toUpperCase(),
          ),
        );
      }
      return _CardContainer(child: Column(children: rows));
    }
    return _CardContainer(
      child: Column(
        children: [
          _ElectionCollapsibleCard(
            title: "April 2026 Special Election",
            pillLabel: 'ACTIVE',
            initiallyExpanded: true,
            expandedChild: _AprilElectionOutreachBody(firstName: firstName),
          ),
          const Divider(height: 1, thickness: 1),
          const _ElectionCollapsibleCard(
            title: "Aug 2026 Primary",
            pillLabel: 'ACTIVE',
          ),
          const Divider(height: 1, thickness: 1),
          const _ElectionCollapsibleCard(
            title: "Nov 2026 General Election",
            pillLabel: 'ACTIVE',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPastElectionTiles(ContactDetailsStepsResponse? d) {
    if (d != null && d.pastElections.isNotEmpty) {
      final out = <Widget>[];
      for (var i = 0; i < d.pastElections.length; i++) {
        final p = d.pastElections[i];
        if (i > 0) out.add(const SizedBox(height: 10));
        final contacted = p.contactedOn.trim();
        final subtitle = contacted.isEmpty
            ? 'No contact date on file'
            : 'Contacted on $contacted';
        out.add(
          _PastElectionTile(
            title: p.electionName,
            subtitle: subtitle,
            onTap: () {},
          ),
        );
      }
      return out;
    }
    return [
      _PastElectionTile(
        title: "Aug 2025 Primary",
        subtitle: "Contacted on Aug 4, 2025",
        onTap: () {},
      ),
      const SizedBox(height: 10),
      _PastElectionTile(
        title: "Nov 2024 General",
        subtitle: "Contacted on Oct 28, 2024",
        onTap: () {},
      ),
    ];
  }
}

/// Shimmer placeholder while contact details API loads.
class _ContactDetailsShimmer extends StatelessWidget {
  const _ContactDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      period: const Duration(milliseconds: 1300),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 14,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 14,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6B7280), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryCircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2563EB),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _GreyCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GreyCircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF374151), size: 20),
        ),
      ),
    );
  }
}

class _GreyOverflowMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _GreyOverflowMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: "Edit relationship",
          child: _MenuRow(icon: Icons.edit_outlined, text: "Edit relationship"),
        ),
        PopupMenuItem(
          value: "Manage connections",
          child: _MenuRow(
            icon: Icons.people_outline,
            text: "Manage connections",
          ),
        ),
        PopupMenuItem(
          value: "View household (1)",
          child: _MenuRow(
            icon: Icons.home_outlined,
            text: "View household (1)",
          ),
        ),
        PopupMenuItem(
          value: "Change voter match",
          child: _MenuRow(icon: Icons.how_to_reg, text: "Change voter match"),
        ),
        PopupMenuItem(
          value: "Unlink match",
          child: _MenuRow(icon: Icons.link_off_outlined, text: "Unlink match"),
        ),
        PopupMenuItem(
          value: "Delete contact",
          child: _MenuRow(
            icon: Icons.delete_outline,
            text: "Delete contact",
            color: Color(0xFFDC2626),
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(Icons.more_horiz, color: Color(0xFF374151)),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MenuRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF101828);
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.inter(color: c, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SemicircularProgress extends StatelessWidget {
  final double value;
  final Color? progressColor;

  const _SemicircularProgress({
    required this.value,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: CustomPaint(
        painter: _SemicircularProgressPainter(
          value: value,
          progressColor: progressColor ?? const Color(0xFFDC2626),
        ),
      ),
    );
  }
}

class _SemicircularProgressPainter extends CustomPainter {
  final double value;
  final Color progressColor;

  _SemicircularProgressPainter({
    required this.value,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * value.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemicircularProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.progressColor != progressColor;
}

class _RelationshipDropdown extends StatelessWidget {
  final String selected;
  final List<RelationItem> relations;
  final bool busy;
  final ValueChanged<RelationItem> onSelected;

  const _RelationshipDropdown({
    required this.selected,
    required this.relations,
    this.busy = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RelationItem>(
      offset: const Offset(-20, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.zero,
      enabled: !busy,
      onSelected: onSelected,
      itemBuilder: (context) => relations
          .map(
            (opt) => PopupMenuItem<RelationItem>(
              value: opt,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: opt.relationName == selected
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  opt.relationName,
                  style: GoogleFonts.inter(
                    color: opt.relationName == selected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF374151),
                    fontWeight: opt.relationName == selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            Text(
              selected,
              style: GoogleFonts.inter(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E67FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(const Color(0x142E67FF)),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF98A2B3),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: child),
    );
  }
}

class _ElectionCollapsibleCard extends StatefulWidget {
  final String title;
  final String pillLabel;
  final bool initiallyExpanded;
  final Widget? expandedChild;

  const _ElectionCollapsibleCard({
    required this.title,
    this.pillLabel = 'ACTIVE',
    this.initiallyExpanded = false,
    this.expandedChild,
  });

  @override
  State<_ElectionCollapsibleCard> createState() =>
      _ElectionCollapsibleCardState();
}

class _ElectionCollapsibleCardState extends State<_ElectionCollapsibleCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final hasBody = widget.expandedChild != null;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: hasBody
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _ActivePill(label: widget.pillLabel),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF98A2B3),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && hasBody) widget.expandedChild!,
        ],
      ),
    );
  }
}

/// Outreach steps from API [CurrentElection] (same layout as static mock).
class _ApiElectionStepsBody extends StatefulWidget {
  final CurrentElection election;
  final String firstName;

  const _ApiElectionStepsBody({
    required this.election,
    required this.firstName,
  });

  @override
  State<_ApiElectionStepsBody> createState() => _ApiElectionStepsBodyState();
}

class _ApiElectionStepsBodyState extends State<_ApiElectionStepsBody> {
  static const _kBlue = Color(0xFF2563EB);
  late double _likelihoodSlider;
  late final TextEditingController _notesCtrl;
  late bool _done4;
  late bool _done5;
  late bool _done6;

  static String _letterForKey(String key) {
    switch (key.toLowerCase()) {
      case 'find':
        return 'F';
      case 'reach':
        return 'R';
      case 'include':
        return 'I';
      case 'encourage':
        return 'E';
      case 'nudge':
        return 'N';
      case 'done':
        return 'D';
      default:
        return key.isNotEmpty ? key[0].toUpperCase() : '?';
    }
  }

  static double _sliderFromIncludeStatus(int? s) {
    if (s == null) return 0.48;
    if (s <= 0) return 0.08;
    if (s == 1) return 0.5;
    return 0.92;
  }

  @override
  void initState() {
    super.initState();
    final inc = widget.election.firstOfStep(3);
    _likelihoodSlider = _sliderFromIncludeStatus(inc?.status);
    _notesCtrl = TextEditingController(text: widget.election.notes ?? '');
    _done4 = (widget.election.firstOfStep(4)?.status ?? 0) >= 2;
    _done5 = (widget.election.firstOfStep(5)?.status ?? 0) >= 2;
    _done6 = (widget.election.firstOfStep(6)?.status ?? 0) >= 2;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fn = widget.firstName;

    String personalize(String s) {
      return s.replaceAll(RegExp('Zille', caseSensitive: false), fn);
    }

    final fixedRows = <Widget>[];
    for (var n = 1; n <= 6; n++) {
      final g = widget.election.firstOfStep(n);
      if (g == null) continue;
      final letter = _letterForKey(g.key);
      final lineBelow = n < 6;
      final st = g.status;
      final titleMuted = n >= 4;
      final desc = personalize(g.subtitle);

      Widget? trailing;
      Widget? footer;
      Widget? extra;

      if (n == 1) {
        trailing = Icon(Icons.people_outline_rounded, color: _kBlue, size: 22);
        if (st != null && st >= 2) {
          footer = Text(
            '✓ Completed',
            style: GoogleFonts.inter(
              color: _kBlue,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          );
        }
      } else if (n == 2) {
        trailing =
            Icon(Icons.chat_bubble_outline_rounded, color: _kBlue, size: 20);
        if (st != null && st >= 2) {
          footer = Row(
            children: [
              Text(
                '✓ Completed',
                style: GoogleFonts.inter(
                  color: _kBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        }
      } else if (n == 3) {
        trailing = Icon(Icons.adjust_rounded, color: _kBlue, size: 22);
        extra = Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voting likelihood',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              _GradientLikelihoodSlider(
                value: _likelihoodSlider,
                onChanged: (v) => setState(() => _likelihoodSlider = v),
                showLabels: true,
              ),
            ],
          ),
        );
      } else if (n == 4) {
        trailing = Icon(Icons.notifications_none_rounded,
            color: const Color(0xFF94A3B8), size: 22);
        footer = _MarkDoneButton(
          done: _done4,
          onPressed: () => setState(() => _done4 = !_done4),
        );
      } else if (n == 5) {
        trailing = Icon(Icons.schedule_rounded,
            color: const Color(0xFF94A3B8), size: 22);
        footer = _MarkDoneButton(
          done: _done5,
          onPressed: () => setState(() => _done5 = !_done5),
        );
      } else if (n == 6) {
        trailing = Icon(Icons.check_circle_outline_rounded,
            color: const Color(0xFF94A3B8), size: 22);
        footer = _MarkDoneButton(
          done: _done6,
          onPressed: () => setState(() => _done6 = !_done6),
        );
      }

      fixedRows.add(
        _OutreachLetterRow(
          letter: letter,
          title: g.title,
          description: desc,
          lineBelow: lineBelow,
          trailing: trailing,
          footer: footer,
          extraBelowTitle: extra,
          titleMuted: titleMuted,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...fixedRows,
          const SizedBox(height: 18),
          Text(
            'NOTES',
            style: GoogleFonts.inter(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Add a note about $fn...',
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBlue, width: 1.2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// F–R–I–E–N–D outreach steps inside the active election card.
class _AprilElectionOutreachBody extends StatefulWidget {
  final String firstName;

  const _AprilElectionOutreachBody({required this.firstName});

  @override
  State<_AprilElectionOutreachBody> createState() =>
      _AprilElectionOutreachBodyState();
}

class _AprilElectionOutreachBodyState extends State<_AprilElectionOutreachBody> {
  static const _kBlue = Color(0xFF2563EB);
  double _likelihoodSlider = 0.48;
  final _notesCtrl = TextEditingController();
  bool _doneEncourage = false;
  bool _doneNudge = false;
  bool _doneThank = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fn = widget.firstName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OutreachLetterRow(
            letter: 'F',
            title: '1/6 Find',
            description:
                'Find your friend in the AMAC Circle app and add them to your contacts',
            lineBelow: true,
            trailing: Icon(Icons.people_outline_rounded, color: _kBlue, size: 22),
            footer: Text(
              '✓ Completed',
              style: GoogleFonts.inter(
                color: _kBlue,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          _OutreachLetterRow(
            letter: 'R',
            title: '2/6 Reach',
            description: 'Have you asked $fn to commit to voting?',
            lineBelow: true,
            trailing:
                Icon(Icons.chat_bubble_outline_rounded, color: _kBlue, size: 20),
            footer: Row(
              children: [
                Text(
                  '✓ Completed',
                  style: GoogleFonts.inter(
                    color: _kBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _OutreachLetterRow(
            letter: 'I',
            title: '3/6 Include',
            description: 'What did $fn decide about voting?',
            lineBelow: true,
            trailing: Icon(Icons.adjust_rounded, color: _kBlue, size: 22),
            extraBelowTitle: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voting likelihood',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _GradientLikelihoodSlider(
                    value: _likelihoodSlider,
                    onChanged: (v) => setState(() => _likelihoodSlider = v),
                    showLabels: true,
                  ),
                ],
              ),
            ),
          ),
          _OutreachLetterRow(
            letter: 'E',
            title: '4/6 Encourage',
            description: 'Did you encourage $fn to vote early?',
            lineBelow: true,
            titleMuted: true,
            trailing: Icon(Icons.notifications_none_rounded,
                color: const Color(0xFF94A3B8), size: 22),
            footer: _MarkDoneButton(
              done: _doneEncourage,
              onPressed: () => setState(() => _doneEncourage = !_doneEncourage),
            ),
          ),
          _OutreachLetterRow(
            letter: 'N',
            title: '5/6 Nudge',
            description:
                'Did you check in again right before Election Day?',
            lineBelow: true,
            titleMuted: true,
            trailing: Icon(Icons.schedule_rounded,
                color: const Color(0xFF94A3B8), size: 22),
            footer: _MarkDoneButton(
              done: _doneNudge,
              onPressed: () => setState(() => _doneNudge = !_doneNudge),
            ),
          ),
          _OutreachLetterRow(
            letter: 'D',
            title: '6/6 Done',
            description: 'Did you thank $fn for voting?',
            lineBelow: false,
            titleMuted: true,
            trailing: Icon(Icons.check_circle_outline_rounded,
                color: const Color(0xFF94A3B8), size: 22),
            footer: _MarkDoneButton(
              done: _doneThank,
              onPressed: () => setState(() => _doneThank = !_doneThank),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'NOTES',
            style: GoogleFonts.inter(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Add a note about $fn...',
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBlue, width: 1.2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkDoneButton extends StatelessWidget {
  static const _btnBlue = Color(0xFF2563EB);

  final bool done;
  final VoidCallback onPressed;

  const _MarkDoneButton({required this.done, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: done ? const Color(0xFFEFF6FF) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _btnBlue),
          ),
        ),
        child: Text(
          done ? 'Marked done' : 'Mark as Done',
          style: GoogleFonts.inter(
            color: _btnBlue,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _OutreachLetterRow extends StatelessWidget {
  final String letter;
  final String title;
  final String description;
  final bool lineBelow;
  final Widget? trailing;
  final Widget? footer;
  final Widget? extraBelowTitle;
  final bool titleMuted;

  const _OutreachLetterRow({
    required this.letter,
    required this.title,
    required this.description,
    required this.lineBelow,
    this.trailing,
    this.footer,
    this.extraBelowTitle,
    this.titleMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    const letterBlue = Color(0xFF2563EB);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: letterBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            if (lineBelow)
              Container(
                width: 2,
                height: 44,
                margin: const EdgeInsets.only(top: 4),
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: lineBelow ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: titleMuted
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          if (extraBelowTitle case final widget?) widget,
                        ],
                      ),
                    ),
                    if (trailing case final t?) t,
                  ],
                ),
                if (footer case final f?) ...[
                  const SizedBox(height: 8),
                  f,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientLikelihoodSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool showLabels;

  const _GradientLikelihoodSlider({
    required this.value,
    required this.onChanged,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Won't vote",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Unsure',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Will vote',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEF4444),
                        Color(0xFFF97316),
                        Color(0xFFEAB308),
                        Color(0xFF22C55E),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 10,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 11,
                      elevation: 2,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: value.clamp(0.0, 1.0),
                    onChanged: onChanged,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PastElectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PastElectionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      shadowColor: const Color(0x12000000),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  final String label;

  const _ActivePill({this.label = 'ACTIVE'});

  @override
  Widget build(BuildContext context) {
    final t = label.trim().toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        t.length > 14 ? '${t.substring(0, 14)}…' : t,
        style: GoogleFonts.inter(
          color: const Color(0xFF3B82F6),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _VotingHistoryTable extends StatelessWidget {
  final List<VotingHistoryYear>? apiRows;

  const _VotingHistoryTable({this.apiRows});

  static Widget _cellForSlot(ElectionSlot? slot) {
    if (slot == null) return Center(child: _CellDash());
    final s = slot.status.toUpperCase();
    if (s == 'NOT_VOTED') return Center(child: _CellRedX());
    if (s.contains('VOTED') && !s.contains('NOT')) {
      return Center(child: _CellCheck());
    }
    if (s == 'NO_DATA' || s.isEmpty) return Center(child: _CellQuestion());
    return Center(child: _CellQuestion());
  }

  static Widget _cellForSpecial(dynamic raw) {
    if (raw == null) return Center(child: _CellDash());
    if (raw is List && raw.isNotEmpty) {
      return Center(child: _CellSpecialDual());
    }
    if (raw is Map) {
      final st = raw['status']?.toString() ?? '';
      return _cellForSlot(ElectionSlot(election: '', status: st));
    }
    return Center(child: _CellDash());
  }

  @override
  Widget build(BuildContext context) {
    final dataRows = <TableRow>[];
    if (apiRows != null && apiRows!.isNotEmpty) {
      for (final y in apiRows!) {
        dataRows.add(
          _dataRow(
            y.year.toString(),
            Center(child: _cellForSlot(y.primary)),
            Center(child: _cellForSlot(y.general)),
            Center(child: _cellForSpecial(y.specialRaw)),
          ),
        );
      }
    } else {
      dataRows.addAll([
        _dataRow(
          "2026",
          Center(child: _CellQuestion()),
          Center(child: _CellQuestion()),
          Center(child: _CellDash()),
        ),
        _dataRow(
          "2025",
          Center(child: _CellCheck()),
          Center(child: _CellQuestion()),
          Center(child: _CellDash()),
        ),
        _dataRow(
          "2024",
          Center(child: _CellCheck()),
          Center(child: _CellRedX()),
          Center(child: _CellDash()),
        ),
        _dataRow(
          "2023",
          Center(child: _CellQuestion()),
          Center(child: _CellQuestion()),
          Center(child: _CellSpecialDual()),
        ),
        _dataRow(
          "2022",
          Center(child: _CellQuestion()),
          Center(child: _CellCheck()),
          Center(child: _CellDash()),
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            children: [
              _TableHeader("Year"),
              _TableHeader("(Aug) Primary"),
              _TableHeader("(Nov) General"),
              _TableHeader("Special"),
            ],
          ),
          ...dataRows,
        ],
      ),
    );
  }

  TableRow _dataRow(
    String year,
    Widget primary,
    Widget general,
    Widget special,
  ) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            year,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: primary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: general,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: special,
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CellQuestion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          "?",
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CellCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
    );
  }
}

class _CellRedX extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
    );
  }
}

class _CellSpecialDual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 4),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
        ),
      ],
    );
  }
}

class _CellDash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      "—",
      style: GoogleFonts.inter(
        color: const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
