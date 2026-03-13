import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secretary_edit_profile_page.dart';

class SecretaryProfilePage extends StatefulWidget {
  final String secretaryId; // Aadhar Number

  const SecretaryProfilePage({Key? key, required this.secretaryId}) : super(key: key);

  @override
  State<SecretaryProfilePage> createState() => _SecretaryProfilePageState();
}

class _SecretaryProfilePageState extends State<SecretaryProfilePage> {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      final response = await supabase
          .from('Registered_Members')
          .select()
          .eq('aadhar_number', widget.secretaryId)
          .maybeSingle();

      return response ?? {'full_name': 'Profile Not Found'};
    } catch (e) {
      return {'full_name': 'Error Loading Profile'};
    }
  }

  void _refreshProfile() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Secretary Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          final profile = snapshot.data!;
          final String photoUrl = profile['photo_url'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 100, width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
                    ),
                    Positioned(
                      top: 40,
                      child: CircleAvatar(
                        radius: 50, backgroundColor: Colors.white,
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.teal) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(profile['full_name'] ?? 'Secretary', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("NHG Secretary", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Details"),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SecretaryEditProfilePage(currentProfile: profile)),
                      );
                      if (result == true) _refreshProfile();
                    },
                  ),
                ),

                _buildInfoSection("Personal Information", [
                  _buildDetailRow(Icons.badge, "Aadhar", profile['aadhar_number']),
                  _buildDetailRow(Icons.phone, "Phone", profile['phone_number']),
                  _buildDetailRow(Icons.cake, "DOB", profile['dob']),
                ]),

                _buildInfoSection("Kudumbashree Office", [
                  _buildDetailRow(Icons.home_work, "Unit", profile['unit_number']?.toString()),
                  _buildDetailRow(Icons.map, "Ward", profile['ward']?.toString()),
                  _buildDetailRow(Icons.location_city, "Panchayat", profile['panchayat']),
                ]),
                
                _buildInfoSection("Bank & KYC", [
                  _buildDetailRow(Icons.account_balance, "Bank", profile['bank_name']),
                  _buildDetailRow(Icons.numbers, "Account", profile['account_number']),
                  _buildDetailRow(Icons.credit_card, "PAN", profile['pan_card']),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value ?? 'Not Provided', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }
}