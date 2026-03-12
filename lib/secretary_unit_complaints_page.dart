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
          .eq('complaint_id', complaintId); 

      if (mounted) {
        String message = newStatus == 'Pending at ADS' 
            ? "Complaint Forwarded to ADS" 
            : "Complaint Acknowledged";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: newStatus == 'Pending at ADS' ? Colors.blue : Colors.green,
          ),
        );
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
    final String secUnit = widget.userData['unit_number']?.toString() ?? '';
    final String secWard = widget.userData['ward']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Complaints", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // JOIN LOGIC: Fetching complaints and joining Registered_Members via member_id
        stream: Supabase.instance.client
            .from('complaints')
            .select('''
              *,
              Registered_Members (
                full_name,
                aadhar_number,
                ward,
                unit_number
              )
            ''')
            .eq('status', 'Pending at NHG')
            .eq('unit_number', secUnit)
            .eq('ward', secWard)
            .order('created_at', ascending: false)
            .asStream()
            .map((data) => List<Map<String, dynamic>>.from(data)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return const Center(
              child: Text("No pending complaints for your unit!", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              
              // Extracting Joined Data
              final memberData = complaint['Registered_Members'] as Map<String, dynamic>?;
              
              final String complaintId = complaint['complaint_id']?.toString() ?? '';
              final String subject = complaint['subject'] ?? 'No Subject';
              final String description = complaint['description'] ?? 'No Description';
              final String complaintWard = complaint['ward']?.toString() ?? 'N/A';
              
              // Member Details from Join
              final String memberName = memberData?['full_name'] ?? 'Unknown Member';
              final String aadhar = memberData?['aadhar_number'] ?? 'N/A';
              final String memberUnit = memberData?['unit_number']?.toString() ?? 'N/A';

              final String dateStr = complaint['created_at'] != null 
                  ? complaint['created_at'].toString().split('T')[0] 
                  : 'N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          _buildDetailRow("Unit Number", memberUnit),
                          _buildDetailRow("Complaint Ward", complaintWard),
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
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text("Acknowledge"),
                            onPressed: () => _updateComplaintStatus(complaintId, 'Acknowledged by NHG'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.forward, size: 18),
                            label: const Text("Forward"),
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