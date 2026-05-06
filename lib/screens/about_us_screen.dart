import 'package:flutter/material.dart';
import '../theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.restaurant_menu, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'DishDash',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to DishDash, your ultimate culinary companion! Our mission is to bring food enthusiasts, amateur cooks, and professional chefs together in one vibrant community.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Our Vision',
              'We believe that cooking is more than just preparing food; it is an art, a way to connect, and a global language. DishDash was created to make recipe sharing seamless, interactive, and inspiring.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Features',
              '• Discover trending recipes from around the world.\n• Share your own culinary creations with a global audience.\n• Connect with top chefs and follow their journey.\n• Use our AI Chef Assistant to create recipes from ingredients you already have.',
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              '© 2024 DishDash Inc. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: AppTheme.textColor.withValues(alpha: 0.7), height: 1.6, fontSize: 15),
        ),
      ],
    );
  }
}
