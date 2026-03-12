import 'package:flutter/material.dart';

class SecretaryReportsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SecretaryReportsPage({super.key, required this.userData});

  @override
  State<SecretaryReportsPage> createState() => _SecretaryReportsPageState();
}

class _SecretaryReportsPageState extends State<SecretaryReportsPage> {
  // TODO: Fetch meetings from Supabase where status == 'completed'
  final List<Map<String, dynamic>> completedMeetings = [
    {'id': 1, 'title': 'Monthly Review', 'date': '2026-02-15', 'has_report': false},
    {'id': 2, 'title': 'Financial Sync', 'date': '2026-01-10', 'has_report': true},
  ];

  void _uploadPdf(int meetingId) async {
    // TODO: Implement FilePicker logic to select PDF
    // Example: FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF Selection & Upload Module Opening...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meeting Reports"), backgroundColor: Colors.teal),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: completedMeetings.length,
        itemBuilder: (context, index) {
          final meeting = completedMeetings[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.picture_as_pdf, color: Colors.white),
              ),
              title: Text(meeting['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Date: ${meeting['date']}"),
              trailing: ElevatedButton.icon(
                onPressed: () => _uploadPdf(meeting['id']),
                icon: Icon(meeting['has_report'] ? Icons.edit : Icons.upload_file),
                label: Text(meeting['has_report'] ? "Edit" : "Add PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: meeting['has_report'] ? Colors.orange : Colors.teal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}