import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../models/recipe.dart';
import 'home_screen.dart';

class LeaveReviewScreen extends StatefulWidget {
  final Recipe recipe;

  const LeaveReviewScreen({super.key, required this.recipe});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _recommend = true;

  Future<void> _submitReview() async {
    if (_rating == 0 || _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and a comment')),
      );
      return;
    }

    if (widget.recipe.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Recipe ID is missing.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final userData = userDoc.data();
      final String myName = userData?['fullName'] ?? 'Someone';

      // 1. Save review
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .collection('reviews')
          .add({
        'userId': user?.uid,
        'userName': myName,
        'userImage': userData?['profilePic'] ?? '',
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'recommend': _recommend,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Fetch Chef's UID from the recipe
      final recipeDoc = await FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id).get();
      final String? chefId = recipeDoc.data()?['userId'];

      // 3. Notify the Chef (only if it's not the chef commenting on their own recipe)
      if (chefId != null && chefId != user?.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': chefId,
          'title': 'New Comment!',
          'body': '$myName commented on your recipe "${widget.recipe.title}"',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'recipe',
          'recipeId': widget.recipe.id,
        });
      }

      if (mounted) _showThankYouDialog();
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

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Thank You For Your Review!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('Your feedback helps the community discover the best recipes.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Go To Home'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave A Review', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(widget.recipe.image, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(widget.recipe.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
              const SizedBox(height: 32),
              const Center(child: Text('Your overall rating', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              const Text('Leave us Review!', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Write your experience here...'),
              ),
              const SizedBox(height: 24),
              const Text('Do you recommend this recipe?', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<bool>(value: false, groupValue: _recommend, onChanged: (v) => setState(() => _recommend = v!)),
                  const Text('No'),
                  const SizedBox(width: 20),
                  Radio<bool>(value: true, groupValue: _recommend, onChanged: (v) => setState(() => _recommend = v!)),
                  const Text('Yes'),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
