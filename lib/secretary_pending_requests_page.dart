import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingRequestsPage extends StatefulWidget {
  // Pass the full secretary data map here to use for filtering
  final Map<String, dynamic> secretaryData;

  const PendingRequestsPage({super.key, required this.secretaryData});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  final supabase = Supabase.instance.client;

  // Helper to get secretary details from the map
  String get secDistrict => widget.secretaryData['district']?.toString() ?? '';
  String get secPanchayat => widget.secretaryData['panchayat']?.toString() ?? '';
  int get secWard => int.tryParse(widget.secretaryData['ward'].toString()) ?? 0;
  int get secUnit => int.tryParse(widget.secretaryData['unit_number'].toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unit Member Requests"),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder(
        // UPDATED QUERY: Added multiple .eq() filters to match secretary's location
        future: supabase
            .from('pending_requests')
            .select()
            .eq('status', 'pending') // Matches 'pending' status
            .eq('district', secDistrict)
            .eq('panchayat', secPanchayat)
            .eq('ward', secWard)
            .eq('unit_number', secUnit),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data as List<dynamic>? ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No pending requests found for\nWard: $secWard, Unit: $secUnit",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final item = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(item['full_name'] ?? "Unknown", 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Aadhar: ${item['aadhar_number']}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Applicant Photo", 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          const Divider(),
                          if (item['photo_url'] != null)
                            GestureDetector(
                              onTap: () => _showFullScreenImage(item['photo_url']),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Text("No photo provided", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          const Text("Application Details", 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          const Divider(),
                          _infoRow(Icons.cake, "DOB", item['dob']),
                          _infoRow(Icons.phone, "Phone", item['phone_number']),
                          _infoRow(Icons.home, "Address", item['address']),
                          _infoRow(Icons.map, "Panchayat", item['panchayat']),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () => _handleApproval(item),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text("Accept", style: TextStyle(color: Colors.white)),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                onPressed: () => _handleRejection(item['aadhar_number'].toString()),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text("Reject", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          )
                        ],
                      ),
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

  // Rest of your helper methods (_handleApproval, _handleRejection, etc.) stay the same...
  
  Future<void> _handleApproval(Map<String, dynamic> item) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upsert to Registered_Members using Aadhar as key
      await supabase.from('Registered_Members').upsert({
        'aadhar_number': item['aadhar_number']?.toString(),
        'password': item['password'],
        'full_name': item['full_name'],
        'photo_url': item['photo_url'],
        'phone_number': item['phone_number']?.toString(),
        'ward': int.tryParse(item['ward'].toString()) ?? 0,
        'unit_number': int.tryParse(item['unit_number'].toString()) ?? 0,
        'district': item['district'],
        'panchayat': item['panchayat'],
        'signature_url': item['signature_url'],
        'dob': item['dob'],
        'designation': 'Member',
      }, onConflict: 'aadhar_number');

      // Update status to approved
      await supabase
          .from('pending_requests')
          .update({'status': 'NHG Secretary Approved'})
          .eq('aadhar_number', item['aadhar_number']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member approved!")));
        setState(() {}); 
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _handleRejection(String aadhar) async {
    try {
      await supabase
          .from('pending_requests')
          .update({'status': 'Rejected'})
          .eq('aadhar_number', aadhar);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Rejected")));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }
}