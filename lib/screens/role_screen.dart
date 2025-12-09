// lib/screens/role_screen.dart
import 'package:demo/main.dart';
import 'package:demo/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String? selectedRole = "farmer";
  final FlutterTts _flutterTts = FlutterTts();

  /// use translation keys for labels/descriptions so they are localized
  final List<Map<String, String>> roles = [
    {
      "key": "agronomist",
      "labelKey": "role_agronomist_label",
      "descKey": "role_agronomist_desc"
    },
    {
      "key": "farmer",
      "labelKey": "role_farmer_label",
      "descKey": "role_farmer_desc"
    },
    {
      "key": "home_grower",
      "labelKey": "role_home_grower_label",
      "descKey": "role_home_grower_desc"
    },
  ];

  @override
  void initState() {
    super.initState();
    // small delay to allow UI to settle, then speak instructions
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _speakInstructions();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // ------------ TTS helpers ------------

  Future<void> _speakInstructions() async {
    final theme = Theme.of(context);
    // Use a translation key so instructions are localized where possible.
    final instruction = tr(
      'role_screen_instructions',
      namedArgs: {'default': 'Please select your role. Tap a card to choose and press Continue.'},
    );

    // Try to set language according to app locale (best-effort)
    final localeTag = _localeTagFromLocale(context.locale);
    try {
      if (localeTag != null) {
        await _flutterTts.setLanguage(localeTag);
      }
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(instruction);
    } catch (e) {
      debugPrint('TTS instruction error: $e');
    }
  }

  Future<void> _speakText(String text, {String? langCode}) async {
    try {
      await _flutterTts.stop();
      final tag = langCode != null ? _localeTagForLang(langCode) : _localeTagFromLocale(context.locale);
      if (tag != null) {
        try {
          await _flutterTts.setLanguage(tag);
        } catch (_) {}
      }
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Best-effort mapping from EasyLocalization Locale -> TTS locale tag
  String? _localeTagFromLocale(Locale? locale) {
    if (locale == null) return 'en-US';
    final code = locale.languageCode.toLowerCase();
    return _localeTagForLang(code);
  }

  /// Map short language code to a fuller locale tag for TTS engines
  String? _localeTagForLang(String? lang) {
    if (lang == null) return 'en-US';
    final code = lang.toLowerCase();
    const mapping = {
      'en': 'en-US',
      'en_us': 'en-US',
      'en_gb': 'en-GB',
      'hi': 'hi-IN',
      'mr': 'mr-IN',
      'bn': 'bn-IN',
      'gu': 'gu-IN',
      'kn': 'kn-IN',
      'ml': 'ml-IN',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'ur': 'ur-PK',
      'ar': 'ar-SA',
      'fr': 'fr-FR',
      'es': 'es-ES',
      'de': 'de-DE',
      'ru': 'ru-RU',
      'ja': 'ja-JP',
      'zh': 'zh-CN',
      'pt': 'pt-PT',
    };
    if (mapping.containsKey(code)) return mapping[code];
    if (lang.contains('-') || lang.contains('_')) return lang;
    return 'en-US';
  }

  // ---------------- UI LOGIC ----------------

  void _onNext() async {
    final roleKey = selectedRole ?? 'farmer';

    // stop any speaking before navigating or showing dialog
    await _flutterTts.stop();

    if (roleKey == "farmer") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LandingScreen()));
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('role_selected_title'), style: theme.textTheme.titleLarge),
        content: Text(
          tr('role_selected_content', namedArgs: {'role': _readableRoleLabel(roleKey)}),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(tr('cancel'), style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LandingScreen()));
            },
            child: Text(tr('continue')),
          ),
        ],
      ),
    );
  }

  String _readableRoleLabel(String key) {
    final match = roles.firstWhere((r) => r['key'] == key, orElse: () => roles[1]);
    final labelKey = match['labelKey'] ?? key;
    return tr(labelKey);
  }

  // ---------------- UI BUILDERS ----------------

  Widget _buildRoleCard(BuildContext context, Map<String, String> role) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final key = role['key']!;
    final label = tr(role['labelKey']!);
    final desc = tr(role['descKey']!);
    final isSelected = selectedRole == key;

    final primaryColor = colorScheme.primary;
    final accentColor = colorScheme.secondary;
    final iconColor = isSelected ? Colors.white : primaryColor;
    final borderColor = isSelected ? primaryColor : colorScheme.onSurface.withOpacity(0.2);
    final textColor = colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: theme.cardColor,
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? primaryColor : Colors.transparent, width: 2.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => selectedRole = key);
            // speak the role label when tapped
            _speakText(label, langCode: context.locale.languageCode);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(colors: [primaryColor, accentColor]) : null,
                    color: isSelected ? null : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : null,
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Icon(
                    _iconForRole(key),
                    color: isSelected ? Colors.white : primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? primaryColor : colorScheme.onSurface.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.radio_button_unchecked,
                    size: 16,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForRole(String key) {
    switch (key) {
      case 'agronomist':
        return Icons.auto_graph;
      case 'home_grower':
        return Icons.yard_outlined;
      default:
        return Icons.agriculture_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Logo_App.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 8),
            Text(
              tr('app_title'),
              style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.w700),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('tell_us_about_you_title'), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(tr('tell_us_about_you_subtitle'), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tr('select_role_info'), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.8)))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: roles.length,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    return _buildRoleCard(context, role);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward_ios, size: 16),
                const SizedBox(width: 10),
                Text(tr('continue'), style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
