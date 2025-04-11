import 'package:afk/screens/admin_dashboard.dart';
import 'package:afk/screens/main_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminService {
  static Future<bool> checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return docSnap.data()?['role'] == 'admin';
  }

  static Future<void> makeUserAdmin(String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'role': 'admin'});
  }

  static Future<void> removeAdminRole(String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'role': 'user'});
  }

  static void checkAndNavigate(BuildContext context) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (userDoc.data()?['role'] == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDashboard()),
      );
    }
  }
} 