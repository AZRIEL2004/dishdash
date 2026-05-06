import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _chefController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController(text: '5.0');
  
  bool _isLoading = false;
  String _selectedCategory = 'Breakfast';
  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Vegan', 'Dessert', 'Drinks'];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _chefController.text = user.displayName ?? user.email?.split('@')[0] ?? '';
    }
  }

  Future<void> _publishRecipe() async {
    if (_nameController.text.isEmpty || _imageUrlController.text.isEmpty || _chefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Name, Image URL, and Chef Name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final recipeData = {
        'title': _nameController.text.trim(),
        'author': _chefController.text.trim(),
        'description': _descController.text.trim(),
        'image': _imageUrlController.text.trim(),
        'videoUrl': _videoUrlController.text.trim().isEmpty 
            ? 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4' 
            : _videoUrlController.text.trim(),
        'category': _selectedCategory,
        'time': _timeController.text.trim(),
        'calories': _caloriesController.text.trim(),
        'authorEmail': user?.email ?? 'Anonymous',
        'authorImage': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        'rating': _ratingController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user?.uid,
      };

      final recipeRef = await FirebaseFirestore.instance.collection('recipes').add(recipeData);
      
      if (user != null) {
        final followersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('followers')
            .get();

        for (var doc in followersSnapshot.docs) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': doc.id,
            'title': 'New Recipe!',
            'body': '${_chefController.text} published a new recipe: ${_nameController.text}',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'recipe',
            'recipeId': recipeRef.id,
          });
        }
      }
      
      if (mounted) _showSuccessPopup(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _nameController.clear();
    _descController.clear();
    _imageUrlController.clear();
    _videoUrlController.clear();
    _timeController.clear();
    _caloriesController.clear();
    _ratingController.text = '5.0';
  }

  @override
  Widget build(BuildContext context) {
    // Check if the screen can be popped (i.e., if it was pushed as a full page)
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recipe', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Only show back button if we're NOT in a Tab
        leading: canPop ? IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ) : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _publishRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD6D6),
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearFields,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD6D6),
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                // Focus video url field
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Color(0xFFFF8A8A), size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text('Add video recipe', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInputField('Video Network URL', 'Paste video link (mp4 or YouTube)...', controller: _videoUrlController),
            const SizedBox(height: 20),
            _buildInputField('Image Network URL', 'Paste image link from Unsplash...', controller: _imageUrlController),
            const SizedBox(height: 20),
            _buildInputField('Recipe Name', 'e.g. Italian Pasta', controller: _nameController),
            const SizedBox(height: 20),
            _buildInputField('Chef Name', 'e.g. Chef John', controller: _chefController),
            const SizedBox(height: 20),
            _buildInputField('Description', 'Write about your recipe...', isLarge: true, controller: _descController),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((String category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildInputField('Cooking Time', '30 min', controller: _timeController)),
                const SizedBox(width: 20),
                Expanded(child: _buildInputField('Calories', '120 kcal', controller: _caloriesController)),
              ],
            ),
            const SizedBox(height: 20),
            _buildInputField('Rating', 'e.g. 4.5', controller: _ratingController),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, {bool isLarge = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: isLarge ? 4 : 1,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: const Color(0xFFF5F5F5),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Recipe Published!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Your recipe has been successfully saved to our database.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFields();
              },
              child: const Text('Add Another'),
            ),
          ],
        ),
      ),
    );
  }
}
