import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class TrendingRecipesScreen extends StatelessWidget {
  const TrendingRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Recipes', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppTheme.textColor), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none, color: AppTheme.textColor), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No recipes found.'));
          }

          // Featured recipe (first one)
          final featuredData = docs.first.data() as Map<String, dynamic>;
          final featuredRecipe = _mapToRecipe(featuredData, docs.first.id);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Most Viewed Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildFeaturedCard(context, featuredRecipe),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Latest Trending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: AppTheme.primaryColor))),
                ],
              ),
              const SizedBox(height: 12),
              ...docs.skip(1).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildTrendingListItem(context, _mapToRecipe(data, doc.id));
              }).toList(),
            ],
          );
        }
      ),
    );
  }

  Recipe _mapToRecipe(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      title: data['title'] ?? 'No Title',
      image: data['image'] ?? '',
      author: data['author'] ?? 'Anonymous',
      authorEmail: data['authorEmail'] ?? 'anonymous@example.com',
      rating: data['rating'] ?? '5.0',
      time: data['time'] ?? '20 min',
      category: data['category'] ?? 'General',
      description: data['description'] ?? 'This recipe is a classic way to enjoy delicious food. The secret is in the fresh ingredients and careful preparation.',
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.primaryColor,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _buildRecipeImage(recipe.image, width: double.infinity, height: double.infinity),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(recipe.time, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const Spacer(),
                      const CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.play_arrow, size: 16, color: AppTheme.primaryColor)),
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

  Widget _buildTrendingListItem(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildRecipeImage(recipe.image),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('By ${recipe.author}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppTheme.primaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text(recipe.time, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(recipe.rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite_border, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(String imageStr, {double? width, double? height}) {
    if (imageStr.isEmpty) return Container(color: Colors.grey[200], child: const Icon(Icons.image));
    if (imageStr.startsWith('http')) {
      return Image.network(imageStr, fit: BoxFit.cover, width: width, height: height);
    } else if (imageStr.startsWith('data:image')) {
      try {
        final base64Str = imageStr.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: width, height: height);
      } catch (e) {
        return const Center(child: Icon(Icons.error));
      }
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.image));
  }
}
