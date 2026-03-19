import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Fixes the DateFormat error

class ADSSchemeRequestsPage extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> userData;

  const ADSSchemeRequestsPage({super.key, required this.scheme, required this.userData});

  @override
  State<ADSSchemeRequestsPage> createState() => _ADSSchemeRequestsPageState();
}

class _ADSSchemeRequestsPageState extends State<ADSSchemeRequestsPage> {
  final supabase = Supabase.instance.client;
  final Color adsBlue = const Color(0xFF2B6CB0);

  Future<void> _updateStatus(String appId, String newStatus) async {
    try {
      await supabase.from('scheme_applications').update({'status': newStatus}).eq('id', appId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Application $newStatus"),
          backgroundColor: newStatus.contains('Rejected') ? Colors.red : adsBlue,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current user's ID to filter out their own requests from the review list
    final String myAadhar = widget.userData['aadhar_number'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text("Requests: ${widget.scheme['title']}"),
        backgroundColor: adsBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // FIX: Changed primary_key (error) to primaryKey (correct)
        stream: supabase
            .from('scheme_applications')
            .stream(primaryKey: ['id']) 
            .eq('scheme_id', widget.scheme['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No applications found for this scheme."));
          }

          // --- FIX: LOCAL FILTERING TO HIDE OWN REQUEST ---
          final filteredApps = snapshot.data!.where((app) {
            return app['member_id'].toString() != myAadhar;
          }).toList();

          if (filteredApps.isEmpty) {
            return const Center(child: Text("No applications from other members to review."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              final String status = app['status'] ?? 'Pending';
              final bool isPending = status == 'Pending at ADS';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(app['member_name'] ?? 'Unknown', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("ID: ${app['member_id']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (app['remarks'] != null) ...[
                        const SizedBox(height: 10),
                        Text("Remarks: ${app['remarks']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                      if (isPending) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(app['id'], 'Rejected by ADS'),
                                style: OutlinedButton.styleFrom(foregroundColor: const Color.fromARGB(255, 247, 38, 38)),
                                child: const Text("Reject"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(app['id'], 'Pending at CDS'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                                child: const Text("Fwd to CDS"),
                              ),
                            ),
                          ],
                        )
                      ]
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status.contains('Approved')) color = Colors.green;
    if (status.contains('Rejected')) color = Colors.red;
    if (status.contains('CDS')) color = adsBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}