// lib/screens/add_post_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart'; // desktop/web
import 'package:image_picker/image_picker.dart'; // mobile

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/cloudinary_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _category;
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  // Palette (match your app)
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color lightGreen = Color(0xFF74C043);
  static const Color pageBg = Color(0xFFF4F9F4);

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ------------------------
  // Image picking (web/desktop/mobile)
  // ------------------------
  Future<void> pickImage() async {
    try {
      // WEB
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null) return;

        final fileBytes = result.files.single.bytes;
        final fileName = result.files.single.name;

        if (fileBytes == null) return;

        // Create a temporary file so we can reuse your Cloudinary upload logic that expects File
        final temp = File(fileName);
        await temp.writeAsBytes(fileBytes);
        if (!mounted) return;
        setState(() => _selectedImage = temp);
        return;
      }

      // DESKTOP (Windows / Mac / Linux)
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result == null) return;

        final path = result.files.single.path;
        if (path == null) return;

        if (!mounted) return;
        setState(() => _selectedImage = File(path));
        return;
      }

      // MOBILE
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (e, st) {
      debugPrint('[pickImage] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (e, st) {
      debugPrint('[takePhoto] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to take photo')));
    }
  }

  // ------------------------
  // Submit post
  // ------------------------
  Future<void> submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    String? imageUrl;
    try {
      // upload image if present
      if (_selectedImage != null) {
        // If your CloudinaryService supports progress events, hook them here.
        // For now we emulate progress until upload completes.
        final url = await CloudinaryService.uploadImage(
  _selectedImage!,
  folder: 'community_posts',
);


        imageUrl = url;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to post')));
        return;
      }

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user.uid,
        'imageUrl': imageUrl ?? "",
        'title': _titleController.text.trim(),
        'category': _category ?? 'crop',
        'description': _descController.text.trim(),
        'likedBy': [],
        'savedBy': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post added successfully'), backgroundColor: lightGreen));
      Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('[submitPost] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add post'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // ------------------------
  // UI helpers
  // ------------------------
  Widget _imagePickerCard(BuildContext ctx) {
    return GestureDetector(
      onTap: pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 220,
          width: double.infinity,
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // image or placeholder
              if (_selectedImage != null)
                Image.file(_selectedImage!, fit: BoxFit.cover)
              else
                Container(
                  padding: const EdgeInsets.all(18),
                  color: pageBg,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, size: 42, color: primaryGreen),
                      const SizedBox(height: 8),
                      Text('Tap to add an image (optional)', style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => pickImage(),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () => takePhoto(),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              // remove / edit button on top-right when an image is present
              if (_selectedImage != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          onPressed: pickImage,
                          tooltip: 'Replace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                          onPressed: () {
                            setState(() => _selectedImage = null);
                          },
                          tooltip: 'Remove',
                        ),
                      ),
                    ],
                  ),
                ),

              // subtle progress overlay
              if (_isUploading && _uploadProgress > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(value: _uploadProgress, color: lightGreen),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    final categories = <Map<String, dynamic>>[
      {'key': 'crop', 'label': 'Crop'},
      {'key': 'fertilizer', 'label': 'Fertilizer'},
      {'key': 'medicine', 'label': 'Medicine'},
      {'key': 'tool', 'label': 'Tool'},
    ];

    return Wrap(
      spacing: 8,
      children: categories.map((c) {
        final key = c['key'] as String;
        final label = c['label'] as String;
        final selected = _category == key;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() => _category = key);
          },
          selectedColor: lightGreen,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: selected ? Colors.black : Colors.black87, fontWeight: FontWeight.w600),
          elevation: 0.8,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('New post'),
        backgroundColor: primaryGreen,
        actions: [
          TextButton(
            onPressed: () {
              // optional quick clear
              if (!mounted) return;
              setState(() {
                _titleController.clear();
                _descController.clear();
                _selectedImage = null;
                _category = null;
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // Image picker area
                    _imagePickerCard(context),
                    const SizedBox(height: 16),

                    // Category chips + dropdown fallback
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _categoryChips(),
                    const SizedBox(height: 12),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Short description (required)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Write more details (required)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 5,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
                    ),

                    const SizedBox(height: 18),

                    // Action row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : submitPost,
                            icon: _isUploading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.upload),
                            label: Text(_isUploading ? 'Posting...' : 'Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () {
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                },
                         
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                           child: const Text('Cancel'),
                        )
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedImage == null
          ? FloatingActionButton(
              backgroundColor: lightGreen,
              foregroundColor: Colors.black,
              onPressed: pickImage,
            
              tooltip: 'Add Image',
                child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }
}
