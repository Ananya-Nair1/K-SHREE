
import 'package:flutter/material.dart';

class SecretaryTrainingsPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SecretaryTrainingsPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trainings"), backgroundColor: Colors.orange),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.school, color: Colors.orange, size: 30),
              title: Text("Micro-Enterprise Training", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Date: 25th March 2026\nVenue: Panchayat Hall"),
              isThreeLine: true,
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.computer, color: Colors.orange, size: 30),
              title: Text("Digital Literacy Workshop", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Date: 5th April 2026\nVenue: Online"),
              isThreeLine: true,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          // TODO: Add new training request/notification logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
