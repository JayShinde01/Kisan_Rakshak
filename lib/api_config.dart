// lib/api_config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000"; // Web browser
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000"; // Android emulator
    } else {
      return "http://localhost:5000"; // Windows/Mac/Linux
    }
  }
}