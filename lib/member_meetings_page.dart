import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberMeetingsPage extends StatefulWidget {
  final String unitNumber; 

  const MemberMeetingsPage({Key? key, required this.unitNumber}) : super(key: key);

  @override
  State<MemberMeetingsPage> createState() => _MemberMeetingsPageState();
}

class _MemberMeetingsPageState extends State<MemberMeetingsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Upcoming Meetings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: supabase
            .from('meetings')
            .select()
            .eq('unit_name', widget.unitNumber) 
            .order('meeting_date', ascending: true), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final meetings = snapshot.data as List<dynamic>? ?? [];

          if (meetings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No upcoming meetings scheduled.", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _buildMeetingCard(meeting);
            },
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    // Dynamic status color based on your DB 'status' column
    final isScheduled = meeting['status'] == 'scheduled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting['meeting_level'] ?? 'NHG Meeting', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 4),
                      // UPDATED: Now fetches the 'reason' from your database!
                      Text(meeting['reason'] ?? 'No specific agenda provided', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                // NEW: Status Badge
                if (meeting['status'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isScheduled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      meeting['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: isScheduled ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Text(meeting['meeting_date'] ?? 'TBA', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(meeting['meeting_time'] ?? 'TBA', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(meeting['venue'] ?? 'Location TBA', style: const TextStyle(color: Colors.blueGrey))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}