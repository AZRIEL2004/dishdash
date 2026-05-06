import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _recentSearches = ['Pasta', 'Salad', 'Burger', 'Sushi', 'Dessert'];

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _addRecentSearch(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _addRecentSearch(value);
              },
              decoration: InputDecoration(
                hintText: 'Search recipe...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.primaryColor),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged("");
                  },
                ),
                filled: true,
                fillColor: AppTheme.secondaryColor.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty) ...[
              const Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _recentSearches.map((search) => _buildSearchChip(search)).toList(),
              ),
              const SizedBox(height: 32),
              const Text('Recommended For You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ] else ...[
              const Text('Search Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? "").toString().toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No recipes found.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final recipe = Recipe(
                        id: docs[index].id,
                        title: data['title'] ?? 'No Title',
                        image: data['image'] ?? '',
                        author: data['author'] ?? 'Anonymous',
                        authorEmail: data['authorEmail'] ?? 'anonymous@example.com',
                        rating: data['rating'] ?? '5.0',
                        time: data['time'] ?? '20 min',
                        category: data['category'] ?? 'General',
                        description: data['description'] ?? 'This recipe is a classic way to enjoy delicious food.',
                      );

                      return GestureDetector(
                        onTap: () {
                          _addRecentSearch(recipe.title);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: _buildRecipeImage(recipe.image),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.orange, size: 14),
                                        const SizedBox(width: 4),
                                        Text(recipe.rating, style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                                        const SizedBox(width: 4),
                                        Text(recipe.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildRecipeImage(String imageStr) {
    if (imageStr.startsWith('http')) {
      return Image.network(imageStr, fit: BoxFit.cover);
    } else if (imageStr.startsWith('data:image')) {
      try {
        final base64Str = imageStr.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (e) {
        return const Center(child: Icon(Icons.error));
      }
    }
    return const Center(child: Icon(Icons.image));
  }
}
