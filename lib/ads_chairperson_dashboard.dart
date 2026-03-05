import 'package:flutter/material.dart';

class ADSChairpersonDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  ADSChairpersonDashboard({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F4), // Light greenish background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4285F4), // Blue app bar
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replace with your actual K-SHREE logo asset
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage('https://via.placeholder.com/50'), // Placeholder for logo
            ),
            const SizedBox(width: 8),
            const Text('K-SHREE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
              )
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),
            
            const Text("ADS Functions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
            const SizedBox(height: 12),
            _buildADSGrid(),
            
            const SizedBox(height: 24),
            
            const Text("Member Functions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
            const SizedBox(height: 12),
            _buildMemberGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(userData['photo_url'] ?? 'https://via.placeholder.com/150'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['full_name'] ?? 'Name Not Found', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userData['aadhar_number'] ?? 'ID-Not-Found', // Adjust if you have a specific ID field
                      style: const TextStyle(color: Color(0xFF718096), fontSize: 13)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['designation'] ?? 'Role Not Found', 
                      style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.w600, fontSize: 13)
                    ),
                    const SizedBox(height: 2),
                    Text("Ward: ${userData['ward'] ?? 'N/A'}", style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
                    Text("Panchayat: ${userData['panchayat'] ?? 'N/A'}", style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDF2F7), thickness: 1),
          const SizedBox(height: 16),
          _buildAttendanceBar(),
        ],
      ),
    );
  }

  Widget _buildAttendanceBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("2026 Attendance", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D3748))),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.88, // Change dynamically based on DB
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("22/25 meetings attended", style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
            Text("88%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
          ],
        )
      ],
    );
  }

  Widget _buildADSGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6, 
      children: [
        _buildButtonCard("View Complaints", Icons.error_outline, const Color(0xFFFFEBEB), const Color(0xFFC53030), const Color(0xFFFEB2B2)),
        _buildButtonCard("Loan Requests", Icons.attach_money, const Color(0xFFFEFCBF), const Color(0xFF975A16), const Color(0xFFF6E05E)),
        _buildButtonCard("Meetings Conducted", Icons.assignment_outlined, const Color(0xFFE9D8FD), const Color(0xFF553C9A), const Color(0xFFD6BCFA)),
        _buildButtonCard("Scheme Progress", Icons.trending_up, const Color(0xFFC6F6D5), const Color(0xFF22543D), const Color(0xFF9AE6B4)),
      ],
    );
  }

  Widget _buildMemberGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildButtonCard("Meeting Report", Icons.description_outlined, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Loans", Icons.attach_money, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Govt Schemes", Icons.account_balance_outlined, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Complaints", Icons.chat_bubble_outline, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Scheduled Meetings", Icons.calendar_today_outlined, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Trainings", Icons.school_outlined, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Savings", Icons.savings_outlined, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
        _buildButtonCard("Election Procedure", Icons.how_to_vote_outlined, const Color(0xFFD6E4FF), const Color(0xFF2B6CB0), const Color(0xFFA3BFFA)),
      ],
    );
  }

  Widget _buildButtonCard(String title, IconData icon, Color bgColor, Color iconTextColor, Color borderColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // Add navigation here
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconTextColor, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: iconTextColor, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}