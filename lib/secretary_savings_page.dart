import 'package:flutter/material.dart';

class SavingsPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SavingsPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Savings"), backgroundColor: Colors.pink),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Total Savings", style: TextStyle(fontSize: 20, color: Colors.grey)),
            SizedBox(height: 10),
            Text("₹ 0.00", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.pink)),
          ],
        ),
      ),
    );
  }
}