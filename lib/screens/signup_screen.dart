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
    // NOTE: Don't dispose of listener as it's disposed with the controller.
    super.dispose();
  }

  // -------------------------------------------------------------
  // --- PASSWORD STRENGTH LOGIC (UPDATED COLORS TO BE THEME-AWARE) ---
  // -------------------------------------------------------------

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
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  // Uses context to grab primary color for 'Strong' state
  Color _strengthColor(int s, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (s) {
      case 0:
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return colorScheme.secondary; // Use theme accent color for 'Good'
      default:
        return colorScheme.primary; // Use theme primary color for 'Strong'
    }
  }

  int _currentStrength = 0;

  void _onPasswordChanged() {
    final score = _passwordStrengthScore(_passwordCtrl.text);
    if (mounted) setState(() => _currentStrength = score);
  }

  // -------------------------------------------------------------
  // --- AUTH LOGIC ---
  // -------------------------------------------------------------

  Future<void> _submit() async {
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
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccessAndNavigate(User? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Welcome', style: theme.textTheme.titleLarge),
        content: Text(
          user == null
              ? 'Signed up successfully'
              : 'Signed up as: ${user.email}',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text('Continue', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

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

  void _signupWithPhone() {
    Navigator.pushNamed(context, '/phone');
  }

  void _onAvatarTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar picker not implemented — add image picker here')),
    );
  }

  // -------------------------------------------------------------
  // --- UI BUILDER (THEME INTEGRATION) ---
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // NOTE: Removed hardcoded colors: primaryGreen, accent, canvas

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // AppBar is now flat and uses theme colors
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
        ),
        title: Text('Create account', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onBackground)),
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
                  // --- Header Card: Vibrant Gradient ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      // Uses theme primary and secondary colors
                      gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          // Ensures avatar background contrasts the gradient
                          backgroundColor: colorScheme.onPrimary, 
                          child: Icon(Icons.eco, color: colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Create your Free Account',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Form Card ---
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                                    backgroundColor: colorScheme.surfaceVariant, // Theme compliant background
                                    child: Icon(Icons.camera_alt_outlined, color: colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameCtrl,
                                    focusNode: _nameFocus,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    style: theme.textTheme.bodyLarge,
                                    validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
                                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter email' : (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()) ? 'Enter a valid email' : null),
                              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            ),

                            const SizedBox(height: 16),

                            // Phone (optional)
                            TextFormField(
                              controller: _phoneCtrl,
                              focusNode: _phoneFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone (optional)',
                                labelText: "Phone Number",
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v != null && v.isNotEmpty && v.replaceAll(RegExp(r'\D'), '').length < 8) ? 'Enter a valid phone' : null,
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),

                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Create a password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
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
                                      color: colorScheme.surfaceVariant, // Theme-aware background for bar
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (_currentStrength / 4).clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _strengthColor(_currentStrength, context), // Dynamic color
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _strengthLabel(_currentStrength),
                                  style: TextStyle(color: _strengthColor(_currentStrength, context), fontWeight: FontWeight.w700),
                                )
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Confirm password
                            TextFormField(
                              controller: _confirmCtrl,
                              focusNode: _confirmFocus,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.isEmpty) ? 'Confirm your password' : (v != _passwordCtrl.text ? 'Passwords do not match' : null),
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 16),

                            // Terms checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  activeColor: colorScheme.primary, // Theme primary
                                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I agree to the ',
                                        style: theme.textTheme.bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Signup button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary, // Theme primary
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OR divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text('OR', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500)),
                                ),
                                Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.3))),
                              ],
                            ),

                            const SizedBox(height: 20),

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
                                      errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary),
                                    ),
                                    label: const Text('Google'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: theme.brightness == Brightness.dark ? colorScheme.surfaceVariant : Colors.white,
                                      foregroundColor: colorScheme.onSurface,
                                      side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                              ],
                            ),

                            const SizedBox(height: 20),

                            // login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Already have an account? ', style: theme.textTheme.bodyMedium),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                  child: Text('Log in', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            
                             const SizedBox(height: 6),
                            // Microcopy
                            Text(
                              "We keep data private — used only for alerts and personalized content.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
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