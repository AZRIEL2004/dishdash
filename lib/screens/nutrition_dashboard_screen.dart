import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class NutritionDashboardScreen extends StatelessWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Dashboard', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .doc(user?.uid)
            .collection('cooked_history')
            .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          double totalCalories = 0;
          double totalProtein = 0;
          double totalCarbs = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalCalories += _parseValue(data['calories']);
            totalProtein += _parseValue(data['protein']);
            totalCarbs += _parseValue(data['carbs']);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Based on ${docs.length} meals cooked this week', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                
                _buildNutritionCard('Total Calories', totalCalories.toInt().toString(), 'kcal', Colors.orange, Icons.local_fire_department),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildNutritionCard('Protein', totalProtein.toInt().toString(), 'g', Colors.blue, Icons.fitness_center)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNutritionCard('Carbs', totalCarbs.toInt().toString(), 'g', Colors.green, Icons.bakery_dining)),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text('Recent Cooked Meals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (docs.isEmpty) 
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No meals recorded this week.")))
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['timestamp'] as Timestamp).toDate();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['title'] ?? 'Meal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(DateFormat('MMM dd, hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('${data['calories']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  double _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final String str = value.toString();
    final RegExp regExp = RegExp(r'(\d+\.?\d*)');
    final match = regExp.firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  Widget _buildNutritionCard(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: color, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
