import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/models/leaderboard_response.dart';
import 'package:quiz_app/services/auth_storage.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/views/captain_leaderboard_detail.dart';
import 'package:shimmer/shimmer.dart';

const Color _kLbBg = Color(0xFFF5F6F8);
const Color _kLbText = Color(0xFF0F172A);
const Color _kLbSub = Color(0xFF64748B);
const Color _kLbBlue = Color(0xFF2563EB);
const Color _kLbBorder = Color(0xFFE5E7EB);
const Color _kShimmerBase = Color(0xFFE5E7EB);
const Color _kShimmerHighlight = Color(0xFFF9FAFB);

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

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final it = parts.iterator;
  if (!it.moveNext()) return '?';
  final a = it.current;
  if (!it.moveNext()) {
    return a.length >= 2 ? a.substring(0, 2).toUpperCase() : a.toUpperCase();
  }
  return '${a[0]}${it.current[0]}'.toUpperCase();
}

// ──────────────────────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────────────────────

class CaptainLeaderboardPage extends StatefulWidget {
  const CaptainLeaderboardPage({super.key});

  @override
  State<CaptainLeaderboardPage> createState() => _CaptainLeaderboardPageState();
}

class _CaptainLeaderboardPageState extends State<CaptainLeaderboardPage> {
  bool _isLoading = true;
  String? _loadError;
  LeaderboardResponse? _data;

  /// 0 = FOUND, 1 = REACHED, 2 = INCLUDED
  int _selectedMetric = 2;

