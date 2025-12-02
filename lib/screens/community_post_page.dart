// lib/screens/community_post_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'comment_screen.dart';
import 'add_post_screen.dart';

class CommunityPostPage extends StatefulWidget {
  const CommunityPostPage({Key? key}) : super(key: key);

  @override
  State<CommunityPostPage> createState() => _CommunityPostPageState();
}

class _CommunityPostPageState extends State<CommunityPostPage> {
  // Palette for agriculture-style UI
  static const Color primaryGreen = Color(0xFF2E8B3A);
  static const Color accentGreen = Color(0xFF74C043);
  static const Color canvas = Color(0xFFF4FBF4);
  static const Color cardWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentGreen,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Add Post',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPostScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Small header strip under AppBar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: primaryGreen.withOpacity(0.08),
            child: const Text(
              'Share photos, tips, and questions with other farmers.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts yet.\nBe the first to share!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final postId = docs[i].id;
                    return _postCard(context, postId, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(
      BuildContext context, String postId, Map<String, dynamic> data) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final likedBy =
        (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final savedBy =
        (data['savedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final isLiked = uid != null && likedBy.contains(uid);
    final isSaved = uid != null && savedBy.contains(uid);
    final category = (data['category'] ?? '').toString();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['userId'])
          .get(),
      builder: (context, userSnap) {
        final userData = (userSnap.hasData && userSnap.data!.exists)
            ? (userSnap.data!.data() as Map<String, dynamic>)
            : null;
        final userName = userData?['name'] ?? 'Farmer';
        final userPhoto = userData?['photoURL'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage:
                          userPhoto != null ? NetworkImage(userPhoto) : null,
                      child: userPhoto == null
                          ? const Icon(Icons.person, color: primaryGreen)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shared a post',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.zero, bottom: Radius.zero),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    data['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, st) {
                      return Container(
                        color: Colors.green.shade50,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black26,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Actions + text
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action row: like, comment, save
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => toggleLike(postId, isLiked),
                          icon: Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                          ),
                          color: isLiked ? Colors.red : Colors.grey.shade700,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommentScreen(postId: postId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.mode_comment_outlined),
                          color: Colors.grey.shade700,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => toggleSave(postId, isSaved),
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                          ),
                          color:
                              isSaved ? primaryGreen : Colors.grey.shade700,
                        ),
                      ],
                    ),

                    // Likes count
                    if (likedBy.isNotEmpty)
                      Text(
                        '${likedBy.length} like${likedBy.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      )
                    else
                      Text(
                        'Be the first to like this',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Description
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$userName  ',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: (data['description'] ?? '').toString(),
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // View comments link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentScreen(postId: postId),
                          ),
                        );
                      },
                      child: Text(
                        'View comments',
                        style: TextStyle(
                          color: primaryGreen.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                    // Small timestamp placeholder (if you want to add later)
                    Text(
                      'Just now', // TODO: replace with real time formatting if needed
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref =
        FirebaseFirestore.instance.collection('community_posts').doc(postId);

    if (isLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> toggleSave(String postId, bool isSaved) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref =
        FirebaseFirestore.instance.collection('community_posts').doc(postId);

    if (isSaved) {
      await ref.update({
        'savedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'savedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }
}
