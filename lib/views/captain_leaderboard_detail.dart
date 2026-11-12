import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/models/captain_detail_response.dart';
import 'package:quiz_app/models/leaderboard_response.dart';
import 'package:quiz_app/services/auth_storage.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:shimmer/shimmer.dart';

const Color _kBg = Color(0xFFF5F6F8);
const Color _kText = Color(0xFF0F172A);
const Color _kSub = Color(0xFF64748B);
const Color _kBlue = Color(0xFF2563EB);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kShimmerBase = Color(0xFFE5E7EB);
const Color _kShimmerHl = Color(0xFFF9FAFB);

String _fmtComma(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

String _monthYear(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

String _relativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  final now = DateTime.now();
  var diff = now.difference(d);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inDays >= 365) {
    final y = diff.inDays ~/ 365;
    return '$y year${y == 1 ? '' : 's'} ago';
  }
  if (diff.inDays >= 30) {
    final m = diff.inDays ~/ 30;
    return '$m month${m == 1 ? '' : 's'} ago';
  }
  if (diff.inDays >= 1)
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inHours >= 1)
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
  }
  return 'Just now';
}

String _activityLineTime(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yday = today.subtract(const Duration(days: 1));
  final day = DateTime(d.year, d.month, d.day);
  final t =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (day == today) return 'Today at $t';
  if (day == yday) return 'Yesterday at $t';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} at $t';
}

// ──────────────────────────────────────────────────────────────────────────────
// Captain Detail Page
// ──────────────────────────────────────────────────────────────────────────────

class CaptainDetailPage extends StatefulWidget {
  final LeaderboardCaptainEntry entry;
  final int totalCaptains;

  const CaptainDetailPage({
    super.key,
    required this.entry,
    this.totalCaptains = 0,
  });

  @override
  State<CaptainDetailPage> createState() => _CaptainDetailPageState();
}

class _CaptainDetailPageState extends State<CaptainDetailPage> {
  CaptainDetailResponse? _data;
  bool _loading = true;
  String? _error;

