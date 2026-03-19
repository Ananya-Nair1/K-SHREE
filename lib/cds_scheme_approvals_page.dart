import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CDSSchemeApprovalsPage extends StatefulWidget {
  final String panchayat;
  const CDSSchemeApprovalsPage({super.key, required this.panchayat});

  @override
  State<CDSSchemeApprovalsPage> createState() => _CDSSchemeApprovalsPageState();
}

class _CDSSchemeApprovalsPageState extends State<CDSSchemeApprovalsPage> {
  final supabase = Supabase.instance.client;

  Future<void> _updateApplicationStatus(Map<String, dynamic> app, String status, {String? reason}) async {
    try {
      final updateData = {'status': status};
      if (reason != null && reason.isNotEmpty) updateData['remarks'] = reason;

      await supabase.from('scheme_applications').update(updateData).eq('id', app['id']);

      // Automatically send notification on rejection
      if (status == 'REJECTED' && reason != null) {
        await supabase.from('unit_notifications').insert({
          'title': 'Scheme Application Update',
          'message': 'Application for Scheme ID: ${app['scheme_id']} was not approved. Reason: $reason',
          'panchayat': app['panchayat'],
          'ward': app['ward'],
          'unit_number': app['unit_number'] ?? 'N/A',
          'target_audience': 'All Members',
          'is_urgent': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Application $status"), backgroundColor: Colors.teal));
        setState(() {}); 
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // Dialog box for Rejection
  Future<void> _showRejectDialog(Map<String, dynamic> app) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Application", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide a reason. The member will be notified."),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Reason for Rejection",
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); 
              _updateApplicationStatus(app, 'REJECTED', reason: reasonController.text);
            },
            child: const Text("Confirm Rejection", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Scheme Applications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('scheme_applications').select('*, government_schemes(title)').eq('status', 'Pending at CDS'), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final applications = snapshot.data ?? [];
          if (applications.isEmpty) return const Center(child: Text("No scheme applications pending at CDS level.", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final schemeTitle = app['government_schemes'] != null ? app['government_schemes']['title'] : "Scheme ID: ${app['scheme_id']}";

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(schemeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(5)), child: const Text("AWAITING CDS", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Divider(height: 20),
                      Text("Applicant: ${app['member_name'] ?? app['member_id'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text("Application Date: ${app['applied_date']?.toString().split('T')[0] ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showRejectDialog(app), // Trigger Dialog
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("REJECT"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateApplicationStatus(app, 'APPROVED'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const Text("APPROVE", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
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