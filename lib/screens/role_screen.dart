// lib/screens/role_screen.dart
import 'package:demo/screens/login_screen.dart';
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _speakInstructions();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakInstructions() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.speak(
        tr(
          'role_screen_instructions',
          namedArgs: {
            'default':
                'Please select your role. Tap a card to choose and press Continue.'
          },
        ),
      );
    } catch (_) {}
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  void _onNext() async {
    await _flutterTts.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  // ---------------- ROLE CARD ----------------

  Widget _buildRoleCard(BuildContext context, Map<String, String> role) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final key = role['key']!;
    final label = tr(role['labelKey']!);
    final desc = tr(role['descKey']!);
    final isSelected = selectedRole == key;

    return Card(
      elevation: isSelected ? 5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => selectedRole = key);
          _speakText(label);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [cs.primary, cs.secondary],
                        )
                      : null,
                  color: isSelected ? null : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForRole(key),
                  size: 28,
                  color: isSelected ? Colors.white : cs.primary,
                ),
              ),
              const SizedBox(width: 14),

              // TEXT — SAFE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : cs.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- MAIN BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          tr('app_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('tell_us_about_you_title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('tell_us_about_you_subtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔥 MOBILE = LIST | DESKTOP = GRID
                    Expanded(
                      child: isDesktop
                          ? GridView.builder(
                              itemCount: roles.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.4,
                              ),
                              itemBuilder: (context, index) =>
                                  _buildRoleCard(context, roles[index]),
                            )
                          : ListView.separated(
                              itemCount: roles.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildRoleCard(context, roles[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          onPressed: _onNext,
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          label: Text(
            tr('continue'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
