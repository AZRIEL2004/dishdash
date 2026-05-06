import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import 'allergies_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final List<String> _selectedCuisines = [];
  bool _isLoading = false;

  final List<Map<String, String>> _cuisines = [
    {'name': 'Indian', 'image': 'https://images.unsplash.com/photo-1585932231552-05452d3a0428'},
    {'name': 'Italian', 'image': 'https://images.unsplash.com/photo-1533777419517-3e4017e2e15a'},
    {'name': 'Asian', 'image': 'https://images.unsplash.com/photo-1541696432-82c6da8ce7bf'},
    {'name': 'Chinese', 'image': 'https://images.unsplash.com/photo-1552611052-33e04de081de'},
    {'name': 'Mexican', 'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38'},
    {'name': 'French', 'image': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929'},
    {'name': 'American', 'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288'},
    {'name': 'Japanese', 'image': 'https://images.unsplash.com/photo-1526318896980-cf78c088247c'},
  ];

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseDatabase.instance.ref().child('users').child(user.uid).update({
          'preferences': _selectedCuisines,
        });
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllergiesScreen()),
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
              value: 0.66,
              backgroundColor: AppTheme.secondaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              'Select Your Cuisines Preferences',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your cuisines preferences to help us recommend recipes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _cuisines.length,
                itemBuilder: (context, index) {
                  final cuisine = _cuisines[index];
                  bool isSelected = _selectedCuisines.contains(cuisine['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCuisines.remove(cuisine['name']);
                        } else {
                          _selectedCuisines.add(cuisine['name']!);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              cuisine['image']!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cuisine['name']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AllergiesScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedCuisines.isEmpty || _isLoading) ? null : _savePreferences,
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Continue'),
                    ),
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
