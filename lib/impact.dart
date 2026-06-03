import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_app/APIs/ResponseClasses/plan777_mobile_response.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';
import 'package:quiz_app/APIs/api_service.dart';
import 'package:quiz_app/captain_leaderboard_page.dart';
import 'package:quiz_app/community_goal_page.dart';
import 'package:quiz_app/your_focus_page.dart';
import 'package:shimmer/shimmer.dart';

String _formatWithCommas(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buf.write(',');
    }
  }
  return buf.toString();
}

String _impactPctStr(double pct) => pct == pct.roundToDouble()
    ? '${pct.round()}%'
    : '${pct.toStringAsFixed(1)}%';

class ImpactPage extends StatefulWidget {
  const ImpactPage({super.key});

  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage> {
  static const _kPersonalGoalPrefKey = 'impact.personal_goal_voters';

  int _personalGoal = 10;
  int _confirmedVoters = 0;
  bool _isVoterImpactLoading = true;
  String? _voterImpactError;

  Plan777MobileResponse? _plan777;
  bool _isPlan777Loading = true;
  String? _plan777Error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadGoal();
    if (!mounted) return;
    await Future.wait([_loadVoterImpact(), _loadPlan777()]);
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kPersonalGoalPrefKey);
    if (!mounted) return;
    if (stored != null && stored > 0) {
      setState(() => _personalGoal = stored);
    }
  }

  Future<void> _saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPersonalGoalPrefKey, goal);
  }

  Future<void> _onTapSetGoal() async {
    final next = await _showSetGoalDialog(
      context: context,
      initialValue: _personalGoal,
      quickValues: const [10, 25, 50, 100],
    );
    if (!mounted || next == null) return;
    setState(() => _personalGoal = next);
    await _saveGoal(next);
  }

  Future<void> _loadVoterImpact() async {
    if (!mounted) return;
    setState(() {
      _isVoterImpactLoading = true;
      _voterImpactError = null;
    });

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        if (!mounted) return;
        setState(() {
          _isVoterImpactLoading = false;
          _confirmedVoters = 0;
          _voterImpactError = 'Sign in to see your goal.';
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isVoterImpactLoading = false;
          _confirmedVoters = 0;
          _voterImpactError = 'Sign in to see your goal.';
        });
        return;
      }

      final response = await ApiService.voterImpact(
        userId: userId,
        token: token,
      );
      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isVoterImpactLoading = false;
          _voterImpactError = 'Could not load your goal.';
        });
        return;
      }

      final serverGoal = response.goal;
      if (serverGoal > 0) {
        await _saveGoal(serverGoal);
      }

      setState(() {
        if (serverGoal > 0) {
          _personalGoal = serverGoal;
        }
        _confirmedVoters = response.confirmedVoters;
        _isVoterImpactLoading = false;
        _voterImpactError = null;
      });
    } catch (e, st) {
      debugPrint('_loadVoterImpact: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isVoterImpactLoading = false;
        _voterImpactError = 'Could not load your goal.';
      });
    }
  }

  Future<void> _loadPlan777() async {
    if (!mounted) return;
    setState(() {
      _isPlan777Loading = true;
      _plan777Error = null;
    });

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        if (!mounted) return;
        setState(() {
          _isPlan777Loading = false;
          _plan777 = null;
          _plan777Error = 'Sign in to view the community goal.';
        });
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isPlan777Loading = false;
          _plan777 = null;
          _plan777Error = 'Sign in to view the community goal.';
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
          _isPlan777Loading = false;
          if (_plan777 == null) {
            _plan777Error = 'Could not load community goal.';
          }
        });
        return;
      }

      setState(() {
        _plan777 = res;
        _isPlan777Loading = false;
        _plan777Error = null;
      });
    } catch (e, st) {
      debugPrint('_loadPlan777: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isPlan777Loading = false;
        if (_plan777 == null) {
          _plan777Error = 'Could not load community goal.';
        }
      });
    }
  }

  Future<int?> _showSetGoalDialog({
    required BuildContext context,
    required int initialValue,
    required List<int> quickValues,
  }) {
    return showGeneralDialog<int?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Set goal',
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) {
        final base = Theme.of(context);
        final dialogTheme = base.copyWith(
          textTheme: GoogleFonts.interTextTheme(base.textTheme),
          primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
        );
        return Theme(
          data: dialogTheme,
          child: _BlurredDialogHost(
            child: _SetGoalDialog(
              title: 'Set Your Goal',
              subtitle: 'Voters to confirm',
              initialValue: initialValue,
              quickValues: quickValues,
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Values are hard-coded to match the provided design mock.
    const focusDone = 2;
    const focusTotal = 5;
    const focusProgress = 0.40;

    final personalDone = _confirmedVoters;
    final personalTotal = _personalGoal;
    final personalProgress = personalTotal <= 0
        ? 0.0
        : (personalDone / personalTotal).clamp(0.0, 1.0);

    final plan = _plan777;
    final communityDone = plan?.voters.completed ?? 0;
    final communityTotal = plan?.voters.total ?? 0;
    final communityProgress = plan?.gaugeArcFraction ?? 0.0;
    final communityPctLabel = plan != null
        ? _impactPctStr(plan.voterCompletionPercent)
        : '0%';

    final baseTheme = Theme.of(context);
    final impactTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: impactTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
            children: [
              const Text(
                "Salaam, Amira",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your community impact at a glance.",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _FocusTodayCard(
                done: focusDone,
                total: focusTotal,
                progress: focusProgress,
                onTapViewContacts: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const YourFocusPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_isVoterImpactLoading)
                const _PersonalGoalCardShimmer()
              else
                _ProgressCard(
                  leading: _IconBadge(
                    background: Color(0xFFEFF6FF),
                    icon: Icons.trending_up_rounded,
                    iconColor: Color(0xFF2563EB),
                  ),
                  title: "Personal Goal",
                  subtitle: _voterImpactError != null
                      ? _voterImpactError!
                      : "Goal: Confirm $personalTotal voters",
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _onTapSetGoal,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Pill(text: "$personalDone/$personalTotal"),
                    ],
                  ),
                  progressLabel: "PROGRESS",
                  progressValueText: "${(personalProgress * 100).round()}%",
                  progress: personalProgress,
                  progressColor: const Color(0xFF2563EB),
                  backgroundTrackColor: const Color(0xFFE5E7EB),
                  onTap: () {},
                ),
              const SizedBox(height: 14),
              _InfoCard(
                leading: const _IconBadge(
                  background: Color(0xFFFFF7ED),
                  icon: Icons.emoji_events_outlined,
                  iconColor: Color(0xFFF59E0B),
                ),
                title: "Captain Leaderboard",
                subtitle: "16 captains · 431 committed",
                footerLinkText: "View full leaderboard",
                onTapFooter: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CaptainLeaderboardPage(),
                    ),
                  );
                },
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CaptainLeaderboardPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              if (_isPlan777Loading && plan == null)
                const _PersonalGoalCardShimmer()
              else
                _ProgressCard(
                  leading: const _IconBadge(
                    background: Color(0xFFEDE9FE),
                    icon: Icons.adjust_rounded,
                    iconColor: Color(0xFF7C3AED),
                  ),
                  title: "Community Goal",
                  subtitle: _plan777Error != null
                      ? _plan777Error!
                      : "Increasing Muslim Voter Turnout",
                  trailing: _Pill(
                    text: communityTotal > 0
                        ? "${_formatWithCommas(communityDone)}/${_formatWithCommas(communityTotal)}"
                        : "${_formatWithCommas(communityDone)}/—",
                  ),
                  progressLabel: plan != null
                      ? "${plan.year} COMMUNITY PROGRESS"
                      : "2026 COMMUNITY PROGRESS",
                  progressValueText: communityPctLabel,
                  progress: communityProgress,
                  progressColor: const Color(0xFF2563EB),
                  backgroundTrackColor: const Color(0xFFE5E7EB),
                  footerLinkText: "Tap to view city breakdown",
                  onTapFooter: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommunityGoalPage(),
                      ),
                    );
                  },
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommunityGoalPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the Personal Goal `_ProgressCard` (`Shimmer.fromColors` like contacts).
class _PersonalGoalCardShimmer extends StatelessWidget {
  const _PersonalGoalCardShimmer();

