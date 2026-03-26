import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ads_mark_attendance_screen.dart'; // Make sure this import matches your file name!

class ADSMeetingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> meetingData;
  final Map<String, dynamic> adsData; // NEW: Added to pass to the attendance screen

  const ADSMeetingDetailsPage({
    super.key, 
    required this.meetingData,
    required this.adsData, // NEW
  });

  @override
  State<ADSMeetingDetailsPage> createState() => _ADSMeetingDetailsPageState();
}

class _ADSMeetingDetailsPageState extends State<ADSMeetingDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String meetId = widget.meetingData['meet_id'].toString();
    final Color primaryColor = const Color(0xFF2B6CB0); 
    
    // Check if meeting is already held to hide the attendance button
    final bool isHeld = widget.meetingData['status'] == 'HELD';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Meeting Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.meetingData['meeting_date']} at ${widget.meetingData['meeting_time']}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.location_on, "Venue: ${widget.meetingData['venue']}"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.info_outline, "Status: ${widget.meetingData['status']}"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.description, "Agenda: ${widget.meetingData['reason'] ?? 'No agenda'}"),
                  ],
                ),
              ),
            ),
            
            // NEW: Button to navigate to Attendance Hub
            if (!isHeld) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.how_to_reg, size: 22),
                  label: const Text("Open Attendance Hub", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ADSMarkAttendanceScreen(
                          meetId: meetId,
                          adsData: widget.adsData,
                        ),
                      ),
                    ).then((_) {
                      // When we pop back from the Attendance Screen, refresh this page
                      // so the new attendance records show up immediately.
                      setState(() {});
                    });
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            const Text("Attendance Record", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('attendance')
                  .select('*, Registered_Members(full_name, photo_url)')
                  .eq('meet_id', meetId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading database: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                final attendees = snapshot.data ?? [];

                if (attendees.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: const Text("No attendance recorded in the database yet.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: attendees.length,
                  itemBuilder: (context, index) {
                    final record = attendees[index];
                    final memberData = record['Registered_Members'] ?? {};
                    
                    final String name = memberData['full_name'] ?? record['full_name'] ?? "Unknown Member";
                    final String aadhar = record['aadhar_number'] ?? "N/A";
                    final String status = record['status']?.toString().toUpperCase() ?? "UNKNOWN";
                    final String? photoUrl = memberData['photo_url'];
                    
                    final bool isPresent = status == 'PRESENT';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null 
                              ? Icon(isPresent ? Icons.person : Icons.person_off, color: isPresent ? Colors.green : Colors.red.shade300)
                              : null,
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Aadhar: $aadhar"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isPresent ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade800))),
      ],
    );
  }
}