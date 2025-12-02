// lib/screens/language_screen.dart
import 'dart:convert';
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

  Future<void> _initAll() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      // detect device locale
      deviceLocale = WidgetsBinding.instance.window.locale;

      await _loadLanguages();
      await _loadSavedLocale();

      // ensure at least one selectedCode
      selectedCode ??= 'en';
    } catch (e, st) {
      debugPrint('LanguageScreen._initAll error: $e\n$st');
      // fallback minimal data so UI still works
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

  /// Tries common locations for the JSON asset and parses it.
  Future<void> _loadLanguages() async {
    const candidates = [
      'assets/langs/languages.json', // your languages file
    ];

    String? raw;
    Object? lastError;

    for (final path in candidates) {
      try {
        raw = await rootBundle.loadString(path);
        if (raw.trim().isNotEmpty) {
          debugPrint('Loaded languages.json from: $path');
          break;
        } else {
          debugPrint('Asset found but empty: $path');
        }
      } catch (e) {
        debugPrint('Failed to load $path: $e');
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

    // show device language on top item if matched
    if (deviceLocale != null) {
      final idx = languages.indexWhere((l) => l["code"] == deviceLocale!.languageCode);
      if (idx != -1) {
        languages[0]["native"] = "Phone's language — ${languages[idx]['native']}";
      } else {
        languages[0]["native"] = "Phone's language — ${deviceLocale!.languageCode}";
      }
    }

    // done
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

    try {
      // toggle behavior: stop if same asset is playing
      if (_playingAsset == assetPath) {
        await _audioPlayer.stop();
        setState(() => _playingAsset = null);
        return;
      }

      await _audioPlayer.stop();
      // assetPath in JSON usually like "audio/en.mp3" (relative to assets/)
      await _audioPlayer.play(AssetSource(assetPath));
      setState(() => _playingAsset = assetPath);

      // clear when done
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _playingAsset = null);
      });
    } catch (e, st) {
      debugPrint('Audio play error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio')),
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
          // ignore if deviceLocale not supported by easy_localization
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
      const SnackBar(content: Text('Language saved')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleScreen()),
    );
  }

  Widget _buildLanguageTile(Map lang) {
    final code = lang['code'] as String?;
    final native = lang['native'] as String? ?? '';
    final audio = lang['audio'] as String?;
    final isSelected = selectedCode == code;
    final avatarText = (code ?? '').toUpperCase();
    final avatarLabel = avatarText.isNotEmpty && avatarText != 'PHONE' ? avatarText : 'A';
    final isPlaying = (_playingAsset != null && audio != null && _playingAsset == audio);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: isSelected ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? const Color(0xFF64DD17) : Colors.transparent,
            width: isSelected ? 1.8 : 0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onSelectLanguage(lang),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isSelected ? const Color(0xFFEFFFEF) : const Color(0xFFEEF8EE),
                  child: Text(
                    avatarLabel,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2E8B3A) : const Color(0xFF2E8B3A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        native,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF0B3A1B) : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        code ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // play button
                if (audio != null)
                  IconButton(
                    onPressed: () => _playAudio(audio),
                    tooltip: 'Play language name',
                    icon: isPlaying
                        ? const Icon(Icons.stop_circle_outlined, color: Color(0xFF2E8B3A))
                        : const Icon(Icons.volume_up_outlined, color: Color(0xFF2E8B3A)),
                  ),
                // check or radio
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF64DD17) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.circle_outlined,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed) {
      // show helpful retry UI
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load languages.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64DD17),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Title and short instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2E8B3A), Color(0xFF74C043)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Let's pick a language",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Choose the language you are most comfortable with. You can change this later in settings.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // White card with search + list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _searchText = v),
                              decoration: const InputDecoration(
                                hintText: 'Search language or code',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchText.isNotEmpty)
                            IconButton(
                              onPressed: () => setState(() => _searchText = ''),
                              icon: const Icon(Icons.clear, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // List
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No languages found', style: TextStyle(color: Colors.black54)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final lang = filtered[index] as Map;
                                return _buildLanguageTile(lang);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use a darker app background so the white content card stands out
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco, color: Color(0xFF2E8B3A), size: 22),
            SizedBox(width: 6),
            Text(
              "CropCareAI",
              style: TextStyle(
                color: Color(0xFF0B3A1B),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            )
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ElevatedButton.icon(
            onPressed: _onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}
