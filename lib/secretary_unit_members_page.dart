import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UnitMembersPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UnitMembersPage({super.key, required this.userData});

  // --- ATTENDANCE CALCULATION LOGIC ---
  Future<double> _calculateAttendance(String aadharNumber, String unitNumber) async {
    try {
      final supabase = Supabase.instance.client;
      debugPrint("--- ATTENDANCE CHECK START ---");
      debugPrint("Checking Aadhar: $aadharNumber for Unit: $unitNumber");

      // 1. Get total HELD meetings for this unit
      final meetingsData = await supabase
          .from('meetings')
          .select('meet_id')
          .eq('unit_name', unitNumber)
          .eq('status', 'HELD');

      if (meetingsData.isEmpty) {
        debugPrint("Result: No HELD meetings found. Attendance is 0%.");
        return 0.0; 
      }

      int totalMeetings = meetingsData.length;

      // 2. Get attendance records for this member
      final attendanceData = await supabase
          .from('attendance')
          .select('status')
          .eq('aadhar_number', aadharNumber);

      // 3. Count 'present' status
      int presentCount = attendanceData.where((record) {
        final status = record['status']?.toString().trim().toLowerCase() ?? '';
        return status == 'present';
      }).length;

      debugPrint("Result: Present $presentCount out of $totalMeetings meetings.");
      return (presentCount / totalMeetings) * 100;
    } catch (e) {
      debugPrint("Database Error fetching attendance: $e");
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String panchayat = userData['panchayat']?.toString() ?? '';
    final String ward = userData['ward']?.toString() ?? '';
    final String unitNumber = userData['unit_number']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Members", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('Registered_Members')
            .select()
            .eq('panchayat', panchayat)
            .eq('ward', ward)
            .eq('unit_number', unitNumber)
            .order('full_name', ascending: true)
            .asStream() 
            .map((data) => List<Map<String, dynamic>>.from(data)), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return const Center(child: Text("No members found in this unit."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.person, color: Colors.indigo),
                  ),
                  title: Text(member['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Aadhar: ${member['aadhar_number']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMemberDetails(context, member, unitNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member, String unitNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Text(member['full_name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            const Divider(),
            
            // ==========================================
            // THE ATTENDANCE WIDGET
            // ==========================================
            FutureBuilder<double>(
              future: _calculateAttendance(member['aadhar_number'].toString(), unitNumber),
              builder: (context, snapshot) {
                // 1. Show Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo)),
                        SizedBox(width: 15),
                        Text("Calculating Attendance...", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))
                      ],
                    ),
                  );
                }

                // 2. Show Error State (if any)
                if (snapshot.hasError) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade50,
                    child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  );
                }

                // 3. Show Final Percentage
                final double percentage = snapshot.data ?? 0.0;
                final Color pctColor = percentage >= 75 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: pctColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: pctColor.withOpacity(0.5), width: 2), // Made border thicker so it's obvious
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: pctColor),
                          const SizedBox(width: 8),
                          const Text("Overall Attendance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(
                        "${percentage.toStringAsFixed(1)}%", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: pctColor) // Made text bigger
                      ),
                    ],
                  ),
                );
              },
            ),
            // ==========================================

            _infoRow(Icons.phone, "PHONE", member['phone_number']),
            _infoRow(Icons.cake, "DOB", member['dob']),
            _infoRow(Icons.bloodtype, "Blood", member['blood_group']),
            _infoRow(Icons.home, "Address", member['address']),
            _infoRow(Icons.contact_emergency, "Emergency", member['emergency_contact']),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: member['phone_number'].toString());
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
              icon: const Icon(Icons.call),
              label: const Text("Call Member"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value?.toString() ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}