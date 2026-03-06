import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  final String unitNumber;

  const NotificationsPage({Key? key, required this.unitNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Unit Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: supabase
            .from('unit_notifications')
            .select()
            .eq('unit_number', unitNumber)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          final notifications = snapshot.data as List<dynamic>? ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final bool isUrgent = item['is_urgent'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isUrgent ? Colors.red.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    child: Icon(
                      isUrgent ? Icons.priority_high : Icons.campaign,
                      color: isUrgent ? Colors.red : Colors.amber.shade800,
                    ),
                  ),
                  title: Text(
                    item['title'] ?? 'Update',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(item['message'] ?? '', style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(DateTime.parse(item['created_at'])),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}