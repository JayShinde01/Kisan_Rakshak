// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // UI state
  bool _loading = false;
  double _uploadProgress = 0.0;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Prefill values
    _nameCtrl.text = user.displayName ?? '';
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _phoneCtrl.text = (data['phone'] ?? '') as String;
      }
    } catch (e) {
      debugPrint('Failed to load profile doc: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1200);
      if (picked == null) return;
      setState(() => _pickedImageFile = File(picked.path));
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(File file, String uid) async {
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');

    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((event) {
      final total = event.totalBytes;
      final transferred = event.bytesTransferred;
      if (total > 0 && mounted) {
        setState(() => _uploadProgress = transferred / total);
      }
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _loading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? photoUrl = user.photoURL;

      // Upload image if picked
      if (_pickedImageFile != null) {
        final uploadedUrl = await _uploadProfileImage(_pickedImageFile!, user.uid);
        if (uploadedUrl != null) photoUrl = uploadedUrl;
      }

      // Update Auth profile
      await user.updateDisplayName(name);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await user.reload();

      // Update Firestore user doc
      final docRef = _db.collection('users').doc(user.uid);
      await docRef.set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'phone': phone,
        'photoURL': photoUrl,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );

      // reset picked image and progress
      setState(() {
        _pickedImageFile = null;
        _uploadProgress = 0.0;
      });
    } catch (e, st) {
      debugPrint('Save profile error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_pickedImageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove selected image'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _pickedImageFile = null);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out')),
        ],
      ),
    );

    if (ok == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _effectiveDisplayName(User? user) {
    if (user != null && user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    if (_nameCtrl.text.trim().isNotEmpty) return _nameCtrl.text.trim();
    return 'Farmer';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final theme = Theme.of(context);

    // Effective avatar widget
    Widget avatarWidget;
    if (_pickedImageFile != null) {
      avatarWidget = ClipOval(child: Image.file(_pickedImageFile!, width: 120, height: 120, fit: BoxFit.cover));
    } else if (user?.photoURL != null) {
      avatarWidget = ClipOval(child: Image.network(user!.photoURL!, width: 120, height: 120, fit: BoxFit.cover));
    } else {
      avatarWidget = const ClipOval(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Icon(Icons.person, size: 60, color: Colors.white54),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2E8B3A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          )
        ],
      ),
      backgroundColor: const Color(0xFFF4F9F4), // soft canvas
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Header card with avatar and brief info
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        // avatar & edit
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: avatarWidget,
                            ),
                            Material(
                              elevation: 2,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: _showImageSourceSheet,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                  child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF2E8B3A)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // name + email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _effectiveDisplayName(user),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(user?.email ?? '', style: const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // quick action: open camera diagnose
                                        Navigator.pushNamed(context, '/diagnose');
                                      },
                                      icon: const Icon(Icons.camera_alt, size: 16),
                                      label: const Text('Scan Crop'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF74C043),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        // view saved fields (placeholder)
                                        Navigator.pushNamed(context, '/fieldmap');
                                      },
                                      icon: const Icon(Icons.map, size: 16),
                                      label: const Text('My Fields'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Edit form card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length < 2) return 'Please enter your name';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Email (read-only)
                          TextFormField(
                            initialValue: user?.email ?? '',
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final digits = v.replaceAll(RegExp(r'\D'), '');
                                if (digits.length < 8) return 'Enter a valid phone';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Upload progress UI
                          if (_uploadProgress > 0 && _uploadProgress < 1)
                            Column(
                              children: [
                                LinearProgressIndicator(value: _uploadProgress),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          // Save + remove image
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E8B3A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_pickedImageFile != null || user?.photoURL != null)
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _pickedImageFile = null;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Remove photo'),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Danger zone: clear profile photo from auth (optional)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () async {
                                final doClear = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Remove profile photo'),
                                    content: const Text('This will remove your profile photo from your account. Continue?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );

                                if (doClear == true) {
                                  try {
                                    final u = _auth.currentUser;
                                    if (u != null) {
                                      await u.updatePhotoURL(null);
                                      await _db.collection('users').doc(u.uid).set({'photoURL': FieldValue.delete()}, SetOptions(merge: true));
                                      await u.reload();
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Profile photo removed'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to remove photo: $e'), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                }
                              },
                              child: const Text('Remove photo from account', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Additional actions
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.shield),
                          title: const Text('Privacy & Security'),
                          subtitle: const Text('Manage data permissions and alerts'),
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help & Tutorials'),
                          subtitle: const Text('How to use the app and best practices'),
                          onTap: () => Navigator.pushNamed(context, '/help'),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
