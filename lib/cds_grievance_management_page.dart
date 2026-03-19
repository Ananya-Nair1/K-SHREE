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

  Future<void> _updateGrievanceStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('complaints') 
          .update({'status': newStatus})
          .eq('complaint_id', id); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Grievance marked as $newStatus"), backgroundColor: Colors.green)
        );
        setState(() {}); 
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red)
        );
      }
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
            .from('complaints') 
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
              
              // NEW LOGIC: Separating the states completely
              final bool isFullyResolved = status == 'RESOLVED';
              final bool isAcknowledged = status == 'ACKNOWLEDGED';

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
                              color: isFullyResolved 
                                  ? Colors.green.withOpacity(0.1) 
                                  : (isAcknowledged ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isFullyResolved 
                                    ? Colors.green 
                                    : (isAcknowledged ? Colors.blue : Colors.orange), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 10
                              ),
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
                          Expanded(
                            child: Text(
                              "Ward ${item['ward'] ?? 'N/A'} - Member: ${item['member_id'] ?? item['member_name'] ?? 'Unknown'}", 
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFullyResolved) 
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),

                      // NEW LOGIC: Show buttons only if NOT fully resolved
                      if (!isFullyResolved) ...[
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            // Only show ACKNOWLEDGE if it is still PENDING
                            if (!isAcknowledged) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateGrievanceStatus(item['complaint_id'].toString(), 'ACKNOWLEDGED'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text("ACKNOWLEDGE", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            // ALWAYS show RESOLVE unless it is already fully resolved
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                onPressed: () => _updateGrievanceStatus(item['complaint_id'].toString(), 'RESOLVED'),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("RESOLVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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