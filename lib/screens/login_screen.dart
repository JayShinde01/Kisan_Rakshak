// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // close keyboard
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

      final user = cred.user;

      debugPrint("USER LOGGED IN:");
      debugPrint("uid = ${user?.uid}");
      debugPrint("email = ${user?.email}");
      debugPrint("verified = ${user?.emailVerified}");

      // mark not guest
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);

      // remember me behavior
      await _saveRememberMe(email);

      // Directly navigate (no email verification required)
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No account found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }
      _showError(message);
    } catch (e) {
      _showError('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _emailCtrl.text.trim());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty ||
                    !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid email'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _loading = true);

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Password reset email sent. Check your inbox.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String msg = 'Failed to send reset email.';
                  if (e.code == 'user-not-found') {
                    msg = 'No account found for that email.';
                  }
                  _showError(msg);
                } catch (_) {
                  _showError('Failed to send reset email.');
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: const Text('Send'),
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
          const SnackBar(content: Text('Google sign-in cancelled')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Google sign-in failed. ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skipAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);

    // optional: store a guest-start timestamp
    await prefs.setString('guest_started_at', DateTime.now().toIso8601String());

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home', arguments: {'guest': true});
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryGreen = Color(0xFF2E8B3A);
    const Color accentGreen = Color(0xFF74C043);
    const Color canvas = Color(0xFFF4F9F4);

    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primaryGreen, accentGreen]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.eco, color: primaryGreen, size: 26),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Welcome back — sign in',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // form card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Hint text
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Login to continue',
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Email field
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                label: Text('Email address'),
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Please enter email";
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 12),

                            // Password field
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                label: Text('Password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Enter your password";
                                }
                                if (v.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _login(),
                            ),

                            const SizedBox(height: 8),

                            // Remember + Forgot row
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: primaryGreen,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                ),
                                const SizedBox(width: 4),
                                const Expanded(child: Text('Remember me')),
                                TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: const Text('Forgot?'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // OR divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('OR', style: TextStyle(color: Colors.black54)),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Google button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _googleSignIn,
                                icon: Image.asset(
                                  'assets/images/google_logo.png',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.login, color: Colors.redAccent),
                                ),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Phone sign-in + guest
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // navigate to phone sign-in route - replace with your route
                                      Navigator.pushNamed(context, '/phone');
                                    },
                                    icon: const Icon(Icons.phone_android, color: Colors.black54),
                                    label: const Text('Sign in with phone'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextButton(
                                    onPressed: _skipAsGuest,
                                    child: const Text('Skip as Guest'),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Signup
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? "),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, "/signup");
                                  },
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Microcopy
                            const Text(
                              "We keep data private — used only to send alerts",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.black54),
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
