import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ADSComplaintsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ADSComplaintsPage({super.key, required this.userData});

  @override
  State<ADSComplaintsPage> createState() => _ADSComplaintsPageState();
}

class _ADSComplaintsPageState extends State<ADSComplaintsPage> {
  final Color primaryColor = const Color(0xFF2B6CB0); // ADS Blue Theme
  
  // Method to update complaint status in Supabase
  Future<void> _updateComplaintStatus(String complaintId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('complaints')
          .update({'status': newStatus})
          .eq('complaint_id', complaintId);

      if (mounted) {
        String message = newStatus.contains('CDS') 
            ? "Complaint Forwarded to CDS" 
            : "Complaint Acknowledged and Resolved";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: newStatus.contains('CDS') ? primaryColor : Colors.green,
          ),
        );
        setState(() {}); // Trigger rebuild to refresh the list
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
    // Extract full location hierarchy for Strict Ward-level filtering
    final String adsDistrict = widget.userData['district']?.toString() ?? '';
    final String adsPanchayat = widget.userData['panchayat']?.toString() ?? '';
    final String adsWardStr = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '';
    
    // Convert ward to integer based on the database schema (int8)
    final int adsWard = int.tryParse(adsWardStr) ?? 0; 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Ward Grievances", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: primaryColor,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: Supabase.instance.client
              .from('complaints')
              .select('''
                *,
                Registered_Members!inner (
                  full_name,
                  aadhar_number,
                  panchayat,
                  ward,
                  unit_number,
                  district
                )
              ''')
              .eq('status', 'Pending at ADS') // Fetch complaints forwarded by Secretary
              .eq('ward', adsWard)            // Strict Ward Filter
              .ilike('panchayat', adsPanchayat) // Strict Panchayat Filter
              .ilike('Registered_Members.district', adsDistrict) // Strict District Filter via inner join
              // Notice: NO unit filter here! This guarantees ALL units in this ward are fetched.
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
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
                    child: Text("No pending grievances for your ward!", 
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
                
                final String complaintId = complaint['complaint_id']?.toString() ?? '';
                final String subject = complaint['subject'] ?? 'No Subject';
                final String description = complaint['description'] ?? 'No Description';
                final String unitNumber = complaint['unit_number']?.toString() ?? 'N/A';
                
                // Member Details from Join
                final String memberName = memberMap?['full_name'] ?? 'Unknown Member';
                final String aadhar = memberMap?['aadhar_number'] ?? 'N/A';

                final String dateStr = complaint['created_at'] != null 
                    ? complaint['created_at'].toString().split('T')[0] 
                    : 'N/A';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), 
                    side: BorderSide(color: primaryColor.withOpacity(0.2))
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.report_problem, color: primaryColor),
                    ),
                    title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("From: $memberName • Unit $unitNumber • $dateStr", style: const TextStyle(fontSize: 12)),
                    childrenPadding: const EdgeInsets.all(16.0),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow("Member Aadhar", aadhar),
                            _buildDetailRow("Location", "Ward $adsWardStr, Unit $unitNumber"),
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
                              onPressed: () => _updateComplaintStatus(complaintId, 'Resolved by ADS'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.forward, size: 18),
                              label: const Text("Fwd to CDS"),
                              onPressed: () => _updateComplaintStatus(complaintId, 'Pending at CDS'),
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