  static const Color _base = Color(0xFFE5E7EB);
  static const Color _highlight = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 36,
                  width: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  height: 12,
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 14,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurredDialogHost extends StatelessWidget {
  final Widget child;
  const _BlurredDialogHost({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.expand(),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

class _SetGoalDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final int initialValue;
  final List<int> quickValues;

  const _SetGoalDialog({
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.quickValues,
  });

  @override
  State<_SetGoalDialog> createState() => _SetGoalDialogState();
}

class _SetGoalDialogState extends State<_SetGoalDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final v in widget.quickValues) ...[
                          _QuickChoice(
                            value: v,
                            selected: _value == v,
                            onTap: () => setState(() => _value = v),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ].toList()..removeLast(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            _value.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(null),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(_value),
                        child: Center(
                          child: Text(
                            'Save',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChoice extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _QuickChoice({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9);
    final fg = selected ? Colors.white : const Color(0xFF334155);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value.toString(),
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusTodayCard extends StatelessWidget {
  final int done;
  final int total;
  final double progress;
  final VoidCallback onTapViewContacts;

  const _FocusTodayCard({
    required this.done,
    required this.total,
    required this.progress,
    required this.onTapViewContacts,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = "${(progress * 100).round()}%";

    return GestureDetector(
      onTap: onTapViewContacts,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F5BFF), Color(0xFF6D42FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Focus Today",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Check in with your key contacts\ntoday",
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  text: "$done/$total",
                  background: const Color(0x26FFFFFF),
                  foreground: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  "PROGRESS",
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  percentText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _RoundedProgressBar(
              value: progress,
              trackColor: const Color(0x3D000000),
              valueColor: Colors.white,
              height: 10,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "View Contacts",
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: Color(0xCCFFFFFF)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final String progressLabel;
  final String progressValueText;
  final double progress;
  final Color progressColor;
  final Color backgroundTrackColor;
  final String? footerLinkText;
  final VoidCallback? onTapFooter;
  final VoidCallback? onTap;

  const _ProgressCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.progressLabel,
    required this.progressValueText,
    required this.progress,
    required this.progressColor,
    required this.backgroundTrackColor,
    this.footerLinkText,
    this.onTapFooter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                progressLabel,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                progressValueText,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RoundedProgressBar(
            value: progress,
            trackColor: backgroundTrackColor,
            valueColor: progressColor,
            height: 10,
          ),
          if (footerLinkText != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onTapFooter,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      footerLinkText!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String footerLinkText;
  final VoidCallback onTapFooter;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.footerLinkText,
    required this.onTapFooter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onTapFooter,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    footerLinkText,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CardShell({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
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
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Color background;
  final IconData icon;
  final Color iconColor;

  const _IconBadge({
    required this.background,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: iconColor, size: 26),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.text,
    this.background = const Color(0xFFF1F5F9),
    this.foreground = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoundedProgressBar extends StatelessWidget {
  final double value;
  final Color trackColor;
  final Color valueColor;
  final double height;

  const _RoundedProgressBar({
    required this.value,
    required this.trackColor,
    required this.valueColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(valueColor),
        minHeight: height,
      ),
    );
  }
}
