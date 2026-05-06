import 'package:flutter/material.dart';
import '../theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'At DishDash, we are committed to protecting your privacy. We collect personal information such as your name, email address, and profile picture when you create an account. Additionally, we store the recipes, images, and videos you upload to provide our core services.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We also collect usage data to improve your experience, including:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildNumberedItem('1', 'Device information and unique identifiers.'),
            _buildNumberedItem('2', 'Recipes viewed, liked, or saved by you.'),
            _buildNumberedItem('3', 'Interactions with our AI Chef Assistant.'),
            _buildNumberedItem('4', 'Community engagement data such as followers and following.'),
            const SizedBox(height: 16),
            Text(
              'This data is used solely to enhance the DishDash community experience and provide personalized recipe recommendations.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildBulletedItem('We do not sell your personal data to third parties.'),
            _buildBulletedItem('We use industry-standard encryption to protect your account information.'),
            const SizedBox(height: 24),
            const Text(
              'AI Assistant and User Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'When using the AI Chef Assistant, the ingredients you provide are processed to generate unique recipes. Any content you publish to the community, including recipes and comments, is visible to other registered users of the application.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You retain ownership of the content you create, but by publishing it on DishDash, you grant us a license to display and distribute it within our platform.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'If you have any questions regarding this Privacy Policy, please reach out to us via the Help Center.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberedItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppTheme.textColor.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppTheme.textColor.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
