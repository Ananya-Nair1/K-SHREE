
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NotificationPage({super.key, required this.userData});

  @override
  State<NotificationPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationPage> {
  late final Stream<List<Map<String, dynamic>>> _notificationsStream;

  // Role Checks
  bool get _isAds {
    final String designation = widget.userData['designation']?.toString().toUpperCase() ?? '';
    return designation.contains('ADS');
  }

  bool get _isSecretary {
    final String designation = widget.userData['designation']?.toString().toUpperCase() ?? '';
    return designation.contains('SECRETARY') || designation.contains('ADS'); // ADS can see Secretary notices too
  }

  @override
  void initState() {
    super.initState();
    
    final String unitNum = widget.userData['unit_number']?.toString() ?? '';
    List<String> targetUnits = [unitNum];
    
    if (_isAds) {
      targetUnits.add('ADS');
    }

    _notificationsStream = Supabase.instance.client
        .from('unit_notifications')
        .stream(primaryKey: ['id'])
        .inFilter('unit_number', targetUnits)
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _isAds ? const Color(0xFF2B6CB0) : Colors.teal;
    final bgColor = _isAds ? const Color(0xFFF4F8FB) : const Color(0xFFF4F7F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Notice Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // ---> THE PRIVACY FILTER <---
          final rawNotifications = snapshot.data ?? [];
          final notifications = rawNotifications.where((notif) {
            final target = notif['target_audience'] ?? 'All Members';
            
            if (target == 'All Members') return true; // Everyone sees these
            if (target == 'Secretaries' && _isSecretary) return true; // Only Secs & ADS see these
            if (target == 'ADS Members' && _isAds) return true; // Only ADS see these
            
            return false; // Hide it from this user!
          }).toList();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No new announcements", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final bool isUrgent = notif['is_urgent'] == true;
              
              final DateTime date = DateTime.parse(notif['created_at']).toLocal();
              final String dateString = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              final String timeString = TimeOfDay.fromDateTime(date).format(context);

              final cardColor = isUrgent ? const Color(0xFFFFF5F5) : Colors.white;
              final borderColor = isUrgent ? Colors.redAccent.withOpacity(0.4) : Colors.grey.withOpacity(0.2);
              final iconColor = isUrgent ? Colors.redAccent : primaryColor;
              final iconData = isUrgent ? Icons.warning_amber_rounded : Icons.campaign_outlined;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                color: cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    radius: 25,
                    child: Icon(iconData, color: iconColor, size: 28),
                  ),
                  title: Text(
                    notif['title'] ?? 'Announcement', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: isUrgent ? Colors.red[900] : const Color(0xFF2D3748))
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['message'] ?? '', 
                          style: TextStyle(color: Colors.blueGrey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text("$dateString at $timeString", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                            
                            // Visual tag so they know who it's meant for
                            if (notif['target_audience'] != 'All Members') ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEBF8FF), borderRadius: BorderRadius.circular(4)),
                                child: Text(notif['target_audience'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF2B6CB0), fontWeight: FontWeight.bold)),
                              )
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context, 
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        title: Row(
                          children: [
                            Icon(iconData, color: iconColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text(notif['title'] ?? 'Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                          ],
                        ),
                        content: Text(notif['message'] ?? '', style: const TextStyle(fontSize: 15, height: 1.4)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context), 
                            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold))
                          )
                        ],
                      )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}