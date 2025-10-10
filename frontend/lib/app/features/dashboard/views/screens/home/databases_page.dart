// lib/screens/home/databases_page.dart
import 'package:flutter/material.dart';

class DatabasesPage extends StatelessWidget {
  const DatabasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Systems List Page\n\nThis will show your systems connections',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new database connection
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add database feature coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}