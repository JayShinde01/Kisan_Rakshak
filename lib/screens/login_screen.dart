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
    _loadRememberMe();
    _loadSpeechRate().then((_) {
      _speakWelcome();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

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

    try {
      await _flutterTts.setSpeechRate(_speechRate);
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              child: Text(tr('send'), style: TextStyle(color: colorScheme.primary)),
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

  // -------------------- UI Builder --------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Common Input Decoration for consistency and better look
    InputDecoration inputDecoration(String label, IconData icon, {Widget? suffix}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
        suffixIcon: suffix,
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if we are on a desktop/tablet screen
          final bool isWideScreen = constraints.maxWidth > 600;
          
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                // Adaptive padding: Less on mobile, more on desktop
                horizontal: isWideScreen ? 0 : 24, 
                vertical: 24
              ),
              child: ConstrainedBox(
                // Constraint width for Desktop view
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    // --- Header Section ---
                    Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                              ]
                            ),
                            child: CircleAvatar(
                              radius: 32, // Larger logo
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Logo_App.png',
                                  height: 64,
                                  width: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary, size: 32),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('welcome_back'),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('login_to_continue'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _showSpeechSpeedDialog,
                            icon: const Icon(Icons.speed_rounded, color: Colors.white),
                            tooltip: tr('speech_speed_tooltip', namedArgs: {'default': 'Speech speed'}),
                          ),
                        ],
                      ),
                    ),

                    // --- Form Section ---
                    Card(
                      elevation: isWideScreen ? 4 : 0, // Flat on mobile, shadow on desktop
                      color: isWideScreen ? theme.cardColor : Colors.transparent, // Transparent bg on mobile
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: isWideScreen ? const EdgeInsets.all(32) : EdgeInsets.zero,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              
                              // Email Field
                              TextFormField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                style: theme.textTheme.bodyLarge,
                                decoration: inputDecoration(tr('email_address'), Icons.email_outlined),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? tr('please_enter_email')
                                    : (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v) ? tr('enter_valid_email') : null),
                                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                              ),
                              
                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                style: theme.textTheme.bodyLarge,
                                decoration: inputDecoration(
                                  tr('password'), 
                                  Icons.lock_outline,
                                  suffix: IconButton(
                                    tooltip: _obscurePassword ? tr('show_password') : tr('hide_password'),
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? tr('enter_password')
                                    : (v.length < 6 ? tr('password_min_length') : null),
                                onFieldSubmitted: (_) => _login(),
                              ),

                              const SizedBox(height: 12),

                              // Remember Me & Forgot Password
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: colorScheme.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                                      child: Text(tr('remember_me'), style: theme.textTheme.bodyMedium),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _loading ? null : _forgotPassword,
                                    child: Text(tr('forgot_password'), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Login Button
                              SizedBox(
                                height: 56, // Taller button
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 4,
                                    shadowColor: colorScheme.primary.withOpacity(0.4),
                                  ),
                                  child: _loading
                                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.onPrimary))
                                      : Text(tr('login_button'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(tr('or'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                  ),
                                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Google Button
                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: _loading ? null : _googleSignIn,
                                  icon: Image.asset(
                                    'assets/images/google_logo.jpg',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary),
                                  ),
                                  label: Text(tr('continue_with_google')),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: theme.canvasColor,
                                    foregroundColor: colorScheme.onSurface,
                                    side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Skip / Sign Up Actions
                              Column(
                                children: [
                                  TextButton(
                                    onPressed: _skipAsGuest,
                                    child: Text(tr('skip_as_guest'), style: TextStyle(color: colorScheme.primary, fontSize: 15, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(tr('dont_have_account'), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                                      TextButton(
                                        onPressed: () => Navigator.pushReplacementNamed(context, "/signup"),
                                        child: Text(tr('sign_up'), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                    ],
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
          );
        },
      ),
    );
  }
}