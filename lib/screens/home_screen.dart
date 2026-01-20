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
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------- COLORS ----------------
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color lightGreen = Color(0xFF74C043);
  static const Color offWhite = Color(0xFFF4F9F4);

  // ---------------- NAV ----------------
  int _selectedIndex = 0;
  int notificationCount = 9;

  final List<Widget> _screens = const [
    HomeContent(),
    MarketplacePage(),
    DiagnoseScreen(),
    CommunityPostPage(),
    FieldMapScreen(),
    Cropcare(),
  ];

  // ---------------- TTS ----------------
  late final FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _ttsMuted = false;

  static const String _prefsSpeechRateKey = 'speech_rate';
  static const String _prefsTtsMutedKey = 'tts_muted';

  double _speechRate = 0.9;

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
    _loadTtsMute();
    _initTts().then((_) => _speakOnOpen());
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // ---------------- AUTH ----------------
  Future<void> _checkLoggedIn() async {
    if (FirebaseAuth.instance.currentUser == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ---------------- TTS CORE ----------------
  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble(_prefsSpeechRateKey) ?? _speechRate;

    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setCancelHandler(() => setState(() => _isSpeaking = false));

    try {
      await _flutterTts.setLanguage(_localeTagFromLocale(context.locale)!);
    } catch (_) {}
  }

  String? _localeTagFromLocale(Locale? locale) {
    if (locale == null) return 'en-US';
    const map = {
      'en': 'en-US',
      'hi': 'hi-IN',
      'mr': 'mr-IN',
      'gu': 'gu-IN',
      'pa': 'pa-IN',
    };
    return map[locale.languageCode] ?? 'en-US';
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty || _ttsMuted) return;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _speakOnOpen() async {
    await _speakText(
      tr('welcome_home_tts', namedArgs: {'app': tr('app_title')}),
    );
  }

  // ---------------- TTS MUTE ----------------
  Future<void> _loadTtsMute() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ttsMuted = prefs.getBool(_prefsTtsMutedKey) ?? false;
    });
  }

  Future<void> _toggleTtsMute() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _ttsMuted = !_ttsMuted);

    await prefs.setBool(_prefsTtsMutedKey, _ttsMuted);

    if (_ttsMuted) {
      await _flutterTts.stop();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _ttsMuted
              ? tr('voice_muted', namedArgs: {'default': 'Voice instructions muted'})
              : tr('voice_unmuted', namedArgs: {'default': 'Voice instructions enabled'}),
        ),
      ),
    );
  }

  // ---------------- NAV HANDLER ----------------
  void _onNavSelected(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) {
      _speakText(tr('opening_diagnose_tts'));
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: offWhite,
      drawer: _buildDrawer(isDesktop),
      appBar: _buildAppBar(isMobile),
      body: Row(
  children: [
    if (isDesktop) _buildRail(),
    Expanded(
      child: isDesktop
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            )
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
    ),
  ],
),

      floatingActionButton: !_ttsMuted && _isSpeaking
          ? FloatingActionButton.small(
              backgroundColor: Colors.redAccent,
              tooltip: tr('mute_voice'),
              onPressed: _toggleTtsMute,
              child: const Icon(Icons.volume_off),
            )
          : null,
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  // ---------------- APP BAR ----------------
  AppBar _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: primaryGreen,
      elevation: 2,
      title: Text(tr('app_title')),
      actions: [
        IconButton(
          tooltip: _ttsMuted
              ? tr('unmute_voice', namedArgs: {'default': 'Enable voice instructions'})
              : tr('mute_voice', namedArgs: {'default': 'Mute voice instructions'}),
          icon: Icon(_ttsMuted ? Icons.volume_off : Icons.volume_up),
          onPressed: _toggleTtsMute,
        ),
        const ThemeToggleButton(),
        IconButton(
          tooltip: tr('schedule'),
          icon: const Icon(Icons.event_note_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScheduleScreen()),
          ),
        ),
        _notificationButton(),
      ],
    );
  }

  // ---------------- NAV UI ----------------
  Widget _buildRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onNavSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(icon: Icon(Icons.home_filled), label: Text(tr('nav_chat'))),
        NavigationRailDestination(icon: Icon(Icons.store), label: Text(tr('nav_market'))),
        NavigationRailDestination(icon: Icon(Icons.biotech), label: Text(tr('nav_diagnose'))),
        NavigationRailDestination(icon: Icon(Icons.groups), label: Text(tr('nav_community'))),
        NavigationRailDestination(icon: Icon(Icons.map), label: Text(tr('nav_map'))),
        NavigationRailDestination(icon: Icon(Icons.info), label: Text(tr('nav_info'))),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryGreen,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: tr('nav_chat')),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: tr('nav_market')),
        BottomNavigationBarItem(icon: Icon(Icons.biotech), label: tr('nav_diagnose')),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: tr('nav_community')),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: tr('nav_map')),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: tr('nav_info')),
      ],
    );
  }

  // ---------------- NOTIFICATION ----------------
  Widget _notificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotificationPage()),
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text(
                notificationCount > 9 ? '9+' : '$notificationCount',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------- DRAWER ----------------
 Widget _buildDrawer(bool isDesktop) {
  final user = FirebaseAuth.instance.currentUser;

  return Drawer(
    width: isDesktop ? 320 : null,
    child: Column(
      children: [
    InkWell(
  onTap: () {
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, '/profile');
    // OR
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  },
  child: UserAccountsDrawerHeader(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [primaryGreen, lightGreen]),
    ),
    accountName: Text(user?.displayName ?? tr('default_user')),
    accountEmail: Text(user?.email ?? ''),
    currentAccountPicture: const CircleAvatar(
      child: Icon(Icons.person),
    ),
  ),
),


        _drawerTile(Icons.agriculture, tr('drawer_my_fields'), () {}),

        _drawerTile(Icons.cloud, tr('drawer_crop_care'), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Cropcare()),
          );
        }),

        _drawerTile(Icons.map, tr('drawer_field_map'), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FieldMapScreen()),
          );
        }),

        _drawerTile(Icons.group, tr('drawer_community'), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CommunityPostPage()),
          );
        }),

        _drawerTile(Icons.mail, tr('drawer_contact_us'), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContactUsPage()),
          );
        }),

        // 🔹 DIVIDER
        const Divider(),

        // 🌐 CHANGE LANGUAGE OPTION
        _drawerTile(Icons.language, tr('change_language'), () {
          Navigator.pop(context); // close drawer
          Navigator.pushNamed(context, '/language');
          // OR if using direct screen:
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
        }),

        const Spacer(),

        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(tr('sign_out')),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}

  Widget _drawerTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryGreen),
      title: Text(label),
      onTap: onTap,
    );
  }
}
