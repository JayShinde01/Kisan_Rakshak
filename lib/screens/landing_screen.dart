// lib/screens/landing_screen.dart
import 'package:demo/main.dart';
import 'package:flutter/material.dart';

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
        title: Text('How CropCareAI helps', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bulletItem(c, 'Take a photo of a plant to identify pests or disease and get simple steps.'),
            _bulletItem(c, 'Ask Advice for quick tips like water, fertilizer, and timing.'),
            _bulletItem(c, 'Use Scan Field for larger checks and maps.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Close', style: TextStyle(color: theme.colorScheme.primary))),
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
      {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Card(
            color: theme.cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), // Increased padding
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)), textAlign: TextAlign.center),
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)), // More pronounced curve
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
                           Icon(Icons.eco, color: AgrioDemoApp.primaryGreen, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'CropCareAI',
                            style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showHelpDialog(context),
                        icon: Icon(Icons.help_outline, color: colorScheme.onPrimary),
                        tooltip: 'How this app helps you',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Headline and subtitle
                  Text(
                    'Smart, simple farming help',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: _scale(context, isWide ? 30 : 24),
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Point your camera at a plant and get plain-language advice — pests, disease, watering and next steps.',
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
                            // Navigate to Diagnose Screen
                            Navigator.pushNamed(context, '/diagnose');
                          },
                          icon: const Icon(Icons.camera_alt, color: Colors.black87),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Identify plant — take photo',
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Login', style: TextStyle(fontWeight: FontWeight.w700,color: Colors.lightGreenAccent)),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                            side: BorderSide(color: colorScheme.onPrimary.withOpacity(0.5), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                title: 'Ask Advice',
                                subtitle: 'Quick tips for your crop',
                                color: colorScheme.primary,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ask Advice tapped'))),
                              ),
                              const SizedBox(width: 12),
                              _featureTile(
                                context,
                                icon: Icons.map_outlined,
                                title: 'Scan Field',
                                subtitle: 'Map and area checks',
                                color: colorScheme.secondary,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan Field tapped'))),
                              ),
                              const SizedBox(width: 12),
                              _featureTile(
                                context,
                                icon: Icons.book_outlined,
                                title: 'Manuals',
                                subtitle: 'Step-by-step guides',
                                color: colorScheme.error,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manuals tapped'))),
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
                              Text('How this helps you', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 10),
                              _bulletItem(context, 'Identify problems quickly — get simple next steps you can follow.'),
                              _bulletItem(context, 'Learn how much to water, when to spray, and how to care for your crop.'),
                              _bulletItem(context, 'Save and track fields, so you know what worked and when.'),
                              const SizedBox(height: 16),
                              Text('Tips for best results', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              _bulletItem(context, 'Take photos in daylight and include leaves and stems.'),
                              _bulletItem(context, 'If you have many fields, give them names like "North field" or "Plot A".'),
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
                                  'Don\'t worry — the app gives simple steps. Consult a local expert if unsure.',
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
                                child: const Text('Go to Home'),
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