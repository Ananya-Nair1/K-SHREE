import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminComplaintsPage extends StatelessWidget {
  const AdminComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client.from('complaints').stream(primaryKey: ['id']).order('created_at');

    return Scaffold(
      appBar: AppBar(title: const Text("Member Complaints"), backgroundColor: Colors.orange),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final complaints = snapshot.data!;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, i) {
              final item = complaints[i];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(item['subject']),
                  subtitle: Text("From: ${item['member_name']} | Status: ${item['status']}"),
                  trailing: const Icon(Icons.reply, color: Colors.blue),
                  onTap: () => _showReplyDialog(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showReplyDialog(BuildContext context, Map<String, dynamic> complaint) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reply to: ${complaint['subject']}"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Enter your response here...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('complaints').update({
                'admin_reply': controller.text.trim(),
                'status': 'Resolved' // Automatically mark as resolved
              }).eq('id', complaint['id']);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Send Reply"),
          ),
        ],
      ),
    );
  }
}