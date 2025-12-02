// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Small helper to scale font sizes for smaller/larger devices
  double _scale(BuildContext c, double v) => v * MediaQuery.of(c).textScaleFactor;

  @override
  Widget build(BuildContext context) {
    // Palette
    const Color primary = Color(0xFF2E8B3A);
    const Color accent = Color(0xFF74C043);
    const Color canvas = Color(0xFFF4F9F4);
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 640;

    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Hero / header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isWide ? 28 : 22, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [primary, accent]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  // top row: logo + small help
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.eco, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'CropCareAI',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showHelpDialog(context),
                        icon: const Icon(Icons.help_outline, color: Colors.white),
                        tooltip: 'How this app helps you',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Headline and subtitle
                  Text(
                    'Smart, simple farming help',
                    style: TextStyle(
                      fontSize: _scale(context, isWide ? 28 : 22),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point your camera at a plant and get plain-language advice — pests, disease, watering and next steps.',
                    style: TextStyle(color: Colors.white70, fontSize: _scale(context, 14)),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  // Primary CTAs
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: wire to camera flow
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Take Photo tapped')));
                          },
                          icon: const Icon(Icons.camera_alt, color: Colors.black),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Identify plant — take photo',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: _scale(context, 15)),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: upload flow
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload tapped')));
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Upload', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // White card area with scrollable features and content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                  ),

                  // IMPORTANT: make inner content scrollable to avoid RenderFlex overflow
                  child: SingleChildScrollView(
                    // physics: BouncingScrollPhysics(), // optional
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Features grid (three tiles)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              _featureTile(
                                context,
                                icon: Icons.chat_bubble_outline,
                                title: 'Ask Advice',
                                subtitle: 'Quick tips for your crop',
                                color: primary,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ask Advice tapped'))),
                              ),
                              const SizedBox(width: 10),
                              _featureTile(
                                context,
                                icon: Icons.map_outlined,
                                title: 'Scan Field',
                                subtitle: 'Map and area checks',
                                color: Colors.green,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan Field tapped'))),
                              ),
                              const SizedBox(width: 10),
                              _featureTile(
                                context,
                                icon: Icons.book_outlined,
                                title: 'Manuals',
                                subtitle: 'Step-by-step guides',
                                color: Colors.orange,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manuals tapped'))),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // Plain language quick help
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('How this helps you', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              _bulletItem('Identify problems quickly — get simple next steps you can follow.'),
                              _bulletItem('Learn how much to water, when to spray, and how to care for your crop.'),
                              _bulletItem('Save and track fields, so you know what worked and when.'),
                              const SizedBox(height: 12),
                              const Text('Tips for best results', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              _bulletItem('Take photos in daylight and include leaves and stems.'),
                              _bulletItem('If you have many fields, give them names like "North field" or "Plot A".'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // small footnote + CTA row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Don\'t worry — the app gives simple steps. If unsure, ask a neighbor or use our manuals.',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),

                        // add a small bottom padding so content doesn't touch the rounded corner
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom illustration (small) — decorative only
            SizedBox(
              height: 80,
              child: CustomPaint(
                painter: _SimpleFooterPainter(),
                size: Size(MediaQuery.of(context).size.width, 80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // small helper for feature tiles
  Widget _featureTile(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // simple bullet item
  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: CircleAvatar(radius: 5, backgroundColor: Color(0xFF2E8B3A)),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // help dialog
  void _showHelpDialog(BuildContext c) {
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('How CropCareAI helps'),
        content: const Text(
          '1) Take a photo of a plant to identify pests or disease and get simple steps.\n\n'
          '2) Ask Advice for quick tips like water, fertilizer, and timing.\n\n'
          '3) Use Scan Field for larger checks and maps.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
        ],
      ),
    );
  }
}

// Simple footer painter: small rolling hills + wheat shapes (pure decoration)
class _SimpleFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hillPaint = Paint()..color = const Color(0xFF2E8B3A).withOpacity(0.95);
    final p = Path()
      ..moveTo(0, h * 0.9)
      ..quadraticBezierTo(w * 0.25, h * 0.75, w * 0.5, h * 0.9)
      ..quadraticBezierTo(w * 0.75, h * 1.05, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p, hillPaint);

    // small wheat icons
    final stalkPaint = Paint()..color = Colors.amber.shade600;
    for (int i = 0; i < 4; i++) {
      final x = w * (0.12 + i * 0.2);
      final baseY = h * 0.65;
      canvas.drawRect(Rect.fromLTWH(x - 2, baseY - 24, 4, 24), stalkPaint);
      final grainPaint = Paint()..color = Colors.amber.shade400;
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 8, baseY - 18), width: 12, height: 8), grainPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 8, baseY - 30), width: 12, height: 8), grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
