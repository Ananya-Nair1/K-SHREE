import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CDSGrievanceManagementPage extends StatefulWidget {
  final String panchayat;
  const CDSGrievanceManagementPage({super.key, required this.panchayat});

  @override
  State<CDSGrievanceManagementPage> createState() => _CDSGrievanceManagementPageState();
}

class _CDSGrievanceManagementPageState extends State<CDSGrievanceManagementPage> {
  final supabase = Supabase.instance.client;

  // Function to finalize the grievance
  Future<void> _updateGrievanceStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('complaints') // UPDATED: Matches your schema table name
          .update({'status': newStatus, 'resolved_by': 'CDS Chairperson'})
          .eq('complaint_id', id); // UPDATED: Matches your schema primary key
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Grievance marked as $newStatus"), backgroundColor: Colors.green)
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Grievance Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('complaints') // UPDATED: Matches your schema table name
            .select()
            .eq('panchayat', widget.panchayat)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final grievances = snapshot.data ?? [];
          if (grievances.isEmpty) {
            return const Center(child: Text("No complaints reported in this Panchayat."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              final item = grievances[index];
              final String status = item['status'] ?? 'PENDING';
              final bool isResolved = status == 'RESOLVED' || status == 'ACKNOWLEDGED';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isResolved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: isResolved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          Text(item['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(item['subject'] ?? "General Grievance", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(item['description'] ?? "No description provided.", style: const TextStyle(color: Colors.black87)),
                      const Divider(height: 25),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          // UPDATED: safely checks for member_id or member_name depending on what you saved
                          Text("Ward ${item['ward'] ?? 'N/A'} - Member: ${item['member_id'] ?? item['member_name'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          if (!isResolved) ...[
                            TextButton(
                              // UPDATED: Passes complaint_id instead of id
                              onPressed: () => _updateGrievanceStatus(item['complaint_id'].toString(), 'ACKNOWLEDGED'),
                              child: const Text("ACKNOWLEDGE"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              // UPDATED: Passes complaint_id instead of id
                              onPressed: () => _updateGrievanceStatus(item['complaint_id'].toString(), 'RESOLVED'),
                              child: const Text("RESOLVE", style: TextStyle(color: Colors.white)),
                            ),
                          ] else 
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
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
}