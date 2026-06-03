import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/contacts.dart';
import 'package:quiz_app/impact.dart';
import 'package:quiz_app/login.dart';
import 'package:quiz_app/message_template.dart';
import 'package:quiz_app/about_page.dart';
import 'package:quiz_app/account_page.dart';
import 'package:quiz_app/profile_page.dart';
import 'package:quiz_app/terms_of_service_page.dart';
import 'package:quiz_app/APIs/Storage/auth_storage.dart';

const Color _kHomePrimaryBlue = Color(0xFF2563EB);
const Color _kHomeTabInactive = Color(0xFF94A3B8);
const Color _kHomeDivider = Color(0xFFE5E7EB);
const String _kAccountAvatarAsset = 'images/account_avatar.png';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ImpactPage(),
    const ContactSyncScreen(),
    const MessageTemplatePage(),
    const ProfilePage(),
  ];

  Future<void> _openProfileSheet() async {
    final results = await Future.wait([
      AuthStorage.getName(),
      AuthStorage.getEmail(),
    ]);
    if (!mounted) return;

    final storedName = results[0];
    final storedEmail = results[1];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final displayName = (storedName != null && storedName.trim().isNotEmpty)
            ? storedName.trim()
            : 'User';
        final displayEmail =
            (storedEmail != null && storedEmail.trim().isNotEmpty)
            ? storedEmail.trim()
            : '';

        return Theme(
          data: Theme.of(ctx).copyWith(
            textTheme: GoogleFonts.interTextTheme(Theme.of(ctx).textTheme),
            primaryTextTheme: GoogleFonts.interTextTheme(
              Theme.of(ctx).primaryTextTheme,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: const AssetImage(_kAccountAvatarAsset),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (displayEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                displayEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, thickness: 1, color: _kHomeDivider),
                  _SheetItem(
                    icon: Icons.person_outline,
                    label: 'Account',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountPage()),
                      );
                    },
                  ),
                  _SheetItem(
                    icon: Icons.info_outline,
                    label: 'About',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),
                  _SheetItem(
                    icon: Icons.description,
                    label: 'Terms of Service',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServicePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _LogoutButton(
                    onTap: () {
                      AuthStorage.clearSession();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: _BottomTabs(
        currentIndex: _currentIndex,
        onTapIndex: (i) => setState(() => _currentIndex = i),
        onTapProfile: _openProfileSheet,
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTapIndex;
  final VoidCallback onTapProfile;

  const _BottomTabs({
    required this.currentIndex,
    required this.onTapIndex,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kHomeDivider)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabItem(
              label: 'Impact',
              selected: currentIndex == 0,
              selectedIcon: Icons.bar_chart_rounded,
              unselectedIcon: Icons.bar_chart_outlined,
              onTap: () => onTapIndex(0),
            ),
            _TabItem(
              label: 'Contacts',
              selected: currentIndex == 1,
              selectedIcon: Icons.group,
              unselectedIcon: Icons.group_outlined,
              onTap: () => onTapIndex(1),
            ),
            _TabItem(
              label: 'Messages',
              selected: currentIndex == 2,
              selectedIcon: Icons.chat_bubble_outline,
              unselectedIcon: Icons.chat_bubble_outline,
              onTap: () => onTapIndex(2),
            ),
            _ProfileTabItem(selected: false, onTap: onTapProfile),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = selected ? _kHomePrimaryBlue : _kHomeTabInactive;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : unselectedIcon, color: c, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTabItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kHomePrimaryBlue : Colors.transparent,
                  width: 2,
                ),
                image: const DecorationImage(
                  image: AssetImage(_kAccountAvatarAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
      ),
      trailing: const SizedBox.shrink(),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.logout, color: Color(0xFFEF4444)),
              const SizedBox(width: 12),
              Text(
                'Log out',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Top row (space + bell with badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.sync, size: 35),
                    ),
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        // decoration: const BoxDecoration(
                        //   color: Colors.red,
                        //   shape: BoxShape.circle,
                        // ),
                        // child: const Text(
                        //   "0",
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontSize: 10,
                        //     fontWeight: FontWeight.w700,
                        //   ),
                        // ),
                      ),
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 6),

            // ✅ Title + subtitle
            Center(
              child: const Text(
                "Sync you Contact List Here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: const Text(
                "Please Sync your contacts using sync button.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ✅ On-Demand Ride Card
            _BigChoiceCard(
              title: "On-Demand Ride",
              subtitle: "Tap and go—rides when you want them",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPage()),
                );
              },
            ),

            const SizedBox(height: 14),

            // ✅ Subscribe & Ride Card
            _BigChoiceCard(
              title: "Subscribe & Ride",
              subtitle: "Enjoy scheduled rides at a fixed monthly rate.",
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // ✅ Active subscriptions small card
            _ActiveSubsCard(
              count: 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveSubscription()),
                );
              },
            ),
            

            ElevatedButton(
               onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text("Logout"),
            ),

            // ✅ push content up, keep bottom nav fixed
            const Spacer(),
          ],
        ),
      ),
    );
  }
}*/

class _BigChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigChoiceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0AB7A0),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 6),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xDFFFFFFF),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSubsCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ActiveSubsCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6EE),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 5),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text(
              "Active Subscriptions",
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              "$count",
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }
}
