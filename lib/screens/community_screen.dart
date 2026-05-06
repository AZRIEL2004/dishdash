import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'chef_profile_screen.dart';
import 'reviews_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'Newest';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search chefs...', border: InputBorder.none),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            )
          : const Text('Community', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _isSearching 
          ? IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor), onPressed: () => setState(() { _isSearching = false; _searchQuery = ""; _searchController.clear(); }))
          : null,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppTheme.primaryColor), 
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = "";
                _searchController.clear();
              }
            }),
          ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildCommunityFeed(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text('Type a name to search for chefs'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final chefs = snapshot.data!.docs.where((doc) {
          final name = (doc['fullName'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (chefs.isEmpty) return const Center(child: Text('No chefs found.'));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: chefs.length,
          itemBuilder: (context, index) {
            final data = chefs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(data['profilePic'] ?? 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80')),
              title: Text(data['fullName'] ?? 'Chef'),
              subtitle: Text('${data['cookingLevel'] ?? 'Professional'} Chef'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChefProfileScreen(userId: chefs[index].id, userData: data))),
            );
          },
        );
      },
    );
  }

  Widget _buildCommunityFeed() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterTab('Top Recipes'),
              _buildFilterTab('Newest'),
              _buildFilterTab('Oldest'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No community posts yet.'));

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String userId = data['userId'] ?? '';
                  final Timestamp? createdAt = data['createdAt'];

                  final recipe = Recipe(
                    id: doc.id,
                    title: data['title'] ?? 'No Title',
                    image: data['image'] ?? '',
                    author: data['author'] ?? 'Chef',
                    authorEmail: data['authorEmail'] ?? '',
                    authorImage: data['authorImage'] ?? 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
                    rating: data['rating'] ?? '5.0',
                    time: data['time'] ?? '20 min',
                    category: data['category'] ?? 'General',
                    description: data['description'] ?? '',
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChefHeader(context, userId, recipe.author, createdAt),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            data['postText'] ?? 'Check out this amazing ${recipe.title} I made today! It was so delicious and easy to prepare. #cooking #foodie',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildRecipeImage(recipe.image),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              _buildLikeAction(doc.id, data['title'] ?? 'recipe', userId),
                              const SizedBox(width: 20),
                              _buildCommentAction(doc.id, recipe),
                              const SizedBox(width: 20),
                              _buildShareAction(recipe),
                              const Spacer(),
                              const Icon(Icons.bookmark_border, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final collection = _firestore.collection('recipes');
    switch (_selectedFilter) {
      case 'Top Recipes':
        return collection.orderBy('rating', descending: true).limit(10).snapshots();
      case 'Oldest':
        return collection.orderBy('createdAt', descending: false).snapshots();
      case 'Newest':
      default:
        return collection.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Widget _buildFilterTab(String title) {
    bool isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime postDate = timestamp.toDate();
    final Duration diff = DateTime.now().difference(postDate);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildChefHeader(BuildContext context, String userId, String fallbackName, Timestamp? timestamp) {
    if (userId.isEmpty) {
      return ListTile(
        leading: const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80')),
        title: Text(fallbackName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_getTimeAgo(timestamp)),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String name = fallbackName;
        String profilePic = 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80';
        Map<String, dynamic>? userData;

        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['fullName'] ?? fallbackName;
          profilePic = userData['profilePic'] ?? profilePic;
        }

        return ListTile(
          onTap: () {
            if (userData != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChefProfileScreen(userId: userId, userData: userData!)));
            }
          },
          leading: CircleAvatar(
            backgroundImage: (profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
            child: (profilePic.isEmpty) ? const Icon(Icons.person) : null,
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(_getTimeAgo(timestamp)),
          trailing: const Icon(Icons.more_horiz),
        );
      }
    );
  }

  Widget _buildRecipeImage(String imageStr) {
    if (imageStr.isEmpty) return const Center(child: Icon(Icons.image, color: Colors.grey));
    if (imageStr.startsWith('http')) {
      return Image.network(imageStr, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
    } else if (imageStr.startsWith('data:image')) {
      try {
        final base64Str = imageStr.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (e) {
        return const Center(child: Icon(Icons.error));
      }
    }
    return const Center(child: Icon(Icons.image, color: Colors.grey));
  }

  Widget _buildLikeAction(String recipeId, String recipeTitle, String chefId) {
    final user = _auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('recipes').doc(recipeId).collection('likes').snapshots(),
      builder: (context, snapshot) {
        bool isLiked = false;
        String count = '0';
        if (snapshot.hasData) {
          isLiked = snapshot.data!.docs.any((doc) => doc.id == user?.uid);
          int n = snapshot.data!.docs.length;
          count = n > 999 ? '${(n/1000).toStringAsFixed(1)}k' : n.toString();
        }
        return GestureDetector(
          onTap: () => _toggleLike(recipeId, recipeTitle, chefId, isLiked),
          child: Row(
            children: [
              Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 20, color: isLiked ? Colors.red : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(count, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }
    );
  }

  Future<void> _toggleLike(String recipeId, String recipeTitle, String chefId, bool isLiked) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final likeRef = _firestore.collection('recipes').doc(recipeId).collection('likes').doc(user.uid);

    if (isLiked) {
      await likeRef.delete();
    } else {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      
      // Notify the Chef
      if (chefId.isNotEmpty && chefId != user.uid) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final myName = userDoc.data()?['fullName'] ?? 'Someone';

        await _firestore.collection('notifications').add({
          'userId': chefId,
          'title': 'New Like!',
          'body': '$myName liked your recipe "$recipeTitle"',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'general',
        });
      }
    }
  }

  Widget _buildCommentAction(String recipeId, Recipe recipe) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('recipes').doc(recipeId).collection('reviews').snapshots(),
      builder: (context, snapshot) {
        String count = '0';
        if (snapshot.hasData) {
          int n = snapshot.data!.docs.length;
          count = n > 999 ? '${(n/1000).toStringAsFixed(1)}k' : n.toString();
        }
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsScreen(recipe: recipe))),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(count, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildShareAction(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        final String shareText = "Check out this amazing recipe: ${recipe.title} by ${recipe.author} on DishDash!\n\nView it here: https://dishdash.app/recipe/${recipe.id}";
        Share.share(shareText);
      },
      child: Row(
        children: [
          Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('Share', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
