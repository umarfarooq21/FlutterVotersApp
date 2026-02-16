import 'package:flutter/material.dart';
import 'package:quiz_app/book_a_ride.dart';
import 'package:quiz_app/rides_page.dart';
import 'package:quiz_app/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const BookARidePage(),
    const RidesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF0A73B7),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi_outlined),
            label: "Book a Ride",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            label: "Rides",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

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
                      icon: const Icon(Icons.notifications_none, size: 26),
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
            const Text(
              "What kind of ride do\nyou need?",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select your ride preference below",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            // ✅ On-Demand Ride Card
            _BigChoiceCard(
              title: "On-Demand Ride",
              subtitle: "Tap and go—rides when you want them",
              onTap: () {},
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
              onTap: () {},
            ),

            // ✅ push content up, keep bottom nav fixed
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

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
          color: const Color(0xFF0A73B7),
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

  const _ActiveSubsCard({
    required this.count,
    required this.onTap,
  });

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
