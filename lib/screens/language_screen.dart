// lib/screens/language_screen.dart

import 'dart:convert';
import 'package:demo/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
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
  bool _loading = true;
  bool _loadFailed = false;
  String? _playingAsset;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  // --- INIT & LOGIC (Kept identical as logic is robust) ---

  Future<void> _initAll() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      deviceLocale = WidgetsBinding.instance.window.locale;
      await _loadLanguages();
      await _loadSavedLocale();
      selectedCode ??= 'en';
    } catch (e, st) {
      debugPrint('LanguageScreen._initAll error: $e\n$st');
      languages = [
        {"code": "phone", "native": "Phone's language — English", "audio": null},
        {"code": "en", "native": "English", "audio": null},
      ];
      selectedCode ??= 'en';
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
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
      {"code": "phone", "native": "Phone's language", "audio": null},
      ...list,
    ];

    if (deviceLocale != null) {
      final idx = languages.indexWhere((l) => l["code"] == deviceLocale!.languageCode);
      if (idx != -1) {
        languages[0]["native"] = "Phone's language — ${languages[idx]['native']}";
      } else {
        languages[0]["native"] = "Phone's language — ${deviceLocale!.languageCode}";
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
          SnackBar(content: const Text('Could not play audio'), backgroundColor: colorScheme.error),
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

    if (play && audio != null) {
      _playAudio(audio);
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
      SnackBar(content: Text('Language saved to ${selectedCode!.toUpperCase()}'), backgroundColor: Theme.of(context).colorScheme.primary),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleScreen()),
    );
  }

  // --- UI COMPONENTS (Theme-Compliant & Modernized) ---

  Widget _buildLanguageTile(Map lang) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final code = lang['code'] as String?;
    final native = lang['native'] as String? ?? '';
    final audio = lang['audio'] as String?;
    final isSelected = selectedCode == code;
    final avatarLabel = (code ?? '').toUpperCase().isNotEmpty && code != 'phone' ? (code ?? '').toUpperCase() : 'A';
    final isPlaying = (_playingAsset != null && audio != null && _playingAsset == audio);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        color: theme.cardColor,
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Vibrant border highlight using Primary color
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onSelectLanguage(lang),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                // Avatar/Initial
                CircleAvatar(
                  radius: 24,
                  // Use SurfaceVariant for soft background, Primary for text
                  backgroundColor: colorScheme.surfaceVariant, 
                  child: Text(
                    avatarLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Language Name & Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        native,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        code ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Play Button (Theme Compliant)
                if (audio != null)
                  IconButton(
                    onPressed: () => _onSelectLanguage(lang, play: true),
                    tooltip: 'Play language name',
                    icon: isPlaying
                        ? Icon(Icons.stop_circle_outlined, color: colorScheme.secondary)
                        : Icon(Icons.volume_up_outlined, color: colorScheme.primary),
                  ),
                
                // Selection Indicator
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 24,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
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
            Text('Failed to load languages.', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground.withOpacity(0.7))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredLanguages();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Title and short instructions (Vibrant Gradient Header)
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
                    "Let's pick a language",
                    style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Choose the language you are most comfortable with. You can change this later in settings.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search bar (Modernized)
            Container(
              decoration: BoxDecoration(
                // Use subtle surface color for search background
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
                        hintText: 'Search language or code',
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

            // Language List
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No languages found', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground.withOpacity(0.6))))
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Minimal App Bar (Theme Compliant)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon( Icons.eco, color: AgrioDemoApp.primaryGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              "CropCareAI",
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.w700,
              ),
            )
          ],
        ),
      ),
      body: _buildBody(),
      
      // Sticky Continue Button (Theme Compliant)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ElevatedButton.icon(
            onPressed: selectedCode == null || _loading ? null : _onNext,
            icon: const Icon(Icons.arrow_forward),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Continue',
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
        ),
      ),
    );
  }
}