import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String? id; // Firestore Document ID
  final String title;
  final String image;
  final String author;
  final String authorEmail;
  final String authorImage;
  final String rating;
  final String time;
  final String category;
  final String calories;
  final String protein;
  final String carbs;
  final String description;
  final List<String> ingredients;
  final String videoUrl;
  final bool isUserRecipe;

  Recipe({
    this.id,
    required this.title,
    required this.image,
    required this.author,
    required this.authorEmail,
    this.authorImage = 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
    required this.rating,
    required this.time,
    required this.category,
    this.calories = '120 kcal',
    this.protein = '10g',
    this.carbs = '15g',
    this.description = 'This recipe is a classic way to enjoy delicious food. The secret is in the fresh ingredients and careful preparation.',
    this.ingredients = const ['2 units Tomato', '1 unit Onion', '3 cloves Garlic', '500g Meat'],
    this.videoUrl = '',
    this.isUserRecipe = false,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      image: data['image'] ?? '',
      author: data['author'] ?? 'Anonymous',
      authorEmail: data['authorEmail'] ?? '',
      authorImage: data['authorImage'] ?? 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
      rating: data['rating'] ?? '5.0',
      time: data['time'] ?? '20 min',
      category: data['category'] ?? 'General',
      calories: data['calories'] ?? '120 kcal',
      protein: data['protein'] ?? '10g',
      carbs: data['carbs'] ?? '15g',
      description: data['description'] ?? 'This recipe is a classic way to enjoy delicious food.',
      ingredients: List<String>.from(data['ingredients'] ?? ['2 units Tomato', '1 unit Onion', '3 cloves Garlic', '500g Meat']),
      videoUrl: data['videoUrl'] ?? '',
      isUserRecipe: data['isUserRecipe'] ?? false,
    );
  }
}

final List<Recipe> recipes = [];
