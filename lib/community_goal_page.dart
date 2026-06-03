import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/APIs/ResponseClasses/plan777_mobile_response.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:quiz_app/APIs/api_service.dart';
import 'package:shimmer/shimmer.dart';

const Color _cgBg = Color(0xFFF5F6F8);
const Color _cgText = Color(0xFF0F172A);
const Color _cgSub = Color(0xFF64748B);
const Color _cgBlue = Color(0xFF2563EB);
const Color _cgBorder = Color(0xFFE5E7EB);
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

String _targetLine(String goal) {
  final g = goal.trim();
  if (g.isEmpty) {
    return 'Target: +7 points across 7 cities over 7 cycles';
  }
  final withPlus = g.startsWith('+') ? g : '+$g';
  return 'Target: $withPlus';
}

String _pctStr(double pct) => pct == pct.roundToDouble()
    ? '${pct.round()}%'
    : '${pct.toStringAsFixed(1)}%';

class CommunityGoalPage extends StatefulWidget {
  const CommunityGoalPage({super.key});

  @override
  State<CommunityGoalPage> createState() => _CommunityGoalPageState();
}

class _CommunityGoalPageState extends State<CommunityGoalPage> {
  bool _isLoading = true;
  String? _loadError;
  Plan777MobileResponse? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loadError = null;
      if (_data == null) _isLoading = true;
    });

    try {
      if (!await AuthStorage.hasSession()) {
        if (!mounted) return;
        setState(() {
          _data = null;
          _isLoading = false;
          _loadError = 'Sign in to view the 2026 goal.';
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
          _loadError = 'Sign in to view the 2026 goal.';
        });
        return;
      }

      final res = await ApiService.getPlan777Mobile(
        userId: userId,
        token: token,
      );
      if (!mounted) return;

      if (res == null) {
        setState(() {
          _isLoading = false;
          if (_data == null) {
            _loadError = 'Could not load goal data. Pull to retry.';
          }
        });
        return;
      }

      setState(() {
        _data = res;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e, st) {
      debugPrint('_load plan777: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_data == null) {
          _loadError = 'Could not load goal data. Pull to retry.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final communityGoalTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: communityGoalTheme,
      child: Scaffold(
        backgroundColor: _cgBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildChromeHeader(showSubtitle: !_isLoading && _data != null),
              const Divider(height: 1, thickness: 1, color: _cgBorder),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChromeHeader({required bool showSubtitle}) {
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
                color: _cgText,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _data == null ? '2026 Goal' : '${_data!.year} Goal',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _cgText,
                  ),
                ),
                if (showSubtitle && _data != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _data!.subtitleTagline,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _cgSub,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return RefreshIndicator(
        color: _cgBlue,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _CommunityGoalShimmer(),
          ),
        ),
      );
    }

    if (_data == null) {
      return RefreshIndicator(
        color: _cgBlue,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _loadError ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final d = _data!;
    final voterPctDisplay = _pctStr(d.voterCompletionPercent);

    return RefreshIndicator(
      color: _cgBlue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(
                bottom: 4,
                left: 0,
                right: 0,
                top: 0,
              ),
              title: const Text(
                'About the 2026 Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    d.goal.isEmpty
                        ? 'Community turnout goal for Washington cities.'
                        : d.goal,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: _cgSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SoftGradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${d.year} ELECTION CYCLE PROGRESS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.85,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _targetLine(d.goal),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _cgSub,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 178,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CommunityGaugePainter(
                      value: d.gaugeArcFraction,
                      voterTotal: d.voters.total,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _fmtComma(d.voters.completed),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _cgText,
                      ),
                    ),
                    Text(
                      ' / ${_fmtComma(d.voters.total)} ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _cgSub,
                      ),
                    ),
                    const Text(
                      'VOTERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.75,
                        color: _cgSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      voterPctDisplay,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: _cgBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'COMPLETE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.75,
                        color: _cgSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'City-by-City Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _cgText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Target: 1-point voter turnout increase per city',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _cgSub,
            ),
          ),
          const SizedBox(height: 14),
          for (final c in d.cityProgress) ...[
            _CityProgressCard(entry: c),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityGoalShimmer extends StatelessWidget {
  const _CommunityGoalShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kShimmerBase,
      highlightColor: _kShimmerHighlight,
      period: const Duration(milliseconds: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _box(height: 18, width: 180, radius: 8),
          const SizedBox(height: 8),
          _box(height: 14, width: 260, radius: 7),
          const SizedBox(height: 20),
          _box(height: 16, width: double.infinity, radius: 8),
          const SizedBox(height: 14),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 22),
          _box(height: 20, width: 220, radius: 8),
          const SizedBox(height: 10),
          _box(height: 14, width: 300, radius: 7),
          const SizedBox(height: 14),
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  static Widget _box({
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Gauge (semi-circle, aligns with leaderboard style)
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityGaugePainter extends CustomPainter {
  final double value;
  final int voterTotal;

  _CommunityGaugePainter({required this.value, this.voterTotal = 0});

  static const List<String> _labels = ['0', '1', '2', '3', '4', '5', '6', '7'];

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 12.0;
    const outerPad = 26.0;
    final cx = size.width / 2;
    final radius = math.max(
      8.0,
      math.min(size.width / 2 - outerPad, size.height * 0.78),
    );
    final cy = size.height * 0.86;
    final center = Offset(cx, cy);

    const pi = math.pi;
    const startAngle = pi;
    const sweepAngle = pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = _cgBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    final v = value.clamp(0.0, 1.0);
    if (v > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * v,
        false,
        Paint()
          ..color = _cgBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    final dotAngle = startAngle + sweepAngle * v;
    final dotCenter = Offset(
      cx + radius * math.cos(dotAngle),
      cy + radius * math.sin(dotAngle),
    );
    canvas.drawCircle(dotCenter, strokeW * 0.85, Paint()..color = _cgBlue);

    const tickStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    final ticks = _labels.length - 1;
    for (var i = 0; i <= ticks; i++) {
      final t = i / ticks;
      final a = startAngle + sweepAngle * t;
      final tickR = radius + strokeW / 2 + 13;
      final pos = Offset(cx + tickR * math.cos(a), cy + tickR * math.sin(a));
      final tp = TextPainter(
        text: TextSpan(text: _labels[i], style: tickStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    const milestoneStyle = TextStyle(
      color: Color(0xFFCBD5E1),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    void drawMs(String s, double frac) {
      final a = startAngle + sweepAngle * frac;
      final r = radius - strokeW / 2 - 20;
      final pos = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      final tp = TextPainter(
        text: TextSpan(text: s, style: milestoneStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    final tot = voterTotal;
    if (tot > 0) {
      drawMs(_fmtComma((tot * 0.14).round()), 0.14);
      drawMs(_fmtComma((tot * 0.43).round()), 0.43);
      drawMs(_fmtComma((tot * 0.71).round()), 0.71);
      drawMs(_fmtComma(tot), 0.93);
    }

    const cornerLabel = TextStyle(
      color: Color(0xFFCBD5E1),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.75,
    );

    final pTp = TextPainter(
      text: const TextSpan(text: 'POINTS', style: cornerLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    pTp.paint(canvas, Offset(0, cy + 4));

    final vTp = TextPainter(
      text: const TextSpan(text: 'VOTERS', style: cornerLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    vTp.paint(canvas, Offset(size.width - vTp.width, cy + 4));
  }

  @override
  bool shouldRepaint(covariant _CommunityGaugePainter old) =>
      old.value != value || old.voterTotal != voterTotal;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────────

class _SoftGradientCard extends StatelessWidget {
  final Widget child;
  const _SoftGradientCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0x26DBEAFE), Color(0x14F0F9FF), Color(0x1A93C5FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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

class _CityProgressCard extends StatelessWidget {
  final Plan777CityProgress entry;

  const _CityProgressCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final pctLabel = _pctStr(entry.percentageOfTotalVoters);
    final p = entry.linearProgress;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cgBlue, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.city.isEmpty ? '—' : entry.city,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _cgText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _cgSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.voterCompletion} / ${entry.totalVoters}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _cgText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pctLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _cgSub,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p,
              backgroundColor: _cgBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(_cgBlue),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
