// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  final AuthService _authService = AuthService();

  // TTS
  late final FlutterTts _flutterTts;
  double _speechRate = 0.9; // adjust default

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    try {
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);

      // set language from app locale if possible
      final localeTag = _localeTagFromLocale(context.locale) ?? 'en-US';
      try {
        await _flutterTts.setLanguage(localeTag);
      } catch (_) {
        // ignore if not available
      }
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.stop();
      final localeTag = _localeTagFromLocale(context.locale) ?? 'en-US';
      try {
        await _flutterTts.setLanguage(localeTag);
      } catch (_) {}
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  String? _localeTagFromLocale(Locale? locale) {
    if (locale == null) return 'en-US';
    final code = locale.languageCode.toLowerCase();
    return _localeTagForLang(code);
  }

  String? _localeTagForLang(String? lang) {
    if (lang == null) return 'en-US';
    final code = lang.toLowerCase();
    const mapping = {
      'en': 'en-US',
      'hi': 'hi-IN',
      'mr': 'mr-IN',
      'bn': 'bn-IN',
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
    };
    if (mapping.containsKey(code)) return mapping[code];
    if (lang.contains('-') || lang.contains('_')) return lang;
    return 'en-US';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();

    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  // --- password strength ---
  int _passwordStrengthScore(String p) {
    int score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[\W_]').hasMatch(p)) score++;
    return score.clamp(0, 4);
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 0:
      case 1:
        return tr('strength_weak');
      case 2:
        return tr('strength_fair');
      case 3:
        return tr('strength_good');
      default:
        return tr('strength_strong');
    }
  }

  Color _strengthColor(int s, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (s) {
      case 0:
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return colorScheme.secondary;
      default:
        return colorScheme.primary;
    }
  }

  int _currentStrength = 0;

  void _onPasswordChanged() {
    final score = _passwordStrengthScore(_passwordCtrl.text);
    if (mounted) setState(() => _currentStrength = score);
  }

  // --- auth logic ---
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showError(tr('accept_terms_required'));
      return;
    }

    setState(() => _loading = true);

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final password = _passwordCtrl.text;

      final UserCredential cred = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone.isEmpty ? null : phone,
      );

      if (!mounted) return;
      _showSuccessAndNavigate(cred.user);
    } on FirebaseAuthException catch (e) {
      String message = tr('signup_failed_generic');
      if (e.code == 'email-already-in-use') {
        message = tr('email_already_in_use');
      } else if (e.code == 'weak-password') {
        message = tr('weak_password');
      } else if (e.code == 'invalid-email') {
        message = tr('invalid_email');
      }
      _showError(message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccessAndNavigate(User? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!mounted) return;

    // speak signup success (localized)
    final spoken = user == null ? tr('signup_success_tts_fallback') : tr('signup_success_tts', namedArgs: {'email': user.email ?? ''});
    _speakText(spoken);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('welcome'), style: theme.textTheme.titleLarge),
        content: Text(
          user == null ? tr('signup_success') : tr('signup_as_email', namedArgs: {'email': user.email ?? ''}),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(tr('continue'), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _loading = true);
    try {
      final cred = await _auth_service_signinGoogleWrapper();
      if (cred != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError(tr('google_signup_cancelled'));
      }
    } catch (e) {
      _showError(tr('google_signup_failed', namedArgs: {'msg': e.toString()}));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // keep original behavior to navigate to phone flow
  void _signupWithPhone() => Navigator.pushNamed(context, '/phone');

  void _onAvatarTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('avatar_picker_not_implemented'))),
    );
  }

  // helper wrapper so we avoid breaking existing AuthService signature call site
  Future<UserCredential?> _auth_service_signinGoogleWrapper() async {
    try {
      return await _authService.signInWithGoogle();
    } catch (_) {
      rethrow;
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: colorScheme.onBackground)),
        title: Text(tr('create_account'), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onBackground)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.onPrimary,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/Logo_App.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(tr('create_account_header'), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 18))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: _onAvatarTap,
                                  borderRadius: BorderRadius.circular(50),
                                  child: CircleAvatar(radius: 30, backgroundColor: colorScheme.surfaceVariant, child: Icon(Icons.camera_alt_outlined, color: colorScheme.primary)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameCtrl,
                                    focusNode: _nameFocus,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(labelText: tr('full_name'), prefixIcon: const Icon(Icons.person_outline)),
                                    style: theme.textTheme.bodyLarge,
                                    validator: (v) => (v == null || v.trim().length < 2) ? tr('please_enter_name') : null,
                                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(labelText: tr('email_address'), prefixIcon: const Icon(Icons.email_outlined)),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.trim().isEmpty) ? tr('please_enter_email') : (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()) ? tr('enter_valid_email') : null),
                              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _phoneCtrl,
                              focusNode: _phoneFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(labelText: tr('phone_number'), hintText: tr('phone_optional'), prefixIcon: const Icon(Icons.phone_outlined)),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v != null && v.isNotEmpty && v.replaceAll(RegExp(r'\D'), '').length < 8) ? tr('enter_valid_phone') : null,
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: tr('create_password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.length < 6) ? tr('password_min_chars') : null,
                              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (_currentStrength / 4).clamp(0.0, 1.0),
                                      child: Container(decoration: BoxDecoration(color: _strengthColor(_currentStrength, context), borderRadius: BorderRadius.circular(6))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_strengthLabel(_currentStrength), style: TextStyle(color: _strengthColor(_currentStrength, context), fontWeight: FontWeight.w700))
                              ],
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _confirmCtrl,
                              focusNode: _confirmFocus,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: tr('confirm_password'),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.isEmpty) ? tr('confirm_your_password') : (v != _passwordCtrl.text ? tr('passwords_not_match') : null),
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Checkbox(value: _acceptTerms, activeColor: colorScheme.primary, onChanged: (v) => setState(() => _acceptTerms = v ?? false)),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        text: tr('i_agree_prefix'),
                                        style: theme.textTheme.bodyMedium,
                                        children: [
                                          TextSpan(text: tr('terms_and_conditions'), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                                          TextSpan(text: ' ${tr('and')} '),
                                          TextSpan(text: tr('privacy_policy'), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
                                child: _loading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) : Text(tr('create_account_button'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(children: [Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.3))), Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Text(tr('or'), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500))), Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.3)))]),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _loading ? null : _signupWithGoogle,
                                    icon: Image.asset('assets/images/google_logo.jpg', width: 20, height: 20, errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary)),
                                    label: Text(tr('google')),
                                    style: OutlinedButton.styleFrom(backgroundColor: theme.brightness == Brightness.dark ? colorScheme.surfaceVariant : Colors.white, foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(tr('already_have_account'), style: theme.textTheme.bodyMedium), TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: Text(tr('log_in'), style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)))]),

                            const SizedBox(height: 6),
                            Text(tr('privacy_microcopy'), textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
