import 'package:flutter/material.dart';
import '../../theme.dart';
import '../home_screen.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final List<String> _selectedAllergies = [];
  final List<Map<String, String>> _allergies = [
    {'name': 'Dairy', 'image': 'https://images.unsplash.com/photo-1550583724-125581cc2586'},
    {'name': 'Egg', 'image': 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f'},
    {'name': 'Gluten', 'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff'},
    {'name': 'Peanuts', 'image': 'https://images.unsplash.com/photo-1567333528477-14bf5275d788'},
    {'name': 'Shellfish', 'image': 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62'},
    {'name': 'Tree Nuts', 'image': 'https://images.unsplash.com/photo-1536511118276-88092261973a'},
    {'name': 'Soy', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'},
    {'name': 'Fish', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2'},
  ];

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
              value: 1.0,
              backgroundColor: AppTheme.secondaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              'Do You Have Any Allergies?',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your allergies to help us recommend recipes.',
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
                itemCount: _allergies.length,
                itemBuilder: (context, index) {
                  final allergy = _allergies[index];
                  bool isSelected = _selectedAllergies.contains(allergy['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedAllergies.remove(allergy['name']);
                        } else {
                          _selectedAllergies.add(allergy['name']!);
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
                              allergy['image']!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            allergy['name']!,
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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
