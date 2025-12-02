// lib/screens/role_screen.dart
import 'package:demo/main.dart';
import 'package:demo/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Retained for translation capability

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

  // ---------------- UI LOGIC ----------------

  void _onNext() {
    // Navigates using theme-aware dialogs/buttons
    final roleKey = selectedRole ?? 'farmer';

    if (roleKey == "farmer") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LandingScreen()));
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // For non-farmer roles: show theme-compliant confirmation then continue
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Role Selected', style: theme.textTheme.titleLarge),
        content: Text(
          'You selected "${_readableRoleLabel(roleKey)}". You can change this later in settings.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, // Use theme primary
              foregroundColor: colorScheme.onPrimary,
            ),
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

  // ---------------- UI BUILDERS ----------------

  Widget _buildRoleCard(BuildContext context, Map<String, String> role) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final key = role['key']!;
    final label = role['label']!;
    final desc = role['desc'] ?? '';
    final isSelected = selectedRole == key;

    // Determine colors based on selection state, using theme colors for vibrancy
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
          borderRadius: BorderRadius.circular(16), // Slightly larger radius
          side: BorderSide(color: isSelected ? primaryColor : Colors.transparent, width: 2.5), // Highlight border
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => selectedRole = key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Increased padding
            child: Row(
              children: [
                // Icon / avatar (Styled with modern gradient/fill)
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    // Use a gradient for selected state, solid surface for unselected
                    gradient: isSelected
                        ? LinearGradient(colors: [primaryColor, accentColor])
                        : null,
                    color: isSelected ? null : colorScheme.surfaceVariant, 
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : null,
                    // Subtle border even when unselected
                    border: Border.all(color: borderColor.withOpacity(0.5)), 
                  ),
                  child: Icon(
                    _iconForRole(key),
                    color: isSelected ? Colors.white : primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Title & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: textColor, // Use theme text color
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // selection indicator (Using theme colors for checkmark)
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
        return Icons.auto_graph; // Updated icon for modern feel
      case 'home_grower':
        return Icons.yard_outlined; // Updated icon for clarity
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
      // AppBar is flat and theme compliant
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
             Icon(Icons.eco, color: AgrioDemoApp.primaryGreen, size: 24),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header/Description Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  // Use primary/secondary theme colors for a dynamic gradient header
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tell us about yourself",
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Choose the role that best matches how you will use this app.",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Short helper text
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Selecting a role customizes your feed and tools.",
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.8)),
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
                    return _buildRoleCard(context, role);
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Sticky continue button
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
                Text('Continue', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}