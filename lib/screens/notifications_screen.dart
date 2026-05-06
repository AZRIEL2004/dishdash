import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Helper function to create a test notification for the current user
  Future<void> _createTestNotification(String uid) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': uid,
      'title': 'Test Working!',
      'body': 'If you see this, your notifications are now dynamic and working.',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'general',
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.translate('please_login'))));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('notification'), style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Hidden Test Button: Tap the 'info' icon to create a test notification for yourself
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
            onPressed: () => _createTestNotification(user.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Firestore Error: ${snapshot.error}");
            if (snapshot.error.toString().contains('requires an index')) {
              return _buildIndexErrorUI(context);
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.translate('no_notifications'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _createTestNotification(user.uid),
                    child: const Text("Create Test Notification"),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildNotificationItem(docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildIndexErrorUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
            SizedBox(height: 16),
            Text('Database Index Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Firebase is blocking the query. Please click the link in your Android Studio "Run" tab to create the index.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Notification';
    final String body = data['body'] ?? '';
    final String type = data['type'] ?? 'general';
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

    IconData icon;
    switch (type) {
      case 'follow': icon = Icons.person_add_alt_1; break;
      case 'recipe': icon = Icons.restaurant_menu; break;
      default: icon = Icons.notifications_active;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(_getTimeAgo(timestamp), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime postDate = timestamp.toDate();
    final Duration diff = DateTime.now().difference(postDate);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
