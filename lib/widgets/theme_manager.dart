// lib/widgets/theme_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⚙️ Theme Notifier Logic (The functionality remains the same)

class ThemeNotifier {
  static const _prefKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.system);

  /// Initialize (load saved mode)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefKey) ?? 'system';
    notifier.value = _stringToMode(s);
  }

  static ThemeMode _stringToMode(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      default: return 'system';
    }
  }

  /// Set and persist
  static Future<void> setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _modeToString(mode));
    notifier.value = mode;
  }

  /// Convenience toggle (cycles system -> light -> dark -> system)
  static Future<void> cycle() async {
    final current = notifier.value;
    final next = current == ThemeMode.system
        ? ThemeMode.light
        : current == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.system;
    await setMode(next);
  }
}

// 🔆 Modern Theme Toggle Widget (Improved)

/// Small widget you can put in an AppBar to cycle theme modes.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  // Use more visually engaging icons for better UI
  IconData _iconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny_outlined; // Brighter Sun
      case ThemeMode.dark:
        return Icons.nightlight_round; // Engaging Moon
      default:
        return Icons.brightness_auto_outlined; // Auto Brightness
    }
  }

  String _labelForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.notifier,
      builder: (context, mode, _) {
        return IconButton(
          tooltip: 'Theme: ${_labelForMode(mode)} (tap to cycle)',
          onPressed: () => ThemeNotifier.cycle(),
          // Use AnimatedSwitcher for a smooth, modern icon transition
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            // Use a simple scale transition
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child); 
            },
            child: Icon(
              _iconForMode(mode),
              // Key is crucial for AnimatedSwitcher to detect the icon change
              key: ValueKey<ThemeMode>(mode), 
              // Attractive Color Combination: Use the primary color from the active theme
              color: Theme.of(context).colorScheme.primary, 
            ),
          ),
        );
      },
    );
  }
}