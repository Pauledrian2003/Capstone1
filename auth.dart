import 'package:afk/screens/admin_dashboard.dart';
import 'package:afk/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  Future<bool> checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return docSnap.data()?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, userSnapshot) {
        if (userSnapshot.hasData) {
          return FutureBuilder<bool>(
            future: checkAdminStatus(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.hasData) {
                return adminSnapshot.data! 
                    ? const AdminDashboard() 
                    : const MainDashboard();
              }
              return const Center(child: CircularProgressIndicator());
            },
          );
        }
        return const OnboardingScreen();
      },
    );
  }
}
