import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class ChefProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ChefProfileScreen({super.key, required this.userId, required this.userData});

  @override
  State<ChefProfileScreen> createState() => _ChefProfileScreenState();
}

class _ChefProfileScreenState extends State<ChefProfileScreen> {
  bool _isFollowing = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).collection('following').doc(widget.userId).get();
      if (mounted) {
        setState(() {
          _isFollowing = doc.exists;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String chefName = widget.userData['fullName'] ?? 'Chef';
    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);

    try {
      if (!wasFollowing) {
        // 1. Update Following/Followers
        await _firestore.collection('users').doc(user.uid).collection('following').doc(widget.userId).set({
          'timestamp': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('users').doc(widget.userId).collection('followers').doc(user.uid).set({
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Fetch current user's name for the notification
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final myName = userDoc.data()?['fullName'] ?? 'Someone';

        // 3. Add Notification for the CHEF being followed
        await _firestore.collection('notifications').add({
          'userId': widget.userId, // Receiver: The Chef
          'title': 'New Follower!',
          'body': '$myName started following you.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'follow',
          'fromUserId': user.uid, // Sender: Me
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have started following $chefName'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } else {
        await _firestore.collection('users').doc(user.uid).collection('following').doc(widget.userId).delete();
        await _firestore.collection('users').doc(widget.userId).collection('followers').doc(user.uid).delete();
      }
    } catch (e) {
      setState(() => _isFollowing = wasFollowing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.userData['fullName'] ?? 'Chef';
    final String pic = widget.userData['profilePic'] ?? '';
    final String level = widget.userData['cookingLevel'] ?? 'Professional';
    final String email = widget.userData['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('@${name.toLowerCase().replaceAll(' ', '_')}', style: const TextStyle(color: AppTheme.textColor, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: AppTheme.textColor), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50, 
            backgroundColor: AppTheme.primaryColor,
            backgroundImage: (pic.isNotEmpty && pic.startsWith('http')) ? NetworkImage(pic) : null,
            child: (pic.isEmpty || !pic.startsWith('http')) 
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)) 
              : null,
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('$level Chef', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? Colors.grey[200] : AppTheme.primaryColor,
              foregroundColor: _isFollowing ? AppTheme.textColor : Colors.white,
              minimumSize: const Size(120, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text(_isFollowing ? 'Following' : 'Follow', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatFromQuery('Recipes', _firestore.collection('recipes').where('authorEmail', isEqualTo: email)),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').doc(widget.userId).collection('following').snapshots(),
                builder: (context, snapshot) => _buildStat('Following', snapshot.hasData ? snapshot.data!.docs.length.toString() : '0'),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').doc(widget.userId).collection('followers').snapshots(),
                builder: (context, snapshot) => _buildStat('Followers', snapshot.hasData ? snapshot.data!.docs.length.toString() : '0'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(thickness: 1, height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Recipes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          ),
          const Divider(thickness: 1, height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('recipes')
                  .where('authorEmail', isEqualTo: email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading recipes'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No recipes posted by this chef yet.'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final recipe = Recipe.fromFirestore(docs[index]);
                    return _buildRecipeCard(context, recipe);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatFromQuery(String label, Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        String value = snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
        return _buildStat(label, value);
      },
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey[100],
                child: (recipe.image.isEmpty || !recipe.image.startsWith('http')) 
                  ? const Icon(Icons.image, color: Colors.grey)
                  : Image.network(
                      recipe.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(recipe.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(recipe.rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(recipe.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
