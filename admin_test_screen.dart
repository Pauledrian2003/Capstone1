import 'package:flutter/material.dart';
import 'package:afk/services/admin_service.dart';

class AdminTestScreen extends StatelessWidget {
  const AdminTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Test'),
      ),
      body: Center(
        child: FutureBuilder<bool>(
          future: AdminService.checkAdminStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Is Admin: ${snapshot.data}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
} 