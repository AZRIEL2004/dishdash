import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';

class EditProfileFullScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileFullScreen({super.key, this.userData});

  @override
  State<EditProfileFullScreen> createState() => _EditProfileFullScreenState();
}

class _EditProfileFullScreenState extends State<EditProfileFullScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _presentationController;
  late TextEditingController _picController;
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData?['fullName'] ?? '');
    _usernameController = TextEditingController(text: widget.userData?['username'] ?? '');
    _presentationController = TextEditingController(text: widget.userData?['presentation'] ?? '');
    _picController = TextEditingController(text: widget.userData?['profilePic'] ?? '');
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update Firestore Data
        Map<String, dynamic> updateData = {
          'fullName': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'presentation': _presentationController.text.trim(),
          'profilePic': _picController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // If password field is filled, update Auth and log to DB
        if (_passwordController.text.isNotEmpty) {
          if (_passwordController.text.length < 6) {
            throw Exception("Password must be at least 6 characters");
          }
          await user.updatePassword(_passwordController.text.trim());
          updateData['passwordLastUpdated'] = FieldValue.serverTimestamp();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Full Name', _nameController, hint: 'Enter your full name'),
            const SizedBox(height: 20),
            _buildField('Username', _usernameController, hint: 'Choose a username'),
            const SizedBox(height: 20),
            _buildField('Bio / Presentation', _presentationController, maxLines: 3, hint: 'Tell the world about your cooking...'),
            const SizedBox(height: 20),
            _buildField('Profile Image URL', _picController, hint: 'Paste image link...'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            const Text('Leave blank if you don\'t want to change it.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'New Password (min 6 chars)',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, 
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
