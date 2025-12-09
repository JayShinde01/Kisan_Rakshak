// lib/screens/home_screen.dart
import 'dart:io';
import 'package:demo/screens/ContactUs.dart';
import 'package:demo/screens/CropCare.dart';
import 'package:demo/screens/Marketplace_screen.dart';
import 'package:demo/screens/Notification.dart';
import 'package:demo/screens/community_post_page.dart';
import 'package:demo/screens/dashboard_screen.dart';
import 'package:demo/screens/diagnose_screen.dart';
import 'package:demo/screens/field_map_screen.dart';
import 'package:demo/screens/schedule_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/theme_manager.dart';
import 'package:demo/screens/chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Palette (kept)
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color lightGreen = Color(0xFF74C043);
  static const Color offWhite = Color(0xFFF4F9F4);

  final List<Widget> _screens = const [
    HomeContent(),
    MarketplacePage(),
    DiagnoseScreen(),
    CommunityPostPage(),
    FieldMapScreen(),
    Cropcare(),
  ];

  int _selectedIndex = 0;
  int notificationCount = 9;
  File? _lastPickedImage;

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

  void _onNavSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    final toolbarHeight = isMobile ? 56.0 : (isTablet ? 64.0 : 72.0);
    final iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final avatarSize = isMobile ? 36.0 : (isTablet ? 42.0 : 48.0);
    final titleFont = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    return Scaffold(
      backgroundColor: offWhite,
      drawer: _buildAppDrawer(context, isDesktop: isDesktop),

      floatingActionButton: FloatingActionButton(
        heroTag: 'home_chat_fab',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        tooltip: tr('open_chat'),
      ),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(toolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: primaryGreen,
          elevation: 2,
          toolbarHeight: toolbarHeight,
          titleSpacing: 12,
          title: Row(children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]),
              child: CircleAvatar(
  radius: 24,
  backgroundColor: Colors.white,
  child: ClipOval(
    child: Image.asset(
      'assets/images/Logo_App.png',
      height: 80,
      width: 80,
      fit: BoxFit.cover,  // or BoxFit.contain based on your logo
    ),
  ),
),

            ),
            SizedBox(width: isMobile ? 5 : 7),
            Flexible(
              child: Text(
                tr('app_title'),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: titleFont),
              ),
            ),
          ]),
          actions: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: ThemeToggleButton()),
            IconButton(
              tooltip: tr('schedule'),
              icon: Icon(Icons.event_note_outlined, color: Colors.white, size: iconSize + 2),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
            ),
            Padding(padding: EdgeInsets.only(right: isMobile ? 4 : 8), child: _notificationButton(isMobile: isMobile, iconSize: iconSize)),
          ],
        ),
      ),

      body: Row(children: [
        if (isDesktop) ...[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavSelected,
            extended: width > 1400,
            labelType: width > 1400 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(children: [
              ]),
            ),
            minWidth: 72,
            destinations: [
              NavigationRailDestination(icon: const Icon(Icons.chat_outlined), label: Text(tr('nav_chat'))),
              NavigationRailDestination(icon: const Icon(Icons.storefront), label: Text(tr('nav_market'))),
              NavigationRailDestination(icon: const Icon(Icons.biotech), label: Text(tr('nav_diagnose'))),
              NavigationRailDestination(icon: const Icon(Icons.groups_outlined), label: Text(tr('nav_community'))),
              NavigationRailDestination(icon: const Icon(Icons.map_outlined), label: Text(tr('nav_map'))),
              NavigationRailDestination(icon: const Icon(Icons.info_outline), label: Text(tr('nav_info'))),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE6E6E6)),
        ],

        Expanded(
          child: IndexedStack(index: _selectedIndex, children: _screens.map((w) => SafeArea(top: false, bottom: false, child: w)).toList()),
        ),
      ]),

      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.6)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: primaryGreen,
                  unselectedItemColor: Colors.black54,
                  showUnselectedLabels: true,
                  currentIndex: _selectedIndex,
                  onTap: _onNavSelected,
                  items: [
                    BottomNavigationBarItem(icon: const Icon(Icons.chat_outlined), label: tr('nav_chat')),
                    BottomNavigationBarItem(icon: const Icon(Icons.storefront), label: tr('nav_market')),
                    BottomNavigationBarItem(icon: const Icon(Icons.biotech), label: tr('nav_diagnose')),
                    BottomNavigationBarItem(icon: const Icon(Icons.groups_outlined), label: tr('nav_community')),
                    BottomNavigationBarItem(icon: const Icon(Icons.map_outlined), label: tr('nav_map')),
                    BottomNavigationBarItem(icon: const Icon(Icons.info_outline), label: tr('nav_info')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _notificationButton({required bool isMobile, required double iconSize}) {
    return Semantics(
      label: tr('notifications'),
      button: true,
      child: Stack(clipBehavior: Clip.none, children: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage())),
          icon: Icon(Icons.notifications_none, size: 28),
          color: Colors.white,
          tooltip: tr('notifications'),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              child: Text(notificationCount > 9 ? '9+' : notificationCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
      ]),
    );
  }

  Widget _buildAppDrawer(BuildContext context, {required bool isDesktop}) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      width: isDesktop ? 320 : 300,
      child: Container(
        color: const Color(0xFFF7FBF7),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 18),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [primaryGreen, lightGreen]), borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: SizedBox(width: 64, height: 64, child: _lastPickedImage != null ? Image.file(_lastPickedImage!, fit: BoxFit.cover) : (photoUrl != null ? Image.network(photoUrl, fit: BoxFit.cover) : const Icon(Icons.person, size: 36, color: primaryGreen))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.displayName ?? tr('default_user'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
            const SizedBox(height: 6),
            _drawerTile(icon: Icons.agriculture, label: tr('drawer_my_fields'), onTap: () => Navigator.pop(context)),
            _drawerTile(icon: Icons.cloud_download, label: tr('drawer_crop_care'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Cropcare()))),
            _drawerTile(icon: Icons.map, label: tr('drawer_field_map'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FieldMapScreen()))),
            _drawerTile(icon: Icons.forum, label: tr('drawer_community'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityPostPage()))),
            _drawerTile(icon: Icons.notifications, label: tr('drawer_notifications'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage()))),
            const Divider(),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8), child: Text(tr('useful'), style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w700))),
            _drawerTile(icon: Icons.help_outline, label: tr('drawer_tutorials'), onTap: () {}),
            _drawerTile(icon: Icons.card_giftcard, label: tr('drawer_rewards'), onTap: () {}),
            _drawerTile(icon: Icons.attach_money, label: tr('drawer_plans'), onTap: () {}),
            _drawerTile(icon: Icons.mail_outline, label: tr('drawer_contact_us'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsPage()))),
            const SizedBox(height: 20),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12), child: Column(children: [
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: Text(tr('sign_out')),
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 8),
            Text(tr('privacy_terms'), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _drawerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: primaryGreen),
      title: Text(label, style: const TextStyle(color: Color.fromARGB(255, 51, 74, 51), fontWeight: FontWeight.w600)),
      onTap: onTap,
      horizontalTitleGap: 6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 20,
    );
  }
}
