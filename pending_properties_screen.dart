import 'package:afk/screens/property_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingPropertiesScreen extends StatelessWidget {
  const PendingPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Properties'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // First check if user is admin
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null || userData['role'] != 'admin') {
            return const Center(child: Text('Access denied. Admin only.'));
          }

          // If user is admin, show pending properties
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('properties')
                .where('approvalStatus', isEqualTo: 'pending')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final properties = snapshot.data!.docs;

              if (properties.isEmpty) {
                return const Center(
                  child: Text('No pending properties to review'),
                );
              }

              return ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  final data = property.data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text(data['name'] ?? 'Unnamed Property'),
                      subtitle: Text(
                          'Posted by: ${data['userInfo']?['name'] ?? 'Unknown'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approveProperty(property.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectProperty(property.id),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailScreen(
                              propertyData: data,
                              heroTag: property.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveProperty(String propertyId) async {
    await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .update({
      'approvalStatus': 'approved',
      'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectProperty(String propertyId) async {
    await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .update({
      'approvalStatus': 'rejected',
      'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
