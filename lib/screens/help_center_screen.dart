import 'package:flutter/material.dart';
import '../theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int _selectedTab = 0; // 0 for FAQ, 1 for Contact Us
  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Account', 'Services'];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I add a new recipe?',
      'answer': 'To add a new recipe, go to the "Add" tab in the bottom navigation bar, fill in the details, and tap "Publish".',
      'category': 'General'
    },
    {
      'question': 'Can I edit my profile?',
      'answer': 'Yes, go to your Profile tab, tap "Edit Profile", and update your information.',
      'category': 'Account'
    },
    {
      'question': 'How do I follow other chefs?',
      'answer': 'You can follow other chefs by visiting their profile from the Community or Top Chef screens and tapping the "Follow" button.',
      'category': 'Services'
    },
    {
      'question': 'Is DishDash free to use?',
      'answer': 'Yes, DishDash is completely free for all users to share and discover recipes.',
      'category': 'General'
    },
    {
      'question': 'How do I delete my account?',
      'answer': 'Go to Settings > Delete Account to permanently remove your account and data.',
      'category': 'Account'
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {'name': 'Website', 'icon': Icons.language},
    {'name': 'Facebook', 'icon': Icons.facebook},
    {'name': 'Whatsapp', 'icon': Icons.chat_bubble_outline},
    {'name': 'Instagram', 'icon': Icons.camera_alt_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
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
          // Top Tabs (FAQ / Contact Us)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTab('FAQ', 0)),
                  Expanded(child: _buildTab('Contact Us', 1)),
                ],
              ),
            ),
          ),

          // Categories (Only visible for FAQ tab)
          if (_selectedTab == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: AppTheme.primaryColor.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                filled: true,
                fillColor: const Color(0xFFFFEFEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 0 ? _buildFAQList() : _buildContactList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFFFEFEF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _faqs.where((f) => f['category'] == _selectedCategory).length,
      itemBuilder: (context, index) {
        final faq = _faqs.where((f) => f['category'] == _selectedCategory).toList()[index];
        return _buildFAQItem(faq['question']!, faq['answer']!);
      },
    );
  }

  Widget _buildContactList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _contactOptions.length,
      itemBuilder: (context, index) {
        final option = _contactOptions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFEFEF)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(option['icon'], color: Colors.white, size: 20),
            ),
            title: Text(
              option['name'],
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textColor),
            ),
            trailing: const Icon(Icons.play_arrow_outlined, color: AppTheme.primaryColor),
            onTap: () {
              // Handle contact action
            },
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEFEF)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textColor, fontSize: 15),
        ),
        iconColor: AppTheme.primaryColor,
        collapsedIconColor: AppTheme.primaryColor,
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: AppTheme.textColor.withOpacity(0.7), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
