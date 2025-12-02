// lib/screens/home_screen.dart
import 'dart:io';
import 'package:demo/screens/ContactUs.dart';
import 'package:demo/screens/CropCare.dart';
import 'package:demo/screens/Marketplace_screen.dart';
import 'package:demo/screens/Notification.dart';
import 'package:demo/screens/community_post_page.dart';
import 'package:demo/screens/diagnose_screen.dart';
import 'package:demo/screens/field_map_screen.dart';
import 'package:demo/screens/schedule_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Palette (single source of truth)
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color lightGreen = Color(0xFF74C043);
  static const Color offWhite = Color(0xFFF4F9F4);
  static const Color darkBg = Color(0xFF0E0E0E);

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Keep your screens (you can reorder / replace as needed)
  final List<Widget> screens = const [
    DiagnoseScreen(),
    MarketplacePage(),
    DiagnoseScreen(),
    CommunityPostPage(),
    FieldMapScreen(),
    Cropcare(),
  ];

  int bottomIndex = 0;
  int notificationCount = 9;

  File? _lastPickedImage;

  @override
  Widget build(BuildContext context) {
    // Responsive sizing helpers
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 720;

    return Scaffold(
      backgroundColor: offWhite,

      // Drawer
      drawer: _buildAppDrawer(context),

      // App bar with subtle gradient and action
      appBar: AppBar(
  automaticallyImplyLeading: true,
  backgroundColor: primaryGreen,
  elevation: 2,
  centerTitle: false,

  title: Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
        ),
        child: const Icon(Icons.eco, color: primaryGreen, size: 20),
      ),
      const SizedBox(width: 12),
      const Text('CropCareAI', style: TextStyle(fontWeight: FontWeight.w700)),
    ],
  ),

  actions: [

    // ⭐ Add Schedule Icon here
    IconButton(
      tooltip: "Schedule",
      icon: const Icon(Icons.event_note_outlined, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        );
      },
    ),

    // Existing Notification Button
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _notificationButton(),
    ),
  ],
),


      // --------------------------
      // KEY CHANGE: Body occupies the full remaining area (no Card/padding).
      // Use IndexedStack so each screen keeps its state while switching tabs.
      // --------------------------
      body: IndexedStack(
        index: bottomIndex,
        children: screens.map((w) {
          // Wrap each screen in a Container to ensure full size and background control
          return SizedBox.expand(
            child: Container(
              color: Colors.white, // background for each screen — change if needed
              child: w,
            ),
          );
        }).toList(),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.6)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: SafeArea(
          top: false, // keep only bottom safe area for nav bar
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: primaryGreen,
              unselectedItemColor: Colors.black54,
              showUnselectedLabels: true,
              currentIndex: bottomIndex,
              onTap: (index) => setState(() => bottomIndex = index),
             items: const [
  BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: "Chat"),
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Market"),
  BottomNavigationBarItem(icon: Icon(Icons.biotech), label: "Diagnose"),
  BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: "Community"),
  BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
  BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "Info"),
],

            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Notification button with badge ----------------
  Widget _notificationButton() {
    return Semantics(
      label: 'Notifications',
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
            },
            icon: const Icon(Icons.notifications_none, size: 28),
            color: Colors.white,
            tooltip: 'Notifications',
          ),
          if (notificationCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
                child: Text(
                  notificationCount > 9 ? '9+' : notificationCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Drawer ----------------
  Widget _buildAppDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      width: 300,
      child: Container(
        color: const Color(0xFFF7FBF7),
        child: Column(
          children: [
            // Header with gradient and profile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [primaryGreen, lightGreen]),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // open profile
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: _lastPickedImage != null
                              ? Image.file(_lastPickedImage!, fit: BoxFit.cover)
                              : (photoUrl != null
                                  ? Image.network(photoUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 36, color: primaryGreen)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Farmer',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Sections (grouped)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  const SizedBox(height: 6),
                  _drawerTile(icon: Icons.agriculture, label: 'My Fields', onTap: () => Navigator.pop(context)),
                  _drawerTile(icon: Icons.cloud_download, label: 'Crop Care', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Cropcare()))),
                  _drawerTile(icon: Icons.map, label: 'Field Map', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen()))),
                  _drawerTile(icon: Icons.forum, label: 'Community', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityPostPage()))),
                  _drawerTile(icon: Icons.notifications, label: 'Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage()))),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8),
                    child: Text('Useful', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700)),
                  ),
                  _drawerTile(icon: Icons.help_outline, label: 'Tutorials', onTap: () {}),
                  _drawerTile(icon: Icons.card_giftcard, label: 'Rewards', onTap: () {}),
                  _drawerTile(icon: Icons.attach_money, label: 'Plans & Pricing', onTap: () {}),
                  _drawerTile(icon: Icons.mail_outline, label: 'Contact Us', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsPage()))),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Privacy · Terms', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create drawer entries
  Widget _drawerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: primaryGreen),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      horizontalTitleGap: 6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 20,
    );
  }
}
