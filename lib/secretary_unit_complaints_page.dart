import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitComplaintsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UnitComplaintsPage({super.key, required this.userData});

  @override
  State<UnitComplaintsPage> createState() => _UnitComplaintsPageState();
}

class _UnitComplaintsPageState extends State<UnitComplaintsPage> {
  
  // Method to update complaint status in Supabase
  Future<void> _updateComplaintStatus(String complaintId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('complaints')
          .update({'status': newStatus})
          .eq('complaint_id', complaintId); // Make sure 'complaint_id' matches your DB column exactly

      if (mounted) {
        String message = newStatus.contains('ADS') 
            ? "Complaint Forwarded to ADS" 
            : "Complaint Acknowledged by NHG";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: newStatus.contains('ADS') ? Colors.blue : Colors.green,
          ),
        );
        setState(() {}); // Trigger rebuild to refresh the stream/future
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating status: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract full location hierarchy for strict filtering
    final String secPanchayat = widget.userData['panchayat']?.toString() ?? '';
    final String secWard = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '';
    final String secUnit = widget.userData['unit_number']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Grievances", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Colors.orange,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          // Switched to FutureBuilder for reliable Join queries. 
          // (Streams with joins can sometimes cause issues in Supabase Flutter)
          future: Supabase.instance.client
              .from('complaints')
              .select('''
                *,
                Registered_Members (
                  full_name,
                  aadhar_number,
                  panchayat,
                  ward,
                  unit_number
                )
              ''')
              .eq('status', 'Pending at NHG')
              .eq('panchayat', secPanchayat) // NEW: Strict Panchayat Filter
              .eq('ward', secWard)           // NEW: Strict Ward Filter
              .eq('unit_number', secUnit)    // Maintained Unit Filter
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
            }

            final complaints = snapshot.data ?? [];

            if (complaints.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: Text("No pending grievances for your unit!", 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                
                // Extracting Joined Data safely
                final memberData = complaint['Registered_Members'];
                final memberMap = memberData is Map<String, dynamic> ? memberData : null;
                
                final String complaintId = complaint['complaint_id']?.toString() ?? complaint['id']?.toString() ?? '';
                final String subject = complaint['subject'] ?? 'No Subject';
                final String description = complaint['description'] ?? 'No Description';
                
                // Member Details from Join
                final String memberName = memberMap?['full_name'] ?? 'Unknown Member';
                final String aadhar = memberMap?['aadhar_number'] ?? 'N/A';

                final String dateStr = complaint['created_at'] != null 
                    ? complaint['created_at'].toString().split('T')[0] 
                    : 'N/A';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade100)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.report_problem, color: Colors.orange),
                    ),
                    title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("From: $memberName • $dateStr", style: const TextStyle(fontSize: 12)),
                    childrenPadding: const EdgeInsets.all(16.0),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow("Member Aadhar", aadhar),
                            _buildDetailRow("Location", "Ward $secWard, Unit $secUnit"),
                            const SizedBox(height: 10),
                            const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 4),
                            Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
                          ],
                        ),
                      ),
                      const Divider(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text("Acknowledge"),
                              onPressed: () => _updateComplaintStatus(complaintId, 'Resolved'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.forward, size: 18),
                              label: const Text("Fwd to ADS"),
                              onPressed: () => _updateComplaintStatus(complaintId, 'Pending at ADS'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}