import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  String _getFirestoreDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login to use Meal Planner")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: AppTheme.secondaryColor, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('meal_plans')
                  .doc(_getFirestoreDateId(_selectedDay!))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<String, dynamic> meals = {};
                if (snapshot.hasData && snapshot.data!.exists) {
                  meals = snapshot.data!.data() as Map<String, dynamic>;
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildMealSection('Breakfast', meals['breakfast'], user.uid),
                    _buildMealSection('Lunch', meals['lunch'], user.uid),
                    _buildMealSection('Dinner', meals['dinner'], user.uid),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, Map<String, dynamic>? mealData, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            IconButton(
              icon: Icon(mealData == null ? Icons.add_circle_outline : Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _showRecipePicker(title, userId),
            ),
          ],
        ),
        if (mealData != null)
          GestureDetector(
            onTap: () {
               final recipe = Recipe(
                 id: mealData['id'],
                 title: mealData['title'],
                 image: mealData['image'],
                 author: mealData['author'] ?? 'Unknown',
                 authorEmail: '',
                 rating: mealData['rating'] ?? '5.0',
                 time: mealData['time'] ?? '20 min',
                 category: mealData['category'] ?? 'General',
                 calories: mealData['calories'] ?? '120 kcal',
                 protein: mealData['protein'] ?? '10g',
                 carbs: mealData['carbs'] ?? '15g',
               );
               Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (mealData['image'] != null && mealData['image'].toString().startsWith('http')) 
                      ? Image.network(mealData['image'], width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                      : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mealData['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${mealData['time'] ?? '20 min'} • ${mealData['rating'] ?? '5.0'} ★', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    tooltip: 'Mark as Cooked',
                    onPressed: () => _logAsCooked(userId, mealData),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                    onPressed: () => _removeMeal(title, userId),
                  )
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(child: Text("No meal planned", style: TextStyle(color: Colors.grey))),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _logAsCooked(String userId, Map<String, dynamic> mealData) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).collection('cooked_history').add({
      'title': mealData['title'],
      'calories': mealData['calories'] ?? '120 kcal',
      'protein': mealData['protein'] ?? '10g',
      'carbs': mealData['carbs'] ?? '15g',
      'timestamp': FieldValue.serverTimestamp(),
      'servings': 1,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mealData['title']} logged to Nutrition Dashboard!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showRecipePicker(String mealType, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Select a Recipe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final imageUrl = data['image'] ?? '';
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.startsWith('http') 
                                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image))
                                : const Icon(Icons.image),
                            ),
                            title: Text(data['title'] ?? 'No Title'),
                            subtitle: Text(data['category'] ?? 'General'),
                            onTap: () {
                              _addMeal(mealType, userId, doc.id, data);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addMeal(String mealType, String userId, String recipeId, Map<String, dynamic> recipeData) async {
    final dateId = _getFirestoreDateId(_selectedDay!);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc(dateId)
        .set({
      mealType.toLowerCase(): {
        'id': recipeId,
        'title': recipeData['title'],
        'image': recipeData['image'],
        'time': recipeData['time'],
        'rating': recipeData['rating'],
        'category': recipeData['category'],
        'author': recipeData['author'],
        'calories': recipeData['calories'] ?? '120 kcal',
        'protein': recipeData['protein'] ?? '10g',
        'carbs': recipeData['carbs'] ?? '15g',
      }
    }, SetOptions(merge: true));
  }

  Future<void> _removeMeal(String mealType, String userId) async {
    final dateId = _getFirestoreDateId(_selectedDay!);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc(dateId)
        .update({
      mealType.toLowerCase(): FieldValue.delete(),
    });
  }
}
