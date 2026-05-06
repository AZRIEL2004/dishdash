import 'package:flutter/material.dart';
import '../theme.dart';
import 'category_recipes_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, String>> _categories = const [
    {'name': 'Breakfast', 'image': 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666'},
    {'name': 'Lunch', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd'},
    {'name': 'Dinner', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'},
    {'name': 'Vegan', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'},
    {'name': 'Dessert', 'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777'},
    {'name': 'Drinks', 'image': 'https://images.unsplash.com/photo-1544145945-f904253d0c71'},
    {'name': 'Sea Food', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2'},
    {'name': 'Pasta', 'image': 'https://images.unsplash.com/photo-1473093226795-af9932fe5856'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryRecipesScreen(categoryName: category['name']!),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(category['image']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(16),
                child: Text(
                  category['name']!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
