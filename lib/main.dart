// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/field_map_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/diagnose_screen.dart';
import 'screens/demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase initialization error: $e\n$st');
  }

  runApp(const AgrioDemoApp());
}

class AgrioDemoApp extends StatelessWidget {
  const AgrioDemoApp({super.key});

  // Palette
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color lightGreen = Color(0xFF74C043);
  static const Color paleGreen = Color(0xFFF2FBF4);
  static const Color offWhite = Color(0xFFF8F9F7);
  static const Color darkText = Color(0xFF0B3A1B);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: lightGreen,
        background: offWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      canvasColor: offWhite,
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),

      // Use CardThemeData for ThemeData.cardTheme (Material 3 / recent SDKs)
      cardTheme: const CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black26,
        elevation: 4.0,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: lightGreen, width: 1.6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        elevation: 8,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paleGreen,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGreen, width: 1.6),
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(color: darkText, fontSize: 28, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: darkText, fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: const TextStyle(color: Colors.black87, fontSize: 14),
        labelLarge: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop AI',
      theme: theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user != null) {
            return const HomeScreen();
          }
          return const LanguageScreen();
        },
      ),
     routes: {
  '/login': (_) => const LoginScreen(),
  '/signup': (_) => const SignupScreen(),
  '/home': (_) => const HomeScreen(),
  '/profile': (_) => const ProfileScreen(),
  '/landing': (_) => const LandingScreen(),
  '/fieldmap': (_) => const FieldMapScreen(),
  '/schedule': (_) => const ScheduleScreen(),
  '/diagnose': (_) => const DiagnoseScreen(),
  '/demo': (_) => const SatelliteScreen(),
},

      onUnknownRoute: (settings) => MaterialPageRoute(builder: (_) => const LanguageScreen()),
    );
  }
}
