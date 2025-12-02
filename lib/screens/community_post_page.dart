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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primary = colorScheme.primary;
    final accent = colorScheme.secondary;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        icon: Icon(Icons.add, color: colorScheme.onSecondary),
        label: Text(
          'Add Post',
          style: TextStyle(color: colorScheme.onSecondary, fontWeight: FontWeight.w600),
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
            color: primary.withOpacity(0.08),
            child: Text(
              'Share photos, tips, and questions with other farmers.',
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
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
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No posts yet.\nBe the first to share!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
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

  Widget _postCard(BuildContext context, String postId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardColor;
    final primary = colorScheme.primary;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final likedBy = (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final savedBy = (data['savedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final isLiked = uid != null && likedBy.contains(uid);
    final isSaved = uid != null && savedBy.contains(uid);
    final category = (data['category'] ?? '').toString();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
      builder: (context, userSnap) {
        final userData = (userSnap.hasData && userSnap.data!.exists)
            ? (userSnap.data!.data() as Map<String, dynamic>)
            : null;
        final userName = userData?['name'] ?? 'Farmer';
        final userPhoto = userData?['photoURL'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
                      child: userPhoto == null ? Icon(Icons.person, color: primary) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shared a post',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                          ),
                        ],
                      ),
                    ),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: primary,
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
                borderRadius: const BorderRadius.vertical(top: Radius.zero, bottom: Radius.zero),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    data['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, st) {
                      return Container(
                        color: colorScheme.surfaceVariant,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.disabledColor,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action row: like, comment, save
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => toggleLike(postId, isLiked),
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                          ),
                          color: isLiked ? Colors.redAccent : theme.iconTheme.color,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CommentScreen(postId: postId)),
                            );
                          },
                          icon: const Icon(Icons.mode_comment_outlined),
                          color: theme.iconTheme.color,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => toggleSave(postId, isSaved),
                          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border_rounded),
                          color: isSaved ? colorScheme.primary : theme.iconTheme.color,
                        ),
                      ],
                    ),

                    // Likes count
                    if (likedBy.isNotEmpty)
                      Text(
                        '${likedBy.length} like${likedBy.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      )
                    else
                      Text(
                        'Be the first to like this',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                      ),
                    const SizedBox(height: 6),

                    // Description
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color) ??
                            const TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: '$userName  ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: (data['description'] ?? '').toString(),
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
                          MaterialPageRoute(builder: (_) => CommentScreen(postId: postId)),
                        );
                      },
                      child: Text(
                        'View comments',
                        style: TextStyle(
                          color: primary.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                    // Small timestamp placeholder (if you want to add later)
                    Text(
                      'Just now', // TODO: replace with real time formatting if needed
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
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

    final ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);

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

    final ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);

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
