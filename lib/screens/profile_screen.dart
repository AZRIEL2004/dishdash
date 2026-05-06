import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../theme.dart';
import 'settings_screen.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'following_followers_screen.dart';
import 'edit_profile_full_screen.dart';
import 'share_profile_screen.dart';
import 'meal_planner_screen.dart';
import 'nutrition_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: AppTheme.primaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionDashboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppTheme.textColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MealPlannerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final String? profilePicUrl = userData?['profilePic'];
          final String name = userData?['fullName'] ?? 'Dianne Russell';
          final String handle = '@${name.toLowerCase().replaceAll(' ', '_')}';

          return Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (profilePicUrl != null && profilePicUrl.isNotEmpty)
                          ? NetworkImage(profilePicUrl)
                          : const NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            handle,
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData?['presentation'] ?? 'My passion is cooking and sharing new recipes with the world.',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileFullScreen(userData: userData))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShareProfileScreen(handle: handle))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Share Profile'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('recipes').where('authorEmail', isEqualTo: user?.email).snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _buildStatItem(count.toString(), 'recipes');
                      },
                    ),
                    _buildDivider(),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FollowingFollowersScreen(initialIndex: 0, userId: user!.uid))),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').doc(user?.uid).collection('following').snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatItem(count.toString(), 'Following');
                        },
                      ),
                    ),
                    _buildDivider(),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FollowingFollowersScreen(initialIndex: 1, userId: user!.uid))),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').doc(user?.uid).collection('followers').snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatItem(count.toString(), 'Followers');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: 'Recipe'),
                  Tab(text: 'Favorites'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecipeGrid(isSaved: false),
                    _buildRecipeGrid(isSaved: true),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildDivider() => Container(height: 30, width: 1, color: Colors.grey[300]);

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildRecipeGrid({required bool isSaved}) {
    final user = _auth.currentUser;

    if (isSaved) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('saved_recipes').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text('No saved recipes yet.'));
          }

          final savedTitles = List<String>.from(snapshot.data!['recipeIds'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('recipes').where('title', whereIn: savedTitles.isEmpty ? [''] : savedTitles).snapshots(),
            builder: (context, recipeSnapshot) {
              if (!recipeSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final displayRecipes = recipeSnapshot.data!.docs;

              return _buildGrid(displayRecipes);
            },
          );
        },
      );
    } else {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('recipes').where('authorEmail', isEqualTo: user?.email).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final displayRecipes = snapshot.data!.docs;
          
          if (displayRecipes.isEmpty) return const Center(child: Text('You haven\'t added any recipes yet.'));

          return _buildGrid(displayRecipes);
        },
      );
    }
  }

  Widget _buildGrid(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final recipe = Recipe(
          id: docs[index].id,
          title: data['title'] ?? 'No Title',
          image: data['image'] ?? '',
          author: data['author'] ?? 'Anonymous',
          authorEmail: data['authorEmail'] ?? '',
          rating: data['rating'] ?? '5.0',
          time: data['time'] ?? '20 min',
          category: data['category'] ?? 'General',
        );

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _buildRecipeImage(recipe.image),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(recipe.rating, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeImage(String imageStr) {
    if (imageStr.isEmpty) return const Center(child: Icon(Icons.image));
    if (imageStr.startsWith('http')) {
      return Image.network(imageStr, fit: BoxFit.cover, width: double.infinity);
    } else if (imageStr.startsWith('data:image')) {
      try {
        final base64Str = imageStr.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: double.infinity);
      } catch (e) {
        return const Center(child: Icon(Icons.error));
      }
    }
    return const Center(child: Icon(Icons.image));
  }
}
