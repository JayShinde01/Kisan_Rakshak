// lib/screens/role_screen.dart
import 'package:demo/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String? selectedRole = "farmer";

  final List<Map<String, String>> roles = [
    {
      "key": "agronomist",
      "label": "Agronomist or Crop advisor",
      "desc": "Provide professional advice and view advanced tools."
    },
    {"key": "farmer", "label": "Farmer", "desc": "Manage your fields, get tips, and track crops."},
    {
      "key": "home_grower",
      "label": "Home grower or Gardener",
      "desc": "Small plots, home gardens — simple guidance and reminders."
    },
  ];

  void _onNext() {
    debugPrint("Selected role: $selectedRole");

    // For farmer we navigate to LandingScreen. For others show a small confirmation then navigate.
    final roleKey = selectedRole ?? 'farmer';

    if (roleKey == "farmer") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LandingScreen()));
      return;
    }

    // For non-farmer roles: show short info then continue to landing for now
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Role selected'),
        content: Text(
          'You selected "${_readableRoleLabel(roleKey)}". You can change this later in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B3A)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LandingScreen()));
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String _readableRoleLabel(String key) {
    final match = roles.firstWhere((r) => r['key'] == key, orElse: () => roles[1]);
    return match['label'] ?? key;
  }

  Widget _buildRoleCard(Map<String, String> role) {
    final key = role['key']!;
    final label = role['label']!;
    final desc = role['desc'] ?? '';
    final isSelected = selectedRole == key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: isSelected ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => selectedRole = key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon / avatar
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [Color(0xFF2E8B3A), Color(0xFF74C043)])
                        : const LinearGradient(colors: [Color(0xFFEFFFEF), Color(0xFFF2FFF2)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))] : null,
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                  ),
                  child: Icon(
                    _iconForRole(key),
                    color: isSelected ? Colors.white : const Color(0xFF2E8B3A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // Title & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF0B3A1B) : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // selection indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF64DD17) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.radio_button_unchecked,
                    size: 18,
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

  IconData _iconForRole(String key) {
    switch (key) {
      case 'agronomist':
        return Icons.school;
      case 'home_grower':
        return Icons.grass;
      default:
        return Icons.agriculture;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Friendly green background so the white cards pop
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E8B3A)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E8B3A), Color(0xFF74C043)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tell us about yourself",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Choose the role that best matches how you will use this app.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Card container with role list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    children: [
                      // Short helper text
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Color(0xFF2E8B3A)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Selecting a role lets us show features and tips designed for you. You can change this later.",
                                style: TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // List of role cards
                      Expanded(
                        child: ListView.builder(
                          itemCount: roles.length,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            return _buildRoleCard(role);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Sticky continue button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.arrow_forward, size: 18),
                SizedBox(width: 10),
                Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
