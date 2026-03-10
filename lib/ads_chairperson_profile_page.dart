import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart'; // Ensure this matches your Chairperson edit logic

class ADSChairpersonProfilePage extends StatefulWidget {
  final String adsId; // This is the Chairperson's Aadhar number

  const ADSChairpersonProfilePage({Key? key, required this.adsId}) : super(key: key);

  @override
  State<ADSChairpersonProfilePage> createState() => _ADSChairpersonProfilePageState();
}

class _ADSChairpersonProfilePageState extends State<ADSChairpersonProfilePage> {
  final supabase = Supabase.instance.client;
  final Color adsPrimaryColor = const Color(0xFF4285F4); // ADS Professional Blue

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      final response = await supabase
          .from('Registered_Members')
          .select()
          .eq('aadhar_number', widget.adsId)
          .maybeSingle(); 

      if (response == null) {
        return {
          'full_name': 'Profile Incomplete',
          'designation': 'ADS Chairperson',
          'aadhar_number': widget.adsId,
          'phone_number': 'N/A',
          'dob': 'N/A',
          'unit_number': 'ADS Office',
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
        'aadhar_number': widget.adsId,
      };
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
        title: const Text('ADS Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: adsPrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: adsPrimaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
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
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: adsPrimaryColor,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE3F2FD),
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty ? Icon(Icons.admin_panel_settings, size: 50, color: adsPrimaryColor) : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60), 
                
                Text(
                  profile['full_name'] ?? 'Authorized Personnel',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 5),
                Text(
                  profile['designation'] ?? 'ADS Chairperson',
                  style: TextStyle(fontSize: 16, color: adsPrimaryColor, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: adsPrimaryColor,
                        side: BorderSide(color: adsPrimaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text("Update Official Records", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfilePage(currentProfile: profile)),
                        );
                        if (result == true) {
                          _refreshProfile();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Administrative Scope
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Administrative Scope",
                    icon: Icons.account_tree_outlined,
                    children: [
                      _buildDetailRow(Icons.location_city, "Panchayat/Municipality", profile['panchayat']),
                      const Divider(),
                      _buildDetailRow(Icons.map, "ADS Ward Reference", profile['ward']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.pin_drop, "District", profile['district']),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Identification
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Official Identification",
                    icon: Icons.badge_outlined,
                    children: [
                      _buildDetailRow(Icons.fingerprint, "Aadhar (Official ID)", profile['aadhar_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.contact_phone, "Contact Number", profile['phone_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.event, "Date of Birth", profile['dob']?.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ADS Official Bank details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "ADS Bank Details",
                    icon: Icons.account_balance,
                    children: [
                      _buildDetailRow(Icons.account_balance_wallet, "Bank Name", profile['bank_name']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.numbers, "Account Number", profile['account_number']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.account_tree, "IFSC Code", profile['ifsc_code']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.credit_card, "PAN Card", profile['pan_card']?.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Additional Welfare Data
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(
                    title: "Health & Welfare",
                    icon: Icons.health_and_safety_outlined,
                    children: [
                      _buildDetailRow(Icons.category, "Card Category", profile['card_category']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.bloodtype, "Blood Group", profile['blood_group']?.toString()),
                      const Divider(),
                      _buildDetailRow(Icons.emergency, "Emergency Support", profile['emergency_contact']?.toString()),
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
                Icon(icon, color: adsPrimaryColor),
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