// lib/screens/diagnose_screen.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({Key? key}) : super(key: key);

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _lastPickedImage;
  bool _isUploading = false;

  static const double _cardRadius = 18.0;

  @override
  void initState() {
    super.initState();
    // Assuming checkLoggedIn is handled by the Home Screen shell
  }

  // NOTE: _checkLoggedIn, _pickImage, _startUploadProcess remain UNCHANGED
  // as their logic is correct.

  // ---------------- IMAGE PICK + CLOUDINARY UPLOAD ----------------

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;
    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (xfile == null) return;
      final file = File(xfile.path);
      setState(() => _lastPickedImage = file);

      if (!mounted) return;
      _showUploadConfirmationDialog(file);
    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  // ---------- Confirmation dialog (Theme-Compliant) ----------
  void _showUploadConfirmationDialog(File file) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text('Confirm Diagnosis Photo', style: theme.textTheme.titleLarge)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2) 
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.cover, height: 200),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Is this photo clear and well-focused for analysis?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _lastPickedImage = null);
              },
              child: const Text('Retake'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _startUploadProcess(file);
              },
              icon: const Icon(Icons.cloud_upload_outlined, size: 20),
              label: const Text('Diagnose'),
              style: ElevatedButton.styleFrom(
                // Use Secondary (Accent) for the main action, as defined in main.dart
                backgroundColor: colorScheme.secondary, 
                foregroundColor: colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Upload process (Logic remains the same) ----------
  Future<void> _startUploadProcess(File file) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 2)),
    );

    try {
      final url = await CloudinaryService.uploadImage(file);
      if (url == null) throw Exception('Upload returned null URL');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not signed in');
      await AuthService().saveCropImage(url: url, userId: user.uid, source: 'camera');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Diagnosis complete! Results are ready.'),
          backgroundColor: Theme.of(context).colorScheme.primary, 
        ),
      );

    } catch (e, st) {
      debugPrint('Upload/process error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed. Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _lastPickedImage = null;
        });
      }
    }
  }

  // -----------------------------------------------------------
  // ---------- UI BUILDERS USING THEME COLORS ONLY ----------
  // -----------------------------------------------------------

  Widget _tipRow({required IconData icon, required String text, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8)
            )),
          ),
        ],
      ),
    );
  }

  Widget _adviceContainer(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Use a light tint or surface variant for distinct background
        color: colorScheme.surfaceVariant, 
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Tips for a Better Scan:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _tipRow(icon: Icons.lightbulb_outline, text: 'Use natural daylight for accurate color.', theme: theme),
          _tipRow(icon: Icons.zoom_in, text: 'Focus clearly on the affected area.', theme: theme),
          _tipRow(icon: Icons.grass_outlined, text: 'Include the whole leaf and some context.', theme: theme),
        ],
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onPressed, 
    required Color color,
    required Color foregroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor, 
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
  
  // Combines Status, Preview, and Prompt states
  Widget _buildMainInteractiveArea(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardColor;

    if (_isUploading) {
      // 1. Loading State (High Contrast)
      return Card(
        color: cardBg,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              CircularProgressIndicator(color: colorScheme.secondary),
              const SizedBox(height: 20),
              Text(
                'Analyzing Image...', 
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary),
              ),
              const SizedBox(height: 8),
              Text('Please wait while our AI identifies the issue.', 
                textAlign: TextAlign.center, 
                style: theme.textTheme.bodyMedium
              ),
            ]
          ),
        ),
      );
    }
    
    if (_lastPickedImage != null) {
      // 2. Image Preview State
      return Card(
        color: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_cardRadius)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(_lastPickedImage!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showUploadConfirmationDialog(_lastPickedImage!),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Confirm & Diagnose'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary, 
                        foregroundColor: colorScheme.onSecondary,
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _lastPickedImage = null),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }
    
    // 3. Initial Prompt State (Matches the look from your image)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.camera_alt_outlined, size: 80, color: colorScheme.primary), 
        const SizedBox(height: 16),
        Text(
          'Start Diagnosing',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Tap below to take a picture of the plant leaf or choose from your gallery.',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30), // Space before buttons
        
        // Action Buttons (Matches the style from your image)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _sourceButton(
              icon: Icons.camera_alt, 
              label: 'Camera', 
              onPressed: () => _pickImage(ImageSource.camera), 
              // 🌿 Use Primary Color for Camera (the vibrant green from main.dart)
              color: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            const SizedBox(width: 16),
            _sourceButton(
              icon: Icons.photo_library_outlined, 
              label: 'Gallery', 
              onPressed: () => _pickImage(ImageSource.gallery), 
              // 🌑 Use Dark Surface Color for Gallery (the dark grey from main.dart)
              color: theme.cardColor, 
              foregroundColor: colorScheme.onSurface,
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Build Method ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header/Title
                  Text(
                    'AI-Powered Plant Doctor', 
                    style: theme.textTheme.headlineLarge?.copyWith(fontSize: 30, color: theme.colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get instant, accurate diagnosis for common crop diseases.',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 30),

                  // Main Interactive Area
                  _buildMainInteractiveArea(theme),

                  const SizedBox(height: 24),

                  // Tips/Advice Container
                  _adviceContainer(theme),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}