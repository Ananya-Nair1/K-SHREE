import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UnitMembersPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UnitMembersPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Extract variables
    final String panchayat = userData['panchayat']?.toString() ?? '';
    final String ward = userData['ward']?.toString() ?? '';
    final String unitNumber = userData['unit_number']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Members", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // FAIL-SAFE METHOD: Apply filters to select(), then convert to stream
        stream: Supabase.instance.client
            .from('Registered_Members')
            .select()
            .eq('panchayat', panchayat)
            .eq('ward', ward)
            .eq('unit_number', unitNumber)
            .order('full_name', ascending: true)
            .asStream() // This converts the Postgrest query into a Stream
            .map((data) => List<Map<String, dynamic>>.from(data)), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return const Center(child: Text("No members found in this unit."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.person, color: Colors.indigo),
                  ),
                  title: Text(member['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Aadhar: ${member['aadhar_number']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMemberDetails(context, member),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Text(member['full_name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            const Divider(),
            _infoRow(Icons.phone, "Phone", member['phone_number']),
            _infoRow(Icons.cake, "DOB", member['dob']),
            _infoRow(Icons.bloodtype, "Blood", member['blood_group']),
            _infoRow(Icons.home, "Address", member['address']),
            _infoRow(Icons.contact_emergency, "Emergency", member['emergency_contact']),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: member['phone_number'].toString());
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
              icon: const Icon(Icons.call),
              label: const Text("Call Member"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value?.toString() ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}