import 'package:flutter/material.dart';

class MemberDetailsPage extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberDetailsPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(member['full_name'] ?? "Member Profile", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PROFILE HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: member['photo_url'] != null 
                          ? NetworkImage(member['photo_url']) 
                          : null,
                      child: member['photo_url'] == null 
                          ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    member['full_name']?.toUpperCase() ?? "UNKNOWN NAME",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Aadhar: ${member['aadhar_number']}",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionTitle("General Information"),
                  _buildInfoCard([
                    _buildInfoRow(Icons.phone, "Phone", member['phone_number']),
                    _buildInfoRow(Icons.cake, "DOB", member['dob']),
                    _buildInfoRow(Icons.bloodtype, "Blood Group", member['blood_group'] ?? "Not Provided"),
                    _buildInfoRow(Icons.badge, "Designation", member['designation']),
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle("Locality Details"),
                  _buildInfoCard([
                    _buildInfoRow(Icons.map, "Panchayat", member['panchayat']?.toUpperCase()),
                    _buildInfoRow(Icons.meeting_room, "Ward Number", member['ward'].toString()),
                    _buildInfoRow(Icons.grid_view, "Unit Number", member['unit_number'].toString()),
                    _buildInfoRow(Icons.home, "Address", member['address'] ?? "No address provided"),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionTitle("Financial Information"),
                  _buildInfoCard([
                    _buildInfoRow(Icons.account_balance, "Bank", member['bank_name'] ?? "N/A"),
                    _buildInfoRow(Icons.numbers, "Account No", member['account_number'] ?? "N/A"),
                    _buildInfoRow(Icons.code, "IFSC Code", member['ifsc_code'] ?? "N/A"),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}