import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  final String unitNumber;

  const NotificationsPage({Key? key, required this.unitNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    // Using the ADS Blue theme color
    const Color primaryColor = Color(0xFF2B6CB0); 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Unit Updates', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder(
        // Fetching notifications filtered by the specific unit
        future: supabase
            .from('unit_notifications')
            .select()
            .eq('unit_number', unitNumber)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final notifications = snapshot.data as List<dynamic>? ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => (context as Element).markNeedsBuild(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final bool isUrgent = item['is_urgent'] ?? false;

                return Card(
                  elevation: 2,
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
                        Text(item['message'] ?? '', 
                          style: const TextStyle(color: Colors.black87, fontSize: 14)
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(item['created_at']),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            if (isUrgent)
                              const Text("URGENT", 
                                style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)
                              ),
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

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}