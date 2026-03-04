import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingRequestsPage extends StatefulWidget {
  final dynamic unitNumber;
  const PendingRequestsPage({super.key, required this.unitNumber});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  final supabase = Supabase.instance.client;

  Future<void> _handleApproval(Map<String, dynamic> item) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. UPDATED: Added onConflict to safely tell Supabase how to handle duplicates
      await supabase.from('members').upsert({
        'user_id': item['aadhar_number']?.toString(), // Aadhar becomes their User ID
        'password': item['password'],                 // Keeps the password they created
        'full_name': item['full_name'],
        'photo_url': item['photo_url'],               // Includes photo for Member Dashboard
      }, onConflict: 'user_id'); // <--- THE MAGIC FIX

      // 2. UPDATED: Added onConflict here too just to be 100% safe
      final Map<String, dynamic> insertData = {
        'full_name': item['full_name'],
        'aadhar_number': item['aadhar_number']?.toString(),
        'phone_number': item['phone_number']?.toString(),
        'ward': int.tryParse(item['ward'].toString()) ?? 0,
        'unit_number': int.tryParse(item['unit_number'].toString()) ?? 0,
        'district': item['district'],
        'panchayat': item['panchayat'],
        'photo_url': item['photo_url'],
        'signature_url': item['signature_url'],
        'dob': item['dob'],
        'password': item['password'], 
        'designation': 'Member',
      };
      await supabase.from('Registered_Members').upsert(
        insertData, 
        onConflict: 'aadhar_number' // <--- THE MAGIC FIX
      );

      // 3. Update status to match exactly what the tracker expects
      await supabase
          .from('pending_requests')
          .update({'status': 'NHG Secretary Approved'}) 
          .eq('aadhar_number', item['aadhar_number']);

      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member approved and registered!")),
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Approval Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _handleRejection(String aadhar) async {
    try {
      await supabase
          .from('pending_requests')
          .update({'status': 'Rejected'}) // Capital 'R' for the tracker
          .eq('aadhar_number', aadhar);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application Rejected")),
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Member Requests"), backgroundColor: Colors.blue),
      body: FutureBuilder(
        // Fetch only requests that are 'Submitted' and belong to this unit
        future: supabase
            .from('pending_requests')
            .select()
            .eq('unit_number', int.tryParse(widget.unitNumber.toString()) ?? 0)
            .eq('status', 'Submitted'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final requests = snapshot.data as List<dynamic>? ?? [];
          if (requests.isEmpty) return Center(child: Text("No pending requests for Unit ${widget.unitNumber}"));

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
                  title: Text(item['full_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Aadhar: ${item['aadhar_number']}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Applicant Photo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                          const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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