// lib/screens/landing_screen.dart
import 'package:demo/main.dart';
import 'package:demo/screens/diagnose_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Small helper to scale font sizes for smaller/larger devices
  double _scale(BuildContext c, double v) => v * MediaQuery.of(c).textScaleFactor;

  // help dialog (Updated to be theme compliant)
  void _showHelpDialog(BuildContext c) {
    final theme = Theme.of(c);
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('how_this_helps_title'), style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bulletItem(c, tr('help_bullet_1')),
            _bulletItem(c, tr('help_bullet_2')),
            _bulletItem(c, tr('help_bullet_3')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('close'), style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  // simple bullet item (Theme compliant)
  Widget _bulletItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            // Use theme primary color for bullet point
            child: CircleAvatar(radius: 5, backgroundColor: colorScheme.primary),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  // small helper for feature tiles (Theme compliant)
  Widget _featureTile(BuildContext context,
      {required IconData icon, required String titleKey, required String subtitleKey, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: '${tr(titleKey)}. ${tr(subtitleKey)}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Card(
            color: theme.cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(tr(titleKey), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(tr(subtitleKey),
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 640;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme background
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Hero / Header ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isWide ? 30 : 24, horizontal: 24),
              decoration: BoxDecoration(
                // Use theme primary and secondary colors for the vibrant gradient
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  // top row: logo + small help
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                           Image.asset(
                            'assets/images/Logo_App.png',
                            height: 40,
                            width: 40,
            ),
                          const SizedBox(width: 10),
                          Text(
                            tr('app_title'),
                            style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showHelpDialog(context),
                        icon: Icon(Icons.help_outline, color: colorScheme.onPrimary),
                        tooltip: tr('how_this_helps_hint'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Headline and subtitle
                  Text(
                    tr('hero_headline'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: _scale(context, isWide ? 30 : 24),
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('hero_subtitle'),
                    style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: _scale(context, 14)),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Primary CTAs
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => DiagnoseScreen(),));
                          },
                          icon: const Icon(Icons.camera_alt, color: Colors.black87),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              tr('identify_cta'),
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: _scale(context, 15)),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            // Use Secondary (Yellow/Amber) for high visibility
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to login for authenticated use
                            Navigator.pushNamed(context, '/login');
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 4, 150, 9),
                            foregroundColor: Colors.green,
                            side: BorderSide(color: colorScheme.onPrimary.withOpacity(0.5), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(tr('login'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.lightGreenAccent)),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. Features and Info Card ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  // IMPORTANT: make inner content scrollable
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Features grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              _featureTile(
                                context,
                                icon: Icons.chat_bubble_outline,
                                titleKey: 'ask_advice_title',
                                subtitleKey: 'ask_advice_sub',
                                color: colorScheme.primary,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('ask_advice_tapped')))),
                              ),
                              const SizedBox(width: 12),
                              _featureTile(
                                context,
                                icon: Icons.map_outlined,
                                titleKey: 'scan_field_title',
                                subtitleKey: 'scan_field_sub',
                                color: colorScheme.secondary,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('scan_field_tapped')))),
                              ),
                              const SizedBox(width: 12),
                              _featureTile(
                                context,
                                icon: Icons.book_outlined,
                                titleKey: 'manuals_title',
                                subtitleKey: 'manuals_sub',
                                color: colorScheme.error,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('manuals_tapped')))),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 40, indent: 20, endIndent: 20),

                        // Plain language quick help
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('how_this_helps_section'), style: theme.textTheme.titleLarge),
                              const SizedBox(height: 10),
                              _bulletItem(context, tr('quick_help_1')),
                              _bulletItem(context, tr('quick_help_2')),
                              _bulletItem(context, tr('quick_help_3')),
                              const SizedBox(height: 16),
                              Text(tr('tips_title'), style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              _bulletItem(context, tr('tip_1')),
                              _bulletItem(context, tr('tip_2')),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footnote & CTA
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr('footnote_text'),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  // Navigate to Home Screen for guest/unauthenticated use
                                  Navigator.pushNamed(context, '/home');
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: Text(tr('go_to_home')),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 3. Simple Footer Illustration ---
            SizedBox(
              height: 80,
              child: CustomPaint(
                painter: _SimpleFooterPainter(colorScheme.primary, colorScheme.secondary),
                size: Size(MediaQuery.of(context).size.width, 80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple footer painter: small rolling hills + wheat shapes (theme aware)
class _SimpleFooterPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _SimpleFooterPainter(this.primaryColor, this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hill (Theme Primary)
    final hillPaint = Paint()..color = primaryColor.withOpacity(0.85);
    final p = Path()
      ..moveTo(0, h * 0.9)
      ..quadraticBezierTo(w * 0.25, h * 0.75, w * 0.5, h * 0.9)
      ..quadraticBezierTo(w * 0.75, h * 1.05, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p, hillPaint);

    // Small wheat icons (Theme Accent)
    final stalkPaint = Paint()..color = accentColor.withOpacity(0.8);
    final grainPaint = Paint()..color = accentColor.withOpacity(0.9);

    for (int i = 0; i < 4; i++) {
      final x = w * (0.12 + i * 0.2);
      final baseY = h * 0.65;

      // Stalk
      canvas.drawRect(Rect.fromLTWH(x - 2, baseY - 24, 4, 24), stalkPaint);

      // Grains (small ovals around the top)
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 8, baseY - 18), width: 12, height: 8), grainPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 8, baseY - 30), width: 12, height: 8), grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Only repaint if colors change
    if (oldDelegate is _SimpleFooterPainter) {
      return oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
    }
    return true;
  }
}
