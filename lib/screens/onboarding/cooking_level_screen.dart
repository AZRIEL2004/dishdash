import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import 'preferences_screen.dart';

class CookingLevelScreen extends StatefulWidget {
  const CookingLevelScreen({super.key});

  @override
  State<CookingLevelScreen> createState() => _CookingLevelScreenState();
}

class _CookingLevelScreenState extends State<CookingLevelScreen> {
  String? _selectedLevel;
  bool _isLoading = false;

  final List<Map<String, String>> _levels = [
    {'level': 'Novice', 'desc': 'I am new to cooking and want to learn the basics.'},
    {'level': 'Intermediate', 'desc': 'I know the basics and want to try more complex recipes.'},
    {'level': 'Advanced', 'desc': 'I am a confident cook and enjoy experimenting.'},
    {'level': 'Professional', 'desc': 'I am a trained chef or have professional experience.'},
  ];

  Future<void> _saveCookingLevel() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'cookingLevel': _selectedLevel,
          'email': user.email,
          'fullName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        }, SetOptions(merge: true));
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PreferencesScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(
              value: 0.33,
              backgroundColor: AppTheme.secondaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              'What is Your Cooking Level?',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your cooking level to help us recommend recipes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  bool isSelected = _selectedLevel == level['level'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLevel = level['level']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.secondaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['level']!,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(level['desc']!, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: ElevatedButton(
                onPressed: (_selectedLevel == null || _isLoading) ? null : _saveCookingLevel,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
