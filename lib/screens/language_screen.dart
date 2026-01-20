// lib/screens/language_screen.dart

import 'dart:convert';
import 'dart:math'; // Added for min function in avatar
import 'package:demo/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'role_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  List<dynamic> languages = [];
  String? selectedCode;
  Locale? deviceLocale;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _loading = true;
  bool _loadFailed = false;
  String? _playingAsset;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void dispose() {
    // Stop any audio or TTS and release resources
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // --- INIT & LOGIC (Kept identical as logic is robust) ---

  Future<void> _initAll() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      // Use platformDispatcher for better compatibility across platforms (web/desktop)
      deviceLocale = WidgetsBinding.instance.platformDispatcher.locale; 
      await _loadLanguages();
      await _loadSavedLocale();
      selectedCode ??= 'en';
    } catch (e, st) {
      debugPrint('LanguageScreen._initAll error: $e\n$st');
      languages = [
        // {"code": "phone", "native": tr('phone_language', namedArgs: {'name': 'English'}), "audio": null},
        {"code": "en", "native": "English", "audio": null},
      ];
      selectedCode ??= 'en';
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
      // Speak instructions after initial load (small delay for UI to settle)
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _speakInstructions();
      });
    }
  }

  Future<void> _loadLanguages() async {
    const candidates = ['assets/langs/languages.json'];
    String? raw;
    Object? lastError;

    for (final path in candidates) {
      try {
        raw = await rootBundle.loadString(path);
        if (raw.trim().isNotEmpty) {
          break;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (raw == null) {
      throw Exception('Could not load languages.json. Last error: $lastError');
    }

    final jsonData = jsonDecode(raw);
    final list = jsonData['languages'];
    if (list == null || list is! List) {
      throw Exception('languages.json missing "languages" array');
    }

    languages = [
      {"code": "phone", "native": tr('phone_language', namedArgs: {'name': '...'}), "audio": null},
      ...list,
    ];

    if (deviceLocale != null) {
      final idx = languages.indexWhere((l) => l["code"] == deviceLocale!.languageCode);
      if (idx != -1) {
        languages[0]["native"] = tr('phone_language', namedArgs: {'name': languages[idx]['native']});
      } else {
        languages[0]["native"] = tr('phone_language', namedArgs: {'name': deviceLocale!.languageCode});
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale_code');
    if (saved != null && saved.isNotEmpty) {
      selectedCode = saved;
    } else {
      selectedCode = 'en';
    }
  }

  Future<void> _saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', code);
  }

  Future<void> _playAudio(String? assetPath) async {
    if (assetPath == null) return;
    final colorScheme = Theme.of(context).colorScheme;

    try {
      // stop TTS if running
      await _flutterTts.stop();

      if (_playingAsset == assetPath) {
        await _audioPlayer.stop();
        setState(() => _playingAsset = null);
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
      setState(() => _playingAsset = assetPath);

      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _playingAsset = null);
      });
    } catch (e, st) {
      debugPrint('Audio play error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('could_not_play_audio')), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  void _onSelectLanguage(Map lang, {bool play = false}) {
    final code = lang['code'] as String?;
    final audio = lang['audio'] as String?;
    setState(() {
      selectedCode = code;
    });

    if (play) {
      if (audio != null) {
        _playAudio(audio);
      } else {
        // speak the language name using TTS
        final native = lang['native'] as String? ?? '';
        _speakText(native, langCode: code);
      }
    }
  }

  void _onNext() async {
    if (selectedCode == null) return;

    if (selectedCode == "phone") {
      if (deviceLocale != null) {
        try {
          context.setLocale(deviceLocale!);
        } catch (e) {
          context.setLocale(const Locale('en'));
        }
      } else {
        context.setLocale(const Locale('en'));
      }
    } else {
      try {
        context.setLocale(Locale(selectedCode!));
      } catch (_) {
        context.setLocale(const Locale('en'));
      }
    }

    await _saveLocale(selectedCode!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('language_saved', namedArgs: {'code': selectedCode!.toUpperCase()})),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    // stop TTS/audio before navigating
    await _flutterTts.stop();
    await _audioPlayer.stop();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleScreen()),
    );
  }

  /// Speak default instructions when the screen opens.
  Future<void> _speakInstructions() async {
    if (!mounted) return;

    // stop any currently playing audio
    await _audioPlayer.stop();

    final instructionText = tr(
      'instructions_language_screen',
      // fallback phrase if translation key missing:
      namedArgs: {'default': 'Please select your preferred language. Tap the play button to hear language names.'},
    );

    // if selected code is phone, try to get device locale tag else use selectedCode
    String? langCodeToUse;
    if (selectedCode == 'phone') {
      langCodeToUse = deviceLocale?.languageCode;
    } else {
      langCodeToUse = selectedCode;
    }

    await _speakText(instructionText, langCode: langCodeToUse);
  }

  /// Speak arbitrary text using flutter_tts. langCode is a short code like 'en' or 'hi'.
  Future<void> _speakText(String text, {String? langCode}) async {
    try {
      // Stop other audio
      await _audioPlayer.stop();

      // Map short lang code to TTS locale tag (best-effort)
      final localeTag = _localeTagForLang(langCode);

      if (localeTag != null) {
        // If setLanguage fails for a code on a platform it might throw, so wrap.
        try {
          await _flutterTts.setLanguage(localeTag);
        } catch (e) {
          debugPrint('TTS setLanguage failed for $localeTag: $e');
        }
      }

      // configure rate and pitch (you can tweak)
      try {
        await _flutterTts.setSpeechRate(0.45); // 0.0 - 1.0 (platform-specific)
        await _flutterTts.setPitch(1.0);
      } catch (_) {}

      await _flutterTts.speak(text);
    } catch (e, st) {
      debugPrint('TTS speak error: $e\n$st');
    }
  }

  /// Try to convert 'en' or 'hi' -> 'en-US', 'hi-IN', etc. Best-effort mapping.
  String? _localeTagForLang(String? lang) {
    if (lang == null) return 'en-US';

    final code = lang.toLowerCase();
    const mapping = {
      'en': 'en-US',
      'en_us': 'en-US',
      'en_gb': 'en-GB',
      'hi': 'hi-IN',
      'bn': 'bn-IN',
      'mr': 'mr-IN',
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
      // add more mappings as you need
    };

    if (mapping.containsKey(code)) return mapping[code];
    // If lang is already a full tag, return it
    if (lang.contains('-') || lang.contains('_')) return lang;
    return 'en-US';
  }

  // --- UI COMPONENTS (Theme-Compliant & Modernized) ---

Widget _buildLanguageTile(Map lang) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final media = MediaQuery.of(context);
  final isMobile = media.size.width < 600;

  final code = lang['code'] as String?;
  final native = lang['native'] as String? ?? '';
  final audio = lang['audio'] as String?;
  final isSelected = selectedCode == code;

  final avatarLabel =
      (code ?? '').toUpperCase().isNotEmpty && code != 'phone'
          ? code!.toUpperCase()
          : 'A';

  final isPlaying =
      (_playingAsset != null && audio != null && _playingAsset == audio);

  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    child: Card(
      elevation: isSelected ? 10 : 3,
      shadowColor:
          isSelected ? colorScheme.primary.withOpacity(0.4) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withOpacity(0.3),
          width: isSelected ? 2.2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        hoverColor: colorScheme.primary.withOpacity(0.04),
        splashColor: colorScheme.primary.withOpacity(0.12),
        onTap: () => _onSelectLanguage(lang),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 14 : 16,
            horizontal: isMobile ? 14 : 18,
          ),
          child: Row(
            children: [
              /// AVATAR
              Container(
                width: isMobile ? 44 : 48,
                height: isMobile ? 44 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [
                            colorScheme.primary,
                            colorScheme.secondary
                          ]
                        : [
                            colorScheme.surfaceVariant,
                            colorScheme.surfaceVariant
                          ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLabel.substring(
                      0, avatarLabel.length > 2 ? 2 : avatarLabel.length),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              /// TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      native,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurface.withOpacity(0.6),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              /// AUDIO / TTS BUTTON
              IconButton(
                onPressed: () {
                  if (audio != null) {
                    _onSelectLanguage(lang, play: true);
                  } else {
                    _speakText(native, langCode: code);
                  }
                },
                tooltip: tr('play_language_name'),
                iconSize: 24,
                splashRadius: 22,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isPlaying
                      ? Icon(
                          Icons.stop_circle_rounded,
                          key: const ValueKey('stop'),
                          color: colorScheme.secondary,
                        )
                      : Icon(
                          audio != null
                              ? Icons.volume_up_rounded
                              : Icons.record_voice_over_rounded,
                          key: const ValueKey('play'),
                          color: colorScheme.primary,
                        ),
                ),
              ),

              /// SELECTED INDICATOR
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('checked'),
                        color: colorScheme.primary,
                        size: 26,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('unchecked'),
                        color:
                            colorScheme.onSurface.withOpacity(0.35),
                        size: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  // --- BUILD BODY (Loading, Failed, Content) ---

  List<dynamic> _filteredLanguages() {
    if (_searchText.trim().isEmpty) return languages;
    final q = _searchText.toLowerCase().trim();
    return languages.where((l) {
      final native = (l['native'] ?? '').toString().toLowerCase();
      final code = (l['code'] ?? '').toString().toLowerCase();
      return native.contains(q) || code.contains(q);
    }).toList();
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('failed_load'), style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground.withOpacity(0.7))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('retry')),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredLanguages();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we are on a "wide" screen (Desktop/Web/Tablet)
        bool isWide = constraints.maxWidth > 600;
        
        // Calculate a safe padding that centers content on wide screens
        // Max content width on desktop
        double contentWidth = isWide ? 800 : constraints.maxWidth;
        // Padding to center
        double horizontalPadding = isWide ? (constraints.maxWidth - contentWidth) / 2 : 24;

        return Center( // Center content for extra large screens
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000), // Max constraint for ultra-wide monitors
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('lets_pick_language'),
                          style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('choose_language_instructions'),
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchText = v),
                            decoration: InputDecoration(
                              hintText: tr('search_hint'),
                              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (_searchText.isNotEmpty)
                          IconButton(
                            onPressed: () => setState(() => _searchText = ''),
                            icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.6)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text(tr('no_languages_found'), style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground.withOpacity(0.6))))
                        : isWide
                            // Grid View for Wide Screens
                            ? GridView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400, // Cards won't be wider than 400px
                                  mainAxisExtent: 100,     // Fixed height for cards
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final lang = filtered[index] as Map;
                                  return _buildLanguageTile(lang);
                                },
                              )
                            // List View for Mobile
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final lang = filtered[index] as Map;
                                  return _buildLanguageTile(lang);
                                },
                              ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Logo_App.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              tr('app_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.w700,
              ),
            )
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Constrain width of bottom button on desktop
            bool isWide = constraints.maxWidth > 600;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? (constraints.maxWidth - 400) / 2 : 24, 
                vertical: 16
              ),
              child: ElevatedButton.icon(
                onPressed: selectedCode == null || _loading ? null : _onNext,
                icon: const Icon(Icons.arrow_forward),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    tr('continue'),
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}