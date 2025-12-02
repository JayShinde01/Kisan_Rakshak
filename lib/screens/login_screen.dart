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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emailController = TextEditingController(text: _emailCtrl.text.trim());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reset password', style: theme.textTheme.titleLarge),
          content: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              // Rely on theme input decoration settings
              filled: true, 
              fillColor: theme.inputDecorationTheme.fillColor,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty ||
                    !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Enter a valid email'),
                      backgroundColor: colorScheme.error,
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
                    SnackBar(
                      content: const Text('Password reset email sent. Check your inbox.'),
                      backgroundColor: colorScheme.primary,
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
              child: Text('Send', style: TextStyle(color: colorScheme.secondary)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Use theme's scaffold background color
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // Slightly smaller max width for focus
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header: Modern Gradient ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary], // Fresh colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16), // More rounded corners
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.onPrimary, // White/Black based on theme
                          child: Icon(Icons.eco, color: colorScheme.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Welcome back — sign in to Crop AI',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary, // Ensure text is readable on the gradient
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
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Title
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Login to continue',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email field
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                                // Theme controls the rest (fillColor, border radius, etc.)
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? "Please enter email" : (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v) ? "Enter a valid email" : null),
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
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                // Theme controls the rest
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? "Enter your password" : (v.length < 6 ? "Password must be at least 6 characters" : null),
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
                                Expanded(child: Text('Remember me', style: theme.textTheme.bodyMedium)),
                                TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: Text('Forgot Password?', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
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
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
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

                            // Google button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _googleSignIn,
                                icon: Image.asset(
                                  // NOTE: Using a cleaner icon fallback if the asset image fails
                                  'assets/images/google_logo.png', 
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (_, __, ___) => Icon(Icons.public, color: colorScheme.primary),
                                ),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  // In dark mode, this button must contrast with the surface
                                  backgroundColor: theme.brightness == Brightness.dark ? colorScheme.surfaceVariant : Colors.white,
                                  foregroundColor: colorScheme.onSurface,
                                  side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Phone sign-in + guest
                            Row(
                              children: [
                              
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: _skipAsGuest,
                                    child: const Text('Skip as Guest'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary, // Use primary color for guest option
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
                                Text("Don't have an account? ", style: theme.textTheme.bodyMedium),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, "/signup");
                                  },
                                  child: Text('Sign Up', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
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