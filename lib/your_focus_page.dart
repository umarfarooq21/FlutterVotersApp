import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/APIs/ResponseClasses/contacts_catwise_response.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:quiz_app/APIs/api_service.dart';
import 'package:quiz_app/contact_details.dart';
import 'package:quiz_app/contact_name_format.dart';
import 'package:shimmer/shimmer.dart';

const Color _kBg = Colors.white;
const Color _kTitle = Color(0xFF0F172A);
const Color _kSub = Color(0xFF64748B);
const Color _kBlue = Color(0xFF2563EB);
const Color _kShimmerBase = Color(0xFFE5E7EB);
const Color _kShimmerHighlight = Color(0xFFF9FAFB);

bool _isNotYetContacted(ApiContactItem a) {
  final vr = a.voterResponse?.trim();
  if (vr != null && vr.isNotEmpty) return false;
  if (a.outreachStatus == 1) return false;
  return true;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final it = parts.iterator;
  if (!it.moveNext()) return '?';
  final a = it.current;
  if (!it.moveNext()) {
    return a.length >= 2 ? a.substring(0, 2).toUpperCase() : a.toUpperCase();
  }
  return '${a[0]}${it.current[0]}'.toUpperCase();
}

String _reachPillText(ApiContactItem c) {
  final ms = c.messageStatus;
  if (ms != null) {
    final s = ms.toString().trim();
    if (s.isNotEmpty && s != 'null') {
      if (s.contains('Reach') || s.contains('/')) return s;
      return '$s Reach';
    }
  }
  return '2/4 Reach';
}

String _statusTextForDetails(ApiContactItem a) {
  final vr = a.voterResponse?.trim();
  if (vr != null && vr.isNotEmpty) {
    if (vr.toLowerCase() == 'leaning') return 'Follow up';
    return 'Responded';
  }
  if (a.outreachStatus == 1) return 'Contacted';
  return 'To contact';
}

String _formatLocation(ApiContactItem c) {
  final parts = [
    c.address.trim(),
    c.city.trim(),
  ].where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '—';
  return parts.join(', ');
}

class YourFocusPage extends StatefulWidget {
  const YourFocusPage({super.key});

  @override
  State<YourFocusPage> createState() => _YourFocusPageState();
}

class _YourFocusPageState extends State<YourFocusPage> {
  bool _loading = true;
  String? _error;
  List<ApiContactItem> _notContacted = [];

  static const List<Color> _avatarColors = [
    Color(0xFF2563EB),
    Color(0xFFEA580C),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!await AuthStorage.hasSession()) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Sign in to see your focus list.';
          _notContacted = [];
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Sign in to see your focus list.';
          _notContacted = [];
        });
        return;
      }

      final res = await ApiService.getContactsCatWise(
        userId: userId,
        token: token,
      );
      if (!mounted) return;

      if (res == null) {
        setState(() {
          _loading = false;
          _error = 'Could not load contacts. Pull to retry.';
          _notContacted = [];
        });
        return;
      }

      final merged = <ApiContactItem>[
        ...res.needsAttention,
        ...res.mediumPriority,
        ...res.likelyVoting,
      ];
      final notContacted = merged
          .where(_isNotYetContacted)
          .toList(growable: false);

      setState(() {
        _notContacted = notContacted;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('YourFocusPage load: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load contacts. Pull to retry.';
      });
    }
  }

  Future<void> _openContact(ApiContactItem c) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ContactDetailsPage(
          contactId: c.contactId,
          name: formatContactDisplayName(c.name),
          phone: c.phone.trim(),
          statusText: _statusTextForDetails(c),
          isRegistered: c.voterStatus.toLowerCase().contains('registered'),
          initials: _initials(c.name),
          location: _formatLocation(c),
          relationship: c.relation.trim().isEmpty
              ? 'Friend'
              : c.relation.trim(),
        ),
      ),
    );
    if (mounted && deleted == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _notContacted.length;

    final baseTheme = Theme.of(context);
    final focusTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: focusTheme,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: _kTitle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Your Focus Today',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _kTitle,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: _kBlue,
                  onRefresh: _load,
                  child: _loading
                      ? _buildShimmer()
                      : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                            ),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _kSub,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: _kSub,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$remaining remaining',
                                    style: const TextStyle(
                                      color: _kTitle,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ' · Focus on these contacts to make the most impact today.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Not yet contacted · $remaining',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kTitle,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start with these — a quick ask is step 1.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kSub,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_notContacted.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Text(
                                  'You are all caught up — no contacts waiting for a first reach-out.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: _kSub,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            else
                              ...List.generate(_notContacted.length, (i) {
                                final c = _notContacted[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _FocusContactTile(
                                    name: formatContactDisplayName(c.name),
                                    reachLabel: _reachPillText(c),
                                    initials: _initials(c.name),
                                    avatarColor:
                                        _avatarColors[i % _avatarColors.length],
                                    onTap: () => _openContact(c),
                                  ),
                                );
                              }),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      children: [
        Shimmer.fromColors(
          baseColor: _kShimmerBase,
          highlightColor: _kShimmerHighlight,
          period: const Duration(milliseconds: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 18,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < 6; i++) ...[
                Container(
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusContactTile extends StatelessWidget {
  final String name;
  final String reachLabel;
  final String initials;
  final Color avatarColor;
  final VoidCallback onTap;

  const _FocusContactTile({
    required this.name,
    required this.reachLabel,
    required this.initials,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: _kTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: _kBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            reachLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: _kBlue,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
