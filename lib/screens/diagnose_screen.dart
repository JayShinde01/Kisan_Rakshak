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
  // Pickers & state
  final ImagePicker _picker = ImagePicker();
  File? _lastPickedImage;
  bool _isUploading = false;

  // Palette
  static const Color _primaryGreen = Color(0xFF2E8B3A);
  static const Color _accentGreen = Color(0xFF74C043);
  static const Color _softCanvas = Color(0xFFF4FBF4);
  static const Color _contentCard = Colors.white;
  static const double _cardRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ---------- Image pickers ----------
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (xfile == null) return;
      final file = File(xfile.path);
      setState(() => _lastPickedImage = file);

      // Immediately show confirmation dialog
      if (!mounted) return;
      _showUploadConfirmationDialog(file);
    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to pick image. Check permissions.'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  // ---------- Confirmation dialog ----------
  void _showUploadConfirmationDialog(File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Upload', style: TextStyle(fontWeight: FontWeight.w700)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _lastPickedImage = null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _startUploadProcess(file);
            },
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload & Diagnose'),
            style: ElevatedButton.styleFrom(backgroundColor: _accentGreen, foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  // ---------- Upload process ----------
  Future<void> _startUploadProcess(File file) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    // optional: small immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 2)),
    );

    try {
      // 1) Upload to cloud storage (CloudinaryService expected)
      final url = await CloudinaryService.uploadImage(file);

      if (url == null) throw Exception('Upload returned null URL');

      // 2) Save metadata via AuthService (expected method)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not signed in');
      await AuthService().saveCropImage(url: url, userId: user.uid, source: 'camera');

      // 3) Success feedback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded. Diagnosis started!')),
      );

      // TODO: navigate to results page if you have one:
      // Navigator.pushNamed(context, '/diagnosis_results', arguments: url);

    } catch (e, st) {
      debugPrint('Upload/process error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Try again.'), backgroundColor: Colors.redAccent),
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

  // ---------- UI helpers ----------
  Widget _miniTip(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accentGreen.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accentGreen, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _initialCard(double width, {double? height}) {
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: 160, maxWidth: 900, maxHeight: height ?? double.infinity),
      decoration: BoxDecoration(
        color: _contentCard,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 72, color: _accentGreen),
            const SizedBox(height: 12),
            const Text('Ready to diagnose', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                'Tap camera to take a photo or choose from gallery. Try to include the whole leaf and a few nearby leaves for context.',
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _miniTip(Icons.wb_sunny_outlined, 'Tip: daylight', 'Use natural light'),
                  const SizedBox(width: 10),
                  _miniTip(Icons.photo_size_select_actual_outlined, 'Macro', 'Fill ~60% of frame'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCard(double width, {double? height}) {
    if (_lastPickedImage == null) return const SizedBox.shrink();
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: 200, maxWidth: 900, maxHeight: height ?? double.infinity),
      decoration: BoxDecoration(
        color: _contentCard,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(_lastPickedImage!, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showUploadConfirmationDialog(_lastPickedImage!),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload & Diagnose'),
                      style: ElevatedButton.styleFrom(backgroundColor: _accentGreen, foregroundColor: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _lastPickedImage = null),
                    child: const Text('Retake'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statusCard(double width, {double? height}) {
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: 140, maxWidth: 900, maxHeight: height ?? double.infinity),
      decoration: BoxDecoration(
        color: _contentCard,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: _accentGreen),
          const SizedBox(height: 12),
          const Text('Processing Image...', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Please wait while we analyze your photo.', textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // Build selector for which card to show
  Widget _buildImageOrPromptCard(bool isWide) {
    final double cardW = isWide ? 520 : MediaQuery.of(context).size.width * 0.92;
    final double cardH = 320;

    if (_isUploading) return _statusCard(cardW, height: cardH);
    if (_lastPickedImage != null) return _previewCard(cardW, height: cardH);
    return _initialCard(cardW, height: cardH);
  }

  // Build action buttons row
  Widget _buildActionButtons(bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Camera'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Gallery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 640;

    return Scaffold(
      backgroundColor: _softCanvas,
     
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _contentCard,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Plant Diagnosis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                      'Take a clear photo of the affected leaf. We will analyze the image and provide simple steps you can follow.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // The main card area (prompt / preview / status)
              Center(child: _buildImageOrPromptCard(isWide)),

              const SizedBox(height: 18),

              // Action buttons
              _buildActionButtons(isWide),

              const SizedBox(height: 24),

              // Small footer text
              Text(
                'Your photos are used only for diagnosis and are stored securely.',
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),

              // Add bottom padding so FAB doesn't overlap
              SizedBox(height: 72),
            ],
          ),
        ),
      ),

      // Floating action button (friendly and big)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
        backgroundColor: _accentGreen,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Scan'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
