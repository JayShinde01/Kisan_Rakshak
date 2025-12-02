// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screens
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

// Theme manager
import 'package:demo/widgets/theme_manager.dart';

// --- MAIN FUNCTION REMAINS THE SAME ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    debugPrint('Firebase initialization error: $e\n$st');
  }

  // Load saved theme mode before building app
  await ThemeNotifier.init();

  runApp(const AgrioDemoApp());
}


class AgrioDemoApp extends StatelessWidget {
  const AgrioDemoApp({super.key});

  // 🌿 VIBRANT, FRESH AGRICULTURE COLOR PALETTE (Matched to Dark Screen Image)
  
  // PRIMARY COLOR: High-saturation Emerald Green (Used for light theme and primary highlight)
  static const Color primaryGreen = Color(0xFF00C853); 
  
  // LIGHT GREEN: Very Bright Accent Green (Used as Primary in Dark Theme for Pop)
  static const Color lightGreen = Color(0xFF69F0AE); 
  
  // SECONDARY/ACCENT: Bright Gold/Amber 
  static const Color accentYellow = Color.fromARGB(255, 154, 197, 27); 
  
  // LIGHT BACKGROUND: Crisp off-white
  static const Color paleBg = Color(0xFFF7FDF7); 
  
  // DARK BACKGROUND: Deep Near-Black (Matches the image background)
  static const Color darkBg = Color(0xFF0D0D0D); 
  
  // DARK SURFACE: Medium-Dark Grey (Matches the image's secondary buttons/surfaces)
  static const Color darkSurface = Color(0xFF1F1F1F); 


  // 🌳 LIGHT THEME (Retained for Day Mode)
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: accentYellow,
        surface: Colors.white,
        background: paleBg, 
        error: const Color(0xFFD32F2F),
      ),
      
      scaffoldBackgroundColor: paleBg,
      canvasColor: Colors.white,
      cardColor: Colors.white,

      // --- MODERN COMPONENT STYLING ---
      appBarTheme: AppBarTheme(
        centerTitle: false, 
        elevation: 0, 
        backgroundColor: Colors.white,
        foregroundColor: darkBg,
        titleTextStyle: TextStyle(
          color: darkBg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black12,
        elevation: 6.0, 
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen, 
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2), 
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentYellow, 
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: false, 
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paleBg, 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentYellow, width: 2.0),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: darkBg, fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: darkBg, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: darkBg, fontSize: 20, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: const TextStyle(color: Colors.black54, fontSize: 14),
        labelLarge: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🌑 DARK THEME (Matched to the provided image)
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: lightGreen, // Brighter green for primary actions (matches image)
        secondary: accentYellow,
        background: darkBg,
        surface: darkSurface,
        error: const Color(0xFFFFCC80),
      ),
      
      // Use the deep black/grey from the image
      scaffoldBackgroundColor: darkBg,
      canvasColor: darkBg,
      cardColor: darkSurface,

      // --- DARK COMPONENT STYLING ---
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: darkBg, // Match background for monolithic dark top
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface, // Secondary dark color for cards
        elevation: 8.0, 
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Use LightGreen (very bright) for elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightGreen, 
          foregroundColor: darkBg,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      // Use DarkSurface for secondary/outlined buttons (e.g., the 'Gallery' button)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: darkSurface, width: 2), // Match secondary dark color
          backgroundColor: darkSurface,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface, // Use the secondary dark color
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentYellow, width: 2.0)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightGreen, // Use primary green for FAB
        foregroundColor: darkBg,
        elevation: 8,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBg, // Match background
        selectedItemColor: lightGreen,
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: false,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: Colors.grey[200], fontSize: 16),
        bodyMedium: TextStyle(color: Colors.grey[300], fontSize: 14),
        labelLarge: const TextStyle(color: lightGreen, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- WIDGET BUILDER REMAINS THE SAME ---
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.notifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Crop AI',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: mode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                );
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
      },
    );
  }
}