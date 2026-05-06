import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'chef_profile_screen.dart';

class TopChefsScreen extends StatefulWidget {
  const TopChefsScreen({super.key});

  @override
  State<TopChefsScreen> createState() => _TopChefsScreenState();
}

class _TopChefsScreenState extends State<TopChefsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search chefs...', border: InputBorder.none),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            )
          : const Text('Top Chef', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppTheme.textColor), 
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = "";
                _searchController.clear();
              }
            }),
          ),
          IconButton(icon: const Icon(Icons.notifications_none, color: AppTheme.textColor), onPressed: () {}),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildTopChefsContent(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text('Type a name to search for chefs'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final chefs = snapshot.data!.docs.where((doc) {
          final name = (doc['fullName'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (chefs.isEmpty) return const Center(child: Text('No chefs found.'));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: chefs.length,
          itemBuilder: (context, index) {
            final data = chefs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(data['profilePic'] ?? 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80'),
                onBackgroundImageError: (_, __) => const Icon(Icons.person),
              ),
              title: Text(data['fullName'] ?? 'Chef'),
              subtitle: Text('${data['cookingLevel'] ?? 'Professional'} Chef'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChefProfileScreen(userId: chefs[index].id, userData: data))),
            );
          },
        );
      },
    );
  }

  Widget _buildTopChefsContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Most Viewed Chefs'),
        const SizedBox(height: 16),
        _buildFilteredChefList('followersCount'), 
        const SizedBox(height: 32),
        _buildSectionHeader('Most Liked Chefs'),
        const SizedBox(height: 16),
        _buildFilteredChefList('totalRecipeLikes'), 
        const SizedBox(height: 32),
        _buildSectionHeader('New Chefs'),
        const SizedBox(height: 16),
        _buildFilteredChefList('createdAt'), 
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: AppTheme.primaryColor))),
      ],
    );
  }

  Widget _buildFilteredChefList(String sortBy) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(sortBy, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || (snapshot.hasData && snapshot.data!.docs.isEmpty)) {
          // If the sorted query fails or is empty, show all users as a fallback
          return _buildAllUsersFallback();
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return _buildHorizontalList(context, snapshot.data!.docs);
      },
    );
  }

  Widget _buildAllUsersFallback() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('No chefs found.');
        return _buildHorizontalList(context, docs);
      },
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<QueryDocumentSnapshot> users) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final data = users[index].data() as Map<String, dynamic>;
          final String name = data['fullName'] ?? 'Chef';
          final String pic = data['profilePic'] ?? 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c';
          final String level = data['cookingLevel'] ?? 'Professional';

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChefProfileScreen(userId: users[index].id, userData: data))),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(pic),
                    onBackgroundImageError: (_, __) => const Icon(Icons.person),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('$level Chef', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
