// lib/screens/contact_us_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// =======================================================
///  LAUNCH SERVICES (call / email / whatsapp / maps)
/// =======================================================
class LaunchServices {
  final BuildContext context;
  LaunchServices(this.context);

  void _showError(String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Unable to open $service"),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> launchCall(String phone) async {
    final Uri call = Uri(scheme: "tel", path: phone);
    try {
      if (!await launchUrl(call, mode: LaunchMode.externalApplication)) {
        _showError("Dialer");
      }
    } catch (_) {
      _showError("Dialer");
    }
  }

  Future<void> launchEmail(String to, {String subject = '', String body = ''}) async {
    final Uri email = Uri(
      scheme: "mailto",
      path: to,
      query: Uri(queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      }).query,
    );
    try {
      if (!await launchUrl(email, mode: LaunchMode.externalApplication)) {
        _showError("Email");
      }
    } catch (_) {
      _showError("Email");
    }
  }

  Future<void> launchWhatsapp(String phone, {String text = ''}) async {
    final Uri wa = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");
    try {
      if (!await launchUrl(wa, mode: LaunchMode.externalApplication)) {
        _showError("WhatsApp");
      }
    } catch (_) {
      _showError("WhatsApp");
    }
  }

  Future<void> launchMaps(String query) async {
    final Uri map = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    try {
      if (!await launchUrl(map, mode: LaunchMode.externalApplication)) {
        _showError("Maps");
      }
    } catch (_) {
      _showError("Maps");
    }
  }
}

/// =======================================================
///  CONTACT US PAGE (Green + White, friendly UI)
/// =======================================================
class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final LaunchServices launchServices;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final msgCtrl = TextEditingController();

  // Theme palette tuned for agriculture app
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color lightGreen = Color(0xFF74C043);
  static const Color canvas = Color(0xFFF4FBF4);
  static const Color cardWhite = Colors.white;
  static const Color muted = Color(0xFF6B6B6B);

  // Example contact values (replace with real ones)
  final String supportPhone = '+919999999999';
  final String supportWhatsapp = '918767258243';
  final String supportEmail = 'abccompany@gmail.com';
  final String supportLocationQuery = 'Qutb Minar, Delhi';

  @override
  void initState() {
    super.initState();
    launchServices = LaunchServices(context);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    msgCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // In a real app you'd send this to backend
      showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: primaryGreen),
              const SizedBox(width: 10),
              const Expanded(child: Text("Message Sent!", style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
          content: const Text("We’ll respond within 24 hours. Thank you!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dCtx);
                nameCtrl.clear();
                emailCtrl.clear();
                msgCtrl.clear();
              },
              child: Text("OK", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }

  Widget _quickAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 152,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 20, child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  "Tap to open",
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: cardWhite,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: Icon(icon, color: primaryGreen),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _socialButton(IconData icon, String url, Color color) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(40),
      child: CircleAvatar(radius: 26, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 22)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 760;
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 10),
            Text('CropCareAI', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Call support',
            onPressed: () => launchServices.launchCall(supportPhone),
            icon: const Icon(Icons.phone, color: Colors.white),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card with friendly intro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: lightGreen.withOpacity(0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.support_agent, color: lightGreen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Need help with your crop?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'Contact our support team — quick, friendly, and simple. Choose a contact method below or write to us.',
                          style: TextStyle(color: muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          Chip(
                            label: const Text('Support: 24h'),
                            avatar: const Icon(Icons.timer, size: 18),
                            backgroundColor: lightGreen.withOpacity(0.12),
                          ),
                          Chip(
                            label: const Text('Local advisors'),
                            avatar: const Icon(Icons.person_pin, size: 18),
                            backgroundColor: lightGreen.withOpacity(0.08),
                          ),
                          Chip(
                            label: const Text('Fast replies'),
                            avatar: const Icon(Icons.flash_on, size: 18),
                            backgroundColor: lightGreen.withOpacity(0.08),
                          ),
                        ])
                      ]),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Quick actions grid
              Text('Quick actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryGreen)),
              const SizedBox(height: 12),
              Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    _quickAction(
      label: "Call",
      icon: Icons.phone_rounded,
      color: primaryGreen,
      onTap: () => launchServices.launchCall(supportPhone),
    ),
    _quickAction(
      label: "WhatsApp",
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFF25D366),
      onTap: () => launchServices.launchWhatsapp(
        supportWhatsapp,
        text: 'Hello Support Team',
      ),
    ),
    _quickAction(
      label: "Email",
      icon: Icons.email_outlined,
      color: Colors.blue,
      onTap: () => launchServices.launchEmail(
        supportEmail,
        subject: 'Support request',
        body: '',
      ),
    ),
    _quickAction(
      label: "Location",
      icon: Icons.location_on_outlined,
      color: Colors.redAccent,
      onTap: () => launchServices.launchMaps(supportLocationQuery),
    ),
  ],
),

              const SizedBox(height: 28),

              // Form card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Write to us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryGreen)),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                       children: [
  _inputField(
    hint: "Full Name",
    icon: Icons.person_outline,
    ctrl: nameCtrl,
    validator: (String? v) {
      if (v == null || v.trim().length < 2) return "Enter name";
      return null;
    },
  ),
  const SizedBox(height: 12),

  _inputField(
    hint: "Email Address",
    icon: Icons.email_outlined,
    ctrl: emailCtrl,
    keyboardType: TextInputType.emailAddress,
    validator: (String? v) {
      if (v == null || !v.contains("@")) return "Enter valid email";
      return null;
    },
  ),
  const SizedBox(height: 12),

  _inputField(
    hint: "Your Message",
    icon: Icons.message_outlined,
    ctrl: msgCtrl,
    maxLines: 5,
    validator: (String? v) {
      if (v == null || v.trim().length < 8) return "Message too short";
      return null;
    },
  ),
  const SizedBox(height: 18),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    ),
  ),
],

                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Social follow row
              Center(child: Text('Follow us', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 16))),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _socialButton(Icons.facebook, 'https://facebook.com', Colors.blue),
                const SizedBox(width: 18),
                _socialButton(Icons.camera_alt, 'https://instagram.com', Colors.pink),
                const SizedBox(width: 18),
                _socialButton(Icons.play_circle_fill, 'https://youtube.com', Colors.red),
              ]),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
