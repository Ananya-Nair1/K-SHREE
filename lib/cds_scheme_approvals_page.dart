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

  Future<void> _updateApplicationStatus(String id, String status) async {
    try {
      await supabase.from('scheme_applications').update({
        'status': status,
        'approved_at': DateTime.now().toIso8601String(),
        'remarks': 'Processed by CDS Chairperson'
      }).eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Application $status"), backgroundColor: Colors.teal),
        );
        setState(() {}); // Refresh the list
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
        title: const Text("Scheme Applications", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('scheme_applications')
            .select('*, schemes(title)') // Join with schemes table to get the name
            .eq('panchayat', widget.panchayat)
            .eq('status', 'PENDING'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final applications = snapshot.data ?? [];
          if (applications.isEmpty) {
            return const Center(child: Text("No pending scheme applications."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final schemeTitle = app['schemes'] != null ? app['schemes']['title'] : "Unknown Scheme";

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
                          Expanded(
                            child: Text(schemeTitle, 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ),
                          const Icon(Icons.assignment, color: Colors.grey, size: 20),
                        ],
                      ),
                      const Divider(height: 20),
                      Text("Applicant: ${app['member_name']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("Ward: ${app['ward']} | Aadhar: ${app['aadhar_number']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 10),
                      Text("Application Date: ${app['created_at'].toString().split('T')[0]}", style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateApplicationStatus(app['id'].toString(), 'REJECTED'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("REJECT"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateApplicationStatus(app['id'].toString(), 'APPROVED'),
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
        }, // Closed builder
      ), // Closed FutureBuilder
    );
  }
}