  static const _metricLabels = ['FOUND', 'REACHED', 'INCLUDED'];
  static const _metricIcons = [
    Icons.group_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.check_circle_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _loadError = null;
      if (_data == null) _isLoading = true;
    });

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        if (!mounted) return;
        setState(() {
          _data = null;
          _isLoading = false;
          _loadError = 'Sign in to view the leaderboard.';
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _data = null;
          _isLoading = false;
          _loadError = 'Sign in to view the leaderboard.';
        });
        return;
      }

      final response = await ApiService.getLeaderboard(
        userId: userId,
        token: token,
      );
      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isLoading = false;
          if (_data == null) {
            _loadError = 'Could not load leaderboard. Pull to retry.';
          }
        });
        return;
      }

      setState(() {
        _data = response;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e, st) {
      debugPrint('_loadLeaderboard: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_data == null) {
          _loadError = 'Could not load leaderboard. Pull to retry.';
        }
      });
    }
  }

  // ── per-row value based on selected metric ──────────────────────────────────
  int _captainValue(LeaderboardCaptainEntry e) {
    if (_selectedMetric == 0) return e.points;
    return e.committed;
  }

  // ── global metric totals ────────────────────────────────────────────────────
  List<int> _metricTotals(LeaderboardResponse data) => [
    data.contacts,
    data.messaged,
    data.committed,
  ];

  // ── builds the header (back button + title + subtitle) ─────────────────────
  Widget _buildHeader({required Widget subtitle}) {
    return Padding(
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
                color: _kLbText,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Captain Leaderboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _kLbText,
                  ),
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Main build
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final leaderboardTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: leaderboardTheme,
      child: Builder(
        builder: (context) {
          // ── shimmer state ──────────────────────────────────────────────────────
          if (_isLoading && _data == null) {
            return Scaffold(
              backgroundColor: _kLbBg,
              body: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, c) => RefreshIndicator(
                    color: _kLbBlue,
                    onRefresh: _loadLeaderboard,
                    child: _CaptainLeaderboardShimmer(
                      viewportHeight: c.maxHeight,
                      header: _buildHeader(
                        subtitle: Shimmer.fromColors(
                          baseColor: _kShimmerBase,
                          highlightColor: _kShimmerHighlight,
                          period: const Duration(milliseconds: 1200),
                          child: Container(
                            height: 14,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // ── error state ────────────────────────────────────────────────────────
          if (_data == null) {
            return Scaffold(
              backgroundColor: _kLbBg,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeader(subtitle: const SizedBox.shrink()),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _loadError ?? 'Something went wrong.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── loaded state ───────────────────────────────────────────────────────
          final data = _data!;
          final totals = _metricTotals(data);
          final captainCount = data.leaderboard.length;
          final selectedLabel = _metricLabels[_selectedMetric];
          final voterPct = (data.votersCompleteFraction * 100);
          final voterPctStr = voterPct == voterPct.roundToDouble()
              ? '${voterPct.round()}%'
              : '${voterPct.toStringAsFixed(1)}%';

          return Scaffold(
            backgroundColor: _kLbBg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(
                    subtitle: Text(
                      '$captainCount captains · Viewing ${selectedLabel.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kLbSub,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: _kLbBlue,
                      onRefresh: _loadLeaderboard,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        children: [
                          // ── Progress card ──────────────────────────────────────
                          _CardShell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Progress',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: _kLbText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _YearPill(year: data.year.toString()),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${data.year} Goal: ${data.goal}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kLbSub,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Full-width gauge
                                SizedBox(
                                  height: 180,
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 180),
                                    painter: _GaugePainter(
                                      value: data.gaugeFraction,
                                      labels: const [
                                        '0',
                                        '1',
                                        '2',
                                        '3',
                                        '4',
                                        '5',
                                        '6',
                                        '7',
                                      ],
                                      voterTotal: data.voters.total,
                                    ),
                                  ),
                                ),
                                // Voter count + percent centered below gauge
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _fmtComma(data.voters.completed),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: _kLbText,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/ ${_fmtComma(data.voters.total)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _kLbSub,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'VOTERS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _kLbSub,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      voterPctStr,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: _kLbBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'COMPLETE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _kLbSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Hint card ──────────────────────────────────────────
                          _CardShell(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: _kLbSub,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tap a metric to update the chart and table.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kLbSub,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Metric selector tiles ──────────────────────────────
                          Row(
                            children: [
                              for (var i = 0; i < 3; i++) ...[
                                Expanded(
                                  child: _MetricTile(
                                    icon: _metricIcons[i],
                                    label: _metricLabels[i],
                                    value: _fmtComma(totals[i]),
                                    selected: _selectedMetric == i,
                                    onTap: () =>
                                        setState(() => _selectedMetric = i),
                                  ),
                                ),
                                if (i < 2) const SizedBox(width: 10),
                              ],
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ── Leaderboard label + icons ──────────────────────────
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'LEADERBOARD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.9,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              _IconBtn(
                                icon: Icons.filter_list_rounded,
                                onTap: () {},
                              ),
                              const SizedBox(width: 4),
                              _IconBtn(
                                icon: Icons.swap_vert_rounded,
                                onTap: () {},
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── Leaderboard header row ─────────────────────────────
                          _CardShell(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 40,
                                  child: Text(
                                    'RANK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'CAPTAIN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Text(
                                  selectedLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Leaderboard rows ───────────────────────────────────
                          _CardShell(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                if (data.leaderboard.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No leaderboard data yet.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _kLbSub,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                for (
                                  var i = 0;
                                  i < data.leaderboard.length;
                                  i++
                                ) ...[
                                  _LeaderboardRowTile(
                                    entry: data.leaderboard[i],
                                    metricValue: _captainValue(
                                      data.leaderboard[i],
                                    ),
                                    metricLabel: selectedLabel,
                                    totalCaptains: captainCount,
                                  ),
                                  if (i != data.leaderboard.length - 1)
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: _kLbBorder,
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shimmer skeleton
// ──────────────────────────────────────────────────────────────────────────────

class _CaptainLeaderboardShimmer extends StatelessWidget {
  final double viewportHeight;
  final Widget header;

  const _CaptainLeaderboardShimmer({
    required this.viewportHeight,
    required this.header,
  });

  @override
  Widget build(BuildContext context) {
    final tail = math.max(0.0, viewportHeight - 600);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        header,
        Shimmer.fromColors(
          baseColor: _kShimmerBase,
          highlightColor: _kShimmerHighlight,
          period: const Duration(milliseconds: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress card skeleton
              _shimmerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _sBox(height: 20, width: 100)),
                        _sBox(height: 28, width: 56, radius: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _sBox(height: 13, width: 200),
                    const SizedBox(height: 12),
                    _sBox(height: 170, width: double.infinity, radius: 12),
                    const SizedBox(height: 10),
                    Center(child: _sBox(height: 28, width: 160)),
                    const SizedBox(height: 8),
                    Center(child: _sBox(height: 28, width: 120)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Hint card skeleton
              _shimmerCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _sBox(height: 14, width: double.infinity),
              ),
              const SizedBox(height: 12),
              // Metric tiles skeleton
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Expanded(child: _metricSkeleton()),
                    if (i < 2) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              _sBox(height: 14, width: 120),
              const SizedBox(height: 10),
              _shimmerCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: _sBox(height: 14, width: double.infinity),
              ),
              const SizedBox(height: 8),
              _shimmerCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < 8; i++) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            _sBox(height: 18, width: 24),
                            const SizedBox(width: 12),
                            _sBox(height: 40, width: 40, radius: 999),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sBox(height: 15, width: 130),
                                  const SizedBox(height: 6),
                                  _sBox(height: 12, width: 90),
                                ],
                              ),
                            ),
                            _sBox(height: 18, width: 32),
                          ],
                        ),
                      ),
                      if (i != 7)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: _kLbBorder,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tail),
      ],
    );
  }

  static Widget _sBox({
    double height = 14,
    double width = double.infinity,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget _shimmerCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
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

  static Widget _metricSkeleton() {
    return _shimmerCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sBox(height: 18, width: 18),
              const SizedBox(width: 6),
              Expanded(child: _sBox(height: 11, width: double.infinity)),
            ],
          ),
          const SizedBox(height: 10),
          _sBox(height: 22, width: 52),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Gauge
// ──────────────────────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double value;
  final List<String> labels;
  final int voterTotal;

  const _GaugePainter({
    required this.value,
    required this.labels,
    this.voterTotal = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 12.0;
    const outerPad = 28.0; // room for tick labels
    final radius = math.max(
      8.0,
      math.min(size.width / 2 - outerPad, size.height * 0.78),
    );
    // Center at 85% of height so labels fit at bottom
    final cx = size.width / 2;
    final cy = size.height * 0.85;
    final center = Offset(cx, cy);

    const pi = math.pi;
    const startAngle = pi;
    const sweepAngle = pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    final clampedVal = value.clamp(0.0, 1.0);
    if (clampedVal > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * clampedVal,
        false,
        Paint()
          ..color = _kLbBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Progress dot (filled circle at current position)
    final dotAngle = startAngle + sweepAngle * clampedVal;
    final dotCenter = Offset(
      cx + radius * math.cos(dotAngle),
      cy + radius * math.sin(dotAngle),
    );
    canvas.drawCircle(dotCenter, strokeW * 0.85, Paint()..color = _kLbBlue);

    // ── Tick labels (0-7) around the arc ──────────────────────────────────
    const tickStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    final ticks = labels.length - 1;
    for (var i = 0; i <= ticks; i++) {
      final t = i / ticks;
      final a = startAngle + sweepAngle * t;
      final tickR = radius + strokeW / 2 + 14;
      final pos = Offset(cx + tickR * math.cos(a), cy + tickR * math.sin(a));
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: tickStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // ── Milestone voter numbers inside the arc ────────────────────────────
    const milestoneStyle = TextStyle(
      color: Color(0xFFCBD5E1),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    String fmt(int v) {
      final s = v.toString();
      final buf = StringBuffer();
      for (var k = 0; k < s.length; k++) {
        final fromEnd = s.length - k;
        buf.write(s[k]);
        if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
      }
      return buf.toString();
    }

    void drawMilestone(String s, double t) {
      final a = startAngle + sweepAngle * t;
      final mR = radius - strokeW / 2 - 20;
      final pos = Offset(cx + mR * math.cos(a), cy + mR * math.sin(a));
      final tp = TextPainter(
        text: TextSpan(text: s, style: milestoneStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    if (voterTotal > 0) {
      drawMilestone(fmt((voterTotal * 0.14).round()), 0.14);
      drawMilestone(fmt((voterTotal * 0.43).round()), 0.43);
      drawMilestone(fmt((voterTotal * 0.71).round()), 0.71);
      drawMilestone(fmt(voterTotal), 0.93);
    }

    // ── POINTS label at bottom-left, VOTERS at bottom-right ───────────────
    const labelStyle2 = TextStyle(
      color: Color(0xFFCBD5E1),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    );

    final pointsTp = TextPainter(
      text: const TextSpan(text: 'POINTS', style: labelStyle2),
      textDirection: TextDirection.ltr,
    )..layout();
    pointsTp.paint(canvas, Offset(6, cy + 6));

    final votersTp = TextPainter(
      text: const TextSpan(text: 'VOTERS', style: labelStyle2),
      textDirection: TextDirection.ltr,
    )..layout();
    votersTp.paint(canvas, Offset(size.width - votersTp.width - 6, cy + 6));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value ||
      old.labels != labels ||
      old.voterTotal != voterTotal;
}

// ──────────────────────────────────────────────────────────────────────────────
// Small widgets
// ──────────────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

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

class _YearPill extends StatelessWidget {
  final String year;
  const _YearPill({required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        year,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _kLbText,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kLbBlue : _kLbBorder,
            width: selected ? 1.5 : 1.0,
          ),
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
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? _kLbBlue : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: selected ? _kLbBlue : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: selected ? _kLbBlue : _kLbText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Leaderboard row
// ──────────────────────────────────────────────────────────────────────────────

class _LeaderboardRowTile extends StatelessWidget {
  final LeaderboardCaptainEntry entry;
  final int metricValue;
  final String metricLabel;
  final int totalCaptains;

  const _LeaderboardRowTile({
    required this.entry,
    required this.metricValue,
    required this.metricLabel,
    this.totalCaptains = 0,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor(int r) {
      if (r == 1) return const Color(0xFFF59E0B);
      if (r == 2) return const Color(0xFF94A3B8);
      if (r == 3) return const Color(0xFFB45309);
      return const Color(0xFF94A3B8);
    }

    final initials = _initialsFromName(entry.captain);
    final name = entry.captain.isEmpty ? '—' : entry.captain;
    final location = entry.location.isEmpty ? '—' : entry.location;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CaptainDetailPage(entry: entry, totalCaptains: totalCaptains),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                entry.rank.toString(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: rankColor(entry.rank),
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kLbBlue,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kLbText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kLbSub,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              metricValue.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _kLbText,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
