import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart'; // Ensure you have created this file

class MemberProfilePage extends StatefulWidget {
  final String memberId; // This is their Aadhar number

  const MemberProfilePage({Key? key, required this.memberId}) : super(key: key);

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      print("==== 🔍 DEBUG: Searching Supabase for Aadhar: ${widget.memberId} ====");
      final response = await supabase
          .from('Registered_Members')
          .select()
          .eq('aadhar_number', widget.memberId)
          .maybeSingle(); 

      if (response == null) {
        return {
          'full_name': 'Profile Incomplete',
          'designation': 'Member',
          'aadhar_number': widget.memberId,
          'phone_number': 'N/A',
          'dob': 'N/A',
          'unit_number': 'N/A',
          'ward': 'N/A',
          'panchayat': 'N/A',
          'district': 'N/A',
          'photo_url': '',
          'bank_name': 'N/A',
          'account_number': 'N/A',
          'ifsc_code': 'N/A',
          'pan_card': 'N/A',
          'ration_card_number': 'N/A',
          'card_category': 'N/A',
          'blood_group': 'N/A',
          'emergency_contact': 'N/A',
        };
      }
      
      return response;
    } catch (e) {
      return {
        'full_name': 'Error Loading Profile',
        'aadhar_number': widget.memberId,
      };
    }
  }

  // Helper method to refresh the page after editing
  void _refreshProfile() {
    setState(() {}); // Calling setState triggers FutureBuilder to re-fetch data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error loading profile: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final profile = snapshot.data!;
          final String photoUrl = profile['photo_url'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top Header Background & Photo
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE0F2F1),
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.teal) : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60), 
                
                Text(
                  profile['full_name'] ?? 'Unknown Member',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 5),
                Text(
                  profile['designation'] ?? 'Member',
                  style: const TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 25),

                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit Additional Details", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        // Navigate to Edit page and wait for a result
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfilePage(currentProfile: profile)),
                        );
                        // If result is true, it means they saved data, so we refresh the profile page
                        if (result == true) {
                          _refreshProfile();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Personal Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Personal Information",
                    icon: Icons.person_outline,
                    children: [
                      _buildDetailRow(Icons.badge, "Aadhar Number", profile['aadhar_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.phone, "Phone Number", profile['phone_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.cake, "Date of Birth", profile['dob']?.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Kudumbashree Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Kudumbashree Details",
                    icon: Icons.groups,
                    children: [
                      _buildDetailRow(Icons.home_work, "Unit Number", profile['unit_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.map, "Ward", profile['ward']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.location_city, "Panchayat", profile['panchayat']),
                      const Divider(),
                      _buildDetailRow(Icons.location_on, "District", profile['district']),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bank & KYC Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Bank & KYC Details",
                    icon: Icons.account_balance,
                    children: [
                      _buildDetailRow(Icons.account_balance_wallet, "Bank Name", profile['bank_name']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.numbers, "Account Number", profile['account_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.account_tree, "IFSC Code", profile['ifsc_code']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.credit_card, "PAN Card Number", profile['pan_card']?.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Health & Welfare Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Health & Welfare",
                    icon: Icons.health_and_safety,
                    children: [
                      _buildDetailRow(Icons.featured_play_list, "Ration Card Number", profile['ration_card_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.category, "Card Category", profile['card_category']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.bloodtype, "Blood Group", profile['blood_group']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.contact_emergency, "Emergency Contact", profile['emergency_contact']?.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    // Check if the value is empty, null, or 'N/A' to show 'Not Provided' in grey italic text
    bool isEmpty = value == null || value.isEmpty || value == 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  isEmpty ? 'Not Provided' : value, 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500, 
                    color: isEmpty ? Colors.grey : Colors.black87,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}