  LeaderboardCaptainEntry get _e => widget.entry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _e.captainId.trim();
    if (id.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Captain profile is unavailable (missing id). Try refreshing the leaderboard.';
        _data = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Sign in to view this profile.';
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Sign in to view this profile.';
        });
        return;
      }

      final res = await ApiService.getCaptainDetail(
        captainId: id,
        userId: userId,
        token: token,
      );
      if (!mounted) return;

      if (res == null) {
        setState(() {
          _loading = false;
          if (_data == null) {
            _error = 'Could not load captain profile. Pull to retry.';
          }
        });
        return;
      }

      setState(() {
        _data = res;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('CaptainDetailPage._load: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = 'Could not load captain profile. Pull to retry.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleName =
        _data?.name ?? (_e.captain.isEmpty ? 'Captain' : _e.captain);

    final baseTheme = Theme.of(context);
    // Inter — same family as many product UIs (close to SF Pro on iOS / Roboto on Android).
    final detailTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: detailTheme,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 18, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _kText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        titleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _kText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading && _data == null
                    ? RefreshIndicator(
                        color: _kBlue,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            28 + MediaQuery.of(context).padding.bottom,
                          ),
                          children: [
                            const _CaptainDetailBodyShimmer(),
                            SizedBox(
                              height: math.max(
                                240.0,
                                MediaQuery.of(context).size.height * 0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _data == null && _error != null
                    ? RefreshIndicator(
                        color: _kBlue,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.2,
                            left: 24,
                            right: 24,
                            bottom: MediaQuery.of(context).padding.bottom + 48,
                          ),
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: _kBlue,
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            28 + MediaQuery.of(context).padding.bottom,
                          ),
                          children: _buildContent(context),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final d = _data!;
    final m = d.metrics;
    final rank = d.rank;
    final outOf = rank.ofTotal > 0 ? rank.ofTotal : widget.totalCaptains;
    final denom = (m.contactsAdded > 0 ? m.contactsAdded : 1).toDouble();
    final barContacts = m.contactsAdded > 0 ? 1.0 : 0.0;
    final barAsked = (m.asked / denom).clamp(0.0, 1.0);
    final barAgreed = (m.agreedToVote / denom).clamp(0.0, 1.0);

    final city = d.location.isNotEmpty ? d.location : _e.location;
    final cityDisplay = city.isEmpty ? '—' : city;
    final rankLabel = rank.label.isNotEmpty
        ? rank.label
        : 'No rank change this week';

    return [
      _RankHeroCard(
        rank: rank.current > 0 ? rank.current : _e.rank,
        totalCaptains: outOf,
        footnote: rankLabel,
      ),
      const SizedBox(height: 20),
      const _SectionTitle('Performance Metrics'),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _MetricBox(
              icon: Icons.groups_outlined,
              iconColor: const Color(0xFF6366F1),
              iconBg: const Color(0xFFEEF2FF),
              value: _fmtComma(m.contactsAdded),
              label: 'Total Contacts',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricBox(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBg: const Color(0xFFF5F3FF),
              value: _fmtComma(m.asked),
              label: 'Asked (${m.askedPct}%)',
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _MetricBox(
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFFF0FDF4),
              value: _fmtComma(m.agreedToVote),
              label: 'Agreed to Vote (${m.agreedToVotePct}%)',
              valueColor: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricBox(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBg: const Color(0xFFF5F3FF),
              value: '${m.conversionRatePct}%',
              label: 'Conversion Rate',
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const _SectionTitle('Outreach Progress'),
      const SizedBox(height: 10),
      _CardShell(
        child: Column(
          children: [
            _OutreachBar(
              label: 'Contacts Added',
              value: _fmtComma(m.contactsAdded),
              progress: barContacts,
              color: _kBlue,
            ),
            const SizedBox(height: 14),
            _OutreachBar(
              label: 'Asked',
              value: '${_fmtComma(m.asked)} (${m.askedPct}%)',
              progress: barAsked,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 14),
            _OutreachBar(
              label: 'Agreed to Vote',
              value: '${_fmtComma(m.agreedToVote)} (${m.agreedToVotePct}%)',
              progress: barAgreed,
              color: const Color(0xFF22C55E),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const _SectionTitle('Recent Activity'),
      const SizedBox(height: 10),
      _CardShell(
        padding: EdgeInsets.zero,
        child: d.recentActivity.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Text(
                  'No recent activity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kSub.withValues(alpha: 0.9),
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < d.recentActivity.length; i++) ...[
                    _ActivityRow(item: d.recentActivity[i]),
                    if (i != d.recentActivity.length - 1)
                      const Divider(height: 1, thickness: 1, color: _kBorder),
                  ],
                ],
              ),
      ),
      const SizedBox(height: 20),
      const _SectionTitle('Captain Info'),
      const SizedBox(height: 10),
      _CardShell(
        child: Column(
          children: [
            _InfoRow(label: 'Joined', value: _monthYear(d.joinedAt)),
            const _InfoDivider(),
            _InfoRow(
              label: 'Last Active',
              value: _relativeTime(d.lastActiveAt),
            ),
            const _InfoDivider(),
            _InfoRow(label: 'City', value: cityDisplay),
          ],
        ),
      ),
    ];
  }
}

class _ActivityRow extends StatelessWidget {
  final CaptainDetailActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: _kBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activityLineTime(item.at),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptainDetailBodyShimmer extends StatelessWidget {
  const _CaptainDetailBodyShimmer();

  static Widget _box({
    double h = 14,
    double w = double.infinity,
    double r = 8,
  }) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }

  static Widget _card({
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kShimmerBase,
      highlightColor: _kShimmerHl,
      period: const Duration(milliseconds: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _box(h: 14, w: 120)),
                    _box(h: 28, w: 40, r: 8),
                  ],
                ),
                const SizedBox(height: 16),
                _box(h: 48, w: 100),
                const SizedBox(height: 12),
                _box(h: 14, w: 200),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _box(h: 18, w: 180),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(h: 32, w: 32, r: 8),
                      const SizedBox(height: 12),
                      _box(h: 26, w: 60),
                      const SizedBox(height: 8),
                      _box(h: 12, w: 100),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(h: 32, w: 32, r: 8),
                      const SizedBox(height: 12),
                      _box(h: 26, w: 60),
                      const SizedBox(height: 8),
                      _box(h: 12, w: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _card(child: _box(h: 80))),
              const SizedBox(width: 10),
              Expanded(child: _card(child: _box(h: 80))),
            ],
          ),
          const SizedBox(height: 18),
          _box(h: 18, w: 160),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _box(h: 12),
                const SizedBox(height: 10),
                _box(h: 8),
                const SizedBox(height: 14),
                _box(h: 12),
                const SizedBox(height: 10),
                _box(h: 8),
                const SizedBox(height: 14),
                _box(h: 12),
                const SizedBox(height: 10),
                _box(h: 8),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _box(h: 18, w: 140),
          const SizedBox(height: 10),
          _card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        _box(h: 38, w: 38, r: 999),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _box(h: 15, w: 160),
                              const SizedBox(height: 6),
                              _box(h: 12, w: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < 3) const Divider(height: 1, color: _kBorder),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankHeroCard extends StatelessWidget {
  final int rank;
  final int totalCaptains;
  final String footnote;

  const _RankHeroCard({
    required this.rank,
    required this.totalCaptains,
    required this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B5BDB), Color(0xFF5C7CFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33355EC8),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Leaderboard Rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
              if (totalCaptains > 0) ...[
                const Text(
                  'out of',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  totalCaptains.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  footnote,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final Color? valueColor;

  const _MetricBox({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: valueColor ?? _kText,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutreachBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _OutreachBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
            ),
            Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kSub,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _kBorder);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: _kText,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
