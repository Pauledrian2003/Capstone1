import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(userData['name']?[0] ?? 'U'),
                  ),
                  title: Text(userData['name'] ?? 'Unknown'),
                  subtitle: Text(userData['email'] ?? 'No email'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete User'),
                      ),
                      PopupMenuItem(
                        value: 'disable',
                        child: Text(userData['isActive'] ? 'Disable' : 'Enable'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _deleteUser(userId);
                      } else if (value == 'disable') {
                        await _toggleUserStatus(userId, !userData['isActive']);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Delete user's properties
      final properties = await FirebaseFirestore.instance
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in properties.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      // Delete Firebase Auth user
      final adminApp = FirebaseAuth.instance;
      await adminApp.currentUser?.delete();

    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'isActive': isActive});
  }
} 