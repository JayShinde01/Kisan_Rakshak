// lib/api_config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web always runs on PC browser → use localhost
      return "https://kisan-rakshak-mlbackend.onrender.com";
    }

    // For mobile / desktop (not web)
    if (Platform.isAndroid) {
      // Detect: Emulator or Physical Device
      return _isEmulator ? "https://kisan-rakshak-mlbackend.onrender.com"     // Android Emulator
                         : "https://kisan-rakshak-mlbackend.onrender.com"; // ✔ Physical Android Device on same WiFi
    }

    // iOS Simulator / mac / windows → localhost
    return "http://localhost:5000";
  }

  // -------- Emulator Detector (Android Only) ----------
  static bool get _isEmulator {
    // These checks detect emulator characteristics
    const possibleEmulatorIndicators = [
      "google_sdk",
      "sdk_gphone",
      "sdk",
      "emulator",
      "x86",
    ];

    final model = Platform.environment['ANDROID_EMULATOR_ENV'] ?? "";
    return possibleEmulatorIndicators.any((e) => model.toLowerCase().contains(e));
  }
}
