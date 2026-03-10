import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const NotificationsPage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // Extract user details
    final String unitNum = userData['unit_number']?.toString() ?? '';
    final String designation = userData['designation']?.toString().toUpperCase() ?? '';
    
    // Grab the ID to make sure we hide their own notifications
    final String myId = (userData['aadhar_number'] ?? userData['member_id'])?.toString() ?? 'UNKNOWN';

    // --- BUILD DYNAMIC FILTER ---
    List<String> orConditions = ['unit_number.eq.$unitNum'];

    // Rule for NHG Secretaries
    if (designation.contains('SECRETARY')) {
      orConditions.add('target_audience.eq.Secretaries');
    }

    // Rules for ADS Members / Chairperson
    if (designation.contains('ADS')) {
      orConditions.add('target_audience.eq.ADS Members');
      orConditions.add('unit_number.eq.ALL_ADS');
      orConditions.add('unit_number.eq.ADS');
    }

    final String orQuery = orConditions.join(',');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Notice Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: designation.contains('ADS') ? const Color(0xFF2B6CB0) : Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: supabase
            .from('unit_notifications')
            .select()
            .or(orQuery)
            // 👇 Hides notifications where created_by matches the logged-in user's ID
            .neq('created_by', myId) 
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: designation.contains('ADS') ? const Color(0xFF2B6CB0) : Colors.teal
              )
            );
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final notifications = snapshot.data as List<dynamic>? ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text("No new notifications.", style: TextStyle(color: Colors.grey)));
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
                        item['created_at'] != null 
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['created_at']).toLocal())
                          : 'Unknown Date',
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