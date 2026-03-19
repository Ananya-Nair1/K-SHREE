import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatelessWidget {
  final Map<String, dynamic> userData; 

  const NotificationsPage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    const Color primaryColor = Colors.teal; 
    
    // Extracting full geographic location
    final String unitNumber = userData['unit_number']?.toString() ?? '';
    final String wardId = (userData['ward']?.toString() ?? userData['ward_number']?.toString() ?? '');
    final String panchayat = userData['panchayat']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Unit Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder(
        // 1. Fetch ALL notifications for this panchayat intended for 'All Members'
        future: supabase
            .from('unit_notifications')
            .select()
            .ilike('panchayat', panchayat)
            .eq('target_audience', 'All Members')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final rawNotifications = snapshot.data as List<dynamic>? ?? [];

          // 2. Filter the notifications so members only see what belongs to them
          final notifications = rawNotifications.where((item) {
            final String? nUnit = item['unit_number']?.toString();
            final String? nWard = item['ward']?.toString();

            // If the notification is specifically for a different unit, hide it.
            if (nUnit != null && nUnit.isNotEmpty && nUnit != 'null' && nUnit != unitNumber) {
              return false;
            }

            // If the notification is specifically for a different ward, hide it.
            if (nWard != null && nWard.isNotEmpty && nWard != 'null' && nWard != wardId) {
              return false;
            }

            // Otherwise (it matches their unit, their ward, or is global to the panchayat), show it!
            return true;
          }).toList();

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
                
                // Safe check for boolean or string boolean
                final bool isUrgent = item['is_urgent'] == true || item['is_urgent']?.toString().toLowerCase() == 'true';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: isUrgent ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isUrgent ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                      child: Icon(
                        isUrgent ? Icons.crisis_alert : Icons.campaign,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text("URGENT", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
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