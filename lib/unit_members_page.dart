
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 

class UnitMembersPage extends StatelessWidget {
  final Map<String, dynamic> secretaryData;

  const UnitMembersPage({Key? key, required this.secretaryData}) : super(key: key);

  // Helper function to launch the phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    
    // Extract the strict matching criteria from the Secretary's profile
    final String secPanchayat = secretaryData['panchayat']?.toString() ?? '';
    final String secWard = (secretaryData['ward'] ?? secretaryData['ward_number'])?.toString() ?? '';
    final String secUnit = secretaryData['unit_number']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text("Unit Members ($secUnit)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // The Query: Must match Panchayat AND Ward AND Unit Number
        future: supabase
            .from('Registered_Members')
            .select('full_name, aadhar_number, phone_number, photo_url, designation')
            .eq('panchayat', secPanchayat)
            .eq('ward', secWard) 
            .eq('unit_number', secUnit)
            .order('full_name', ascending: true), // Alphabetical order
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching members: ${snapshot.error}"));
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No members found in this unit.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final String name = member['full_name'] ?? 'Unknown Name';
              final String aadhar = member['aadhar_number'] ?? 'N/A';
              final String phone = member['phone_number'] ?? 'No Phone';
              final String photoUrl = member['photo_url'] ?? '';
              final String role = member['designation'] ?? 'Member';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.teal[50],
                      backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                      child: (photoUrl.isEmpty) ? const Icon(Icons.person, color: Colors.teal) : null,
                    ),
                    title: Text(
                      name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 16)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Aadhar: $aadhar", style: const TextStyle(fontSize: 12)),
                        if (role == 'NHG_SECRETARY') // Highlight if they are the secretary
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(role, style: TextStyle(color: Colors.teal[700], fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: phone != 'No Phone' ? () => _makePhoneCall(phone) : null,
                      tooltip: 'Call Member',
                    ),
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
