// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  // TTS related
  final FlutterTts _flutterTts = FlutterTts();
  double _speechRate = 0.50;
  static const String _prefsSpeechRateKey = 'speech_rate';

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // load persisted UI prefs first
    _loadRememberMe();
    _loadSpeechRate().then((_) {
      // After TTS is configured, speak a welcome message
      _speakWelcome();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    // stop and release TTS
    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  // -------------------- Remember me --------------------
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final rem = prefs.getBool('remember_me') ?? true;
    setState(() => _rememberMe = rem);

    if (_rememberMe) {
      final savedEmail = prefs.getString('saved_email') ?? '';
      _emailCtrl.text = savedEmail;
    }
  }

  Future<void> _saveRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('saved_email');
    }
  }

  // -------------------- TTS helpers --------------------
  Future<void> _loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsSpeechRateKey);
    if (saved != null) _speechRate = saved;

    // Apply to engine (best-effort)
    try {
      await _flutterTts.setSpeechRate(_speechRate);
      // Optionally set language to current app locale (best-effort)
      final langTag = _localeTagFromLocale(context.locale);
      if (langTag != null) {
        await _flutterTts.setLanguage(langTag);
      }
    } catch (_) {}
  }

  Future<void> _setSpeechRate(double rate, {bool persist = true}) async {
    _speechRate = rate;
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (_) {}
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsSpeechRateKey, _speechRate);
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
      'en_us': 'en-US',
      'en_gb': 'en-GB',
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

  Future<void> _speakText(String text, {String? langCode}) async {
    try {
      await _flutterTts.stop();
      final tag = langCode != null ? _localeTagForLang(langCode) : _localeTagFromLocale(context.locale);
      if (tag != null) {
        try {
          await _flutterTts.setLanguage(tag);
        } catch (_) {}
      }
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> _speakWelcome() async {
    final welcome = tr('welcome_back_tts', namedArgs: {'default': 'Welcome back! Please sign in or continue as guest.'});
    await _speakText(welcome);
  }

  void _showSpeechSpeedDialog() {
    double tempRate = _speechRate;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          title: Text(tr('speech_speed_title', namedArgs: {'default': 'Speech speed'})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('speech_speed_label', namedArgs: {'default': 'Adjust how fast the app speaks.'})),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(tr('slow', namedArgs: {'default': 'Slow'})),
                  Expanded(
                    child: Slider(
                      min: 0.3,
                      max: 1.2,
                      divisions: 9,
                      value: tempRate,
                      label: tempRate.toStringAsFixed(2),
                      onChanged: (v) {
                        setStateSB(() => tempRate = v);
                      },
                    ),
                  ),
                  Text(tr('fast', namedArgs: {'default': 'Fast'})),
                ],
              ),
              const SizedBox(height: 8),
              Text('${tr('current', namedArgs: {'default': 'Current:'})} ${tempRate.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
            ElevatedButton(
              onPressed: () async {
                await _setSpeechRate(tempRate, persist: true);
                // preview
                try {
                  await _flutterTts.stop();
                  await _speakText(tr('speech_speed_preview', namedArgs: {'default': 'This is a sample at the selected speed.'}));
                } catch (_) {}
                Navigator.pop(ctx);
              },
              child: Text(tr('save')),
            ),
          ],
        );
      }),
    );
  }

  // -------------------- Login / Auth actions --------------------
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      final UserCredential cred = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      // Successfully logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);

      await _saveRememberMe(email);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = tr('login_failed_generic');
      if (e.code == 'user-not-found') {
        message = tr('no_account_found');
      } else if (e.code == 'wrong-password') {
        message = tr('incorrect_password');
      } else if (e.code == 'invalid-email') {
        message = tr('invalid_email');
      } else if (e.code == 'user-disabled') {
        message = tr('account_disabled');
      }
      _showError(message);
    } catch (e) {
      _showError(tr('login_failed_generic'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emailController = TextEditingController(text: _emailCtrl.text.trim());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tr('reset_password_title'), style: theme.textTheme.titleLarge),
          content: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: tr('enter_email_hint'),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'), style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('enter_valid_email')),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _loading = true);

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('password_reset_sent')),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String msg = tr('password_reset_failed');
                  if (e.code == 'user-not-found') {
                    msg = tr('no_account_found');
                  }
                  _showError(msg);
                } catch (_) {
                  _showError(tr('password_reset_failed'));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: Text(tr('send'), style: TextStyle(color: colorScheme.secondary)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', false);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('google_signin_cancelled'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError(tr('google_signin_failed', namedArgs: {'msg': e.toString()}));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skipAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);

    await prefs.setString('guest_started_at', DateTime.now().toIso8601String());

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home', arguments: {'guest': true});
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header: Modern Gradient with TTS speed button ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
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
                              errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tr('welcome_back'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        // TTS speed button
                        IconButton(
                          tooltip: tr('speech_speed_tooltip', namedArgs: {'default': 'Speech speed'}),
                          onPressed: _showSpeechSpeedDialog,
                          icon: const Icon(Icons.speed_outlined),
                          color: colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Form Card ---
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(tr('login_to_continue'), style: theme.textTheme.titleMedium),
                            ),
                            const SizedBox(height: 20),

                            // Email field
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: tr('email_address'),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? tr('please_enter_email')
                                  : (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
                                      ? tr('enter_valid_email')
                                      : null),
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: tr('password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? tr('show_password') : tr('hide_password'),
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? tr('enter_password')
                                  : (v.length < 6 ? tr('password_min_length') : null),
                              onFieldSubmitted: (_) => _login(),
                            ),

                            const SizedBox(height: 8),

                            // Remember + Forgot row
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: colorScheme.primary,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                ),
                                const SizedBox(width: 4),
                                Expanded(child: Text(tr('remember_me'), style: theme.textTheme.bodyMedium)),
                                TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: Text(tr('forgot_password'), style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                ),
                                child: _loading
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                                    : Text(tr('login_button'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OR divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(tr('or'), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500)),
                                ),
                                Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.3))),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Google button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _googleSignIn,
                                icon: Image.asset(
                                  'assets/images/google_logo.jpg',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary),
                                ),
                                label: Text(tr('continue_with_google')),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: theme.brightness == Brightness.dark ? colorScheme.surfaceVariant : Colors.white,
                                  foregroundColor: colorScheme.onSurface,
                                  side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Skip as Guest
                            Row(
                              children: [
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: _skipAsGuest,
                                    child: Text(tr('skip_as_guest')),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Signup
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tr('dont_have_account'), style: theme.textTheme.bodyMedium),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, "/signup");
                                  },
                                  child: Text(tr('sign_up'), style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
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
