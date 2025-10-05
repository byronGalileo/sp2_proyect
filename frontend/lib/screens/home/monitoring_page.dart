// lib/screens/home/monitoring_page.dart
import 'package:flutter/material.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Monitoring Page\n\nThis will show monitoring results and schedules',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}