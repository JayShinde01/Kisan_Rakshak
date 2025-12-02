// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
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
    super.dispose();
  }

  // Simple password strength estimator (returns 0..4)
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
        return 'Very weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 0:
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.lightGreen;
      default:
        return const Color(0xFF2E8B3A);
    }
  }

  int _currentStrength = 0;

  void _onPasswordChanged() {
    final score = _passwordStrengthScore(_passwordCtrl.text);
    if (mounted) setState(() => _currentStrength = score);
  }

  Future<void> _submit() async {
    // close keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showError('Please accept Terms & Conditions to continue.');
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
      // Use specific messages if available
      String message = e.message ?? 'Signup failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use. Try logging in or reset your password.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use 6+ characters.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
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
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessAndNavigate(User? user) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Welcome'),
        content: Text(
          user == null
              ? 'Signed up successfully'
              : 'Signed up as: ${user.email}\nUID: ${user.uid}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Continue'),
          )
        ],
      ),
    );
  }

  // Optional: UI action for Google sign up (uses AuthService.signInWithGoogle)
  Future<void> _signupWithGoogle() async {
    setState(() => _loading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Google signup cancelled');
      }
    } catch (e) {
      _showError('Google signup failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Placeholder: navigate to phone signup flow (implement your route)
  void _signupWithPhone() {
    Navigator.pushNamed(context, '/phone');
  }

  // Small avatar placeholder tap handler (you can implement image picker here)
  void _onAvatarTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar picker not implemented — add image picker here')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E8B3A);
    const Color accent = Color(0xFF74C043);
    const Color canvas = Color(0xFFF4F9F4);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3A1B)),
        ),
        title: const Text('Create account', style: TextStyle(color: Color(0xFF0B3A1B))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  // header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primaryGreen, accent]),
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
                            'Create your Free Account',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // white form card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Avatar / name row
                            Row(
                              children: [
                                InkWell(
                                  onTap: _onAvatarTap,
                                  borderRadius: BorderRadius.circular(50),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[100],
                                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2E8B3A)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameCtrl,
                                    focusNode: _nameFocus,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      label: Text('Full name'),
                                      prefixIcon: const Icon(Icons.person_outline),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().length < 2) return 'Please enter your name';
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                label: Text('Email address'),
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter email';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                                return null;
                              },
                              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            ),

                            const SizedBox(height: 12),

                            // Phone (optional)
                            TextFormField(
                              controller: _phoneCtrl,
                              focusNode: _phoneFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Phone (optional)',
                                label: Text("phone Number"),
                                prefixIcon: const Icon(Icons.phone_outlined),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  final digits = v.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length < 8) return 'Enter a valid phone';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),

                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                label: Text('Create a password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                            ),

                            const SizedBox(height: 8),

                            // Password strength bar & label
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (_currentStrength / 4).clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _strengthColor(_currentStrength),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _strengthLabel(_currentStrength),
                                  style: TextStyle(color: _strengthColor(_currentStrength), fontWeight: FontWeight.w700),
                                )
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Confirm password
                            TextFormField(
                              controller: _confirmCtrl,
                              focusNode: _confirmFocus,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                label: Text('Confirm password'),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Confirm your password';
                                if (v != _passwordCtrl.text) return 'Passwords do not match';
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 14),

                            // Terms checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  activeColor: primaryGreen,
                                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I agree to the ',
                                        style: const TextStyle(color: Colors.black87),
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Signup button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
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

                            // Social / phone options
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _loading ? null : _signupWithGoogle,
                                    icon: Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.login, color: Colors.redAccent),
                                    ),
                                    label: const Text('Sign up with Google'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _signupWithPhone,
                                    icon: const Icon(Icons.phone_android, color: Colors.black54),
                                    label: const Text('Sign up with Phone'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? '),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                  child: const Text('Log in'),
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
