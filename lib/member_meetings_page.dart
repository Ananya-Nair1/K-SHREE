import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberMeetingsPage extends StatelessWidget {
  final Map<String, dynamic> memberData;

  const MemberMeetingsPage({Key? key, required this.memberData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    // Uses the actual unit_name passed from the Dashboard
    final String memberUnit = memberData['unit_name']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Meetings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Filters meetings strictly by the member's unit_name
        future: supabase.from('meetings').select().eq('unit_name', memberUnit).order('meeting_date', ascending: true), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          if (snapshot.hasError) return Center(child: Text("Error loading meetings: ${snapshot.error}"));

          final meetings = snapshot.data ?? [];

          if (meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No upcoming meetings for $memberUnit", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meet = meetings[index];
              
              DateTime meetDate;
              try { meetDate = DateTime.parse(meet['meeting_date']); } 
              catch (e) { meetDate = DateTime.now(); }
              
              final String displayDate = "${meetDate.day.toString().padLeft(2, '0')}-${meetDate.month.toString().padLeft(2, '0')}-${meetDate.year}";

              return Card(
                elevation: 3, shadowColor: Colors.black12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calendar_month, color: Colors.teal)),
                              const SizedBox(width: 12),
                              Text(displayDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green[200]!)),
                            child: Text(meet['status'].toString().toUpperCase(), style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildMeetingDetailRow(Icons.access_time, "Time", meet['meeting_time']),
                      const SizedBox(height: 8),
                      _buildMeetingDetailRow(Icons.location_on, "Venue", meet['venue']),
                      const SizedBox(height: 8),
                      _buildMeetingDetailRow(Icons.info_outline, "Purpose", meet['reason']),
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

  Widget _buildMeetingDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(children: [TextSpan(text: "$label: ", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)), TextSpan(text: value, style: const TextStyle(color: Colors.black87, fontSize: 14))]),
          ),
        ),
      ],
    );
  }
}