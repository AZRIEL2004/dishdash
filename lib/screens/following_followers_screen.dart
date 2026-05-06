import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'chef_profile_screen.dart';

class FollowingFollowersScreen extends StatefulWidget {
  final int initialIndex;
  final String userId;

  const FollowingFollowersScreen({super.key, required this.initialIndex, required this.userId});

  @override
  State<FollowingFollowersScreen> createState() => _FollowingFollowersScreenState();
}

class _FollowingFollowersScreenState extends State<FollowingFollowersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('@dianne_r', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16)), // Placeholder handle
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Following'),
              Tab(text: 'Followers'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.secondaryColor.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('following'),
                _buildUserList('followers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String collectionPath) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection(collectionPath).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text('No one here yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final userId = docs[index].id;
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox.shrink();
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) return const SizedBox.shrink();

                final name = userData['fullName'] ?? 'User';
                if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery)) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChefProfileScreen(userId: userId, userData: userData))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: userData['profilePic'] != null && userData['profilePic'].toString().isNotEmpty
                        ? NetworkImage(userData['profilePic'])
                        : const NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80'),
                  ),
                  title: Text('@${name.toLowerCase().replaceAll(' ', '_')}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  subtitle: Text(name, style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(80, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Following', style: TextStyle(fontSize: 12)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () => _showOptionsSheet(context, name, userData['profilePic'] ?? ''),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showOptionsSheet(BuildContext context, String name, String pic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : const NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80'),
                ),
                const SizedBox(width: 12),
                Text('@${name.toLowerCase().replaceAll(' ', '_')}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Manage notifications', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.left),
            ListTile(
              title: const Text('Notifications', style: TextStyle(fontSize: 14)),
              trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppTheme.primaryColor),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('Block Account', style: TextStyle(fontSize: 14)),
              trailing: Switch(value: false, onChanged: (v) {}, activeColor: AppTheme.primaryColor),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              title: Text('Report', style: TextStyle(fontSize: 14)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
