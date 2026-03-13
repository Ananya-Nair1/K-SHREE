import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatelessWidget {
  final String unitNumber;

  const NotificationsPage({Key? key, required this.unitNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    const Color primaryColor = Colors.teal; 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Unit Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder(
        future: supabase
            .from('unit_notifications')
            .select()
            .eq('unit_number', unitNumber)
            // Use ilike to be safe against extra spaces or case differences
            .ilike('target_audience', '%All Members%') 
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final notifications = snapshot.data as List<dynamic>? ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No local notifications yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Mark as read when the list loads successfully
          _saveLastSeen(unitNumber, notifications.first['created_at'].toString());

          return RefreshIndicator(
            onRefresh: () async => (context as Element).markNeedsBuild(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final bool isUrgent = item['is_urgent']?.toString() == 'true' || item['is_urgent'] == true;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isUrgent ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                      child: Icon(
                        isUrgent ? Icons.priority_high : Icons.campaign,
                        color: isUrgent ? Colors.red : Colors.teal.shade800,
                      ),
                    ),
                    title: Text(item['title'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(item['message'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(item['created_at'].toString()), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            if (isUrgent)
                              const Text("URGENT", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveLastSeen(String unit, String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_seen_notifications_$unit', timestamp);
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}