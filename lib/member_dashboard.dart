import 'package:flutter/material.dart';
import 'member.dart';
import 'login_page.dart';
import 'dashboard_pages.dart'; // Ensure this file is created

class MemberDashboard extends StatelessWidget {
  final Member member;
  const MemberDashboard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F6),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text("K-SHREE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), 
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (r) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildActionGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("NHG: ${member.nhgUnit}", style: const TextStyle(color: Colors.grey)),
                  Text("Ward: ${member.ward} | ${member.panchayat}", style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          const Align(alignment: Alignment.centerLeft, child: Text("2026 Attendance", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: member.attendance / 20, minHeight: 12, color: Colors.black, backgroundColor: Colors.grey[200]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${member.attendance}/20 meetings attended"),
              Text("${((member.attendance / 20) * 100).toInt()}%"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.description_outlined, 'title': 'Meeting Report'},
      {'icon': Icons.attach_money, 'title': 'Loans'},
      {'icon': Icons.business_center_outlined, 'title': 'Govt Schemes'},
      {'icon': Icons.chat_bubble_outline, 'title': 'Complaints'},
      {'icon': Icons.calendar_today_outlined, 'title': 'Meetings'},
      {'icon': Icons.school_outlined, 'title': 'Trainings'},
      {'icon': Icons.savings_outlined, 'title': 'Savings'},
      {'icon': Icons.how_to_reg_outlined, 'title': 'Election'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.4),
      itemCount: items.length,
      itemBuilder: (context, i) => InkWell(
        onTap: () {
          Widget nextPage;
          switch (items[i]['title']) {
            case 'Meeting Report': nextPage = const MeetingReportPage(); break;
            case 'Loans': nextPage = const LoansPage(); break;
            case 'Govt Schemes': nextPage = const SchemesPage(); break;
            case 'Complaints': nextPage = ComplaintsPage(member: member); break; // Pass member
            case 'Meetings': nextPage = const PlaceholderPage(title: "Scheduled Meetings"); break;
            case 'Trainings': nextPage = const PlaceholderPage(title: "Trainings"); break;
            case 'Savings': nextPage = const PlaceholderPage(title: "Savings"); break;
            case 'Election': nextPage = const PlaceholderPage(title: "Election Procedure"); break;
            default: nextPage = const PlaceholderPage(title: "Feature");
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
        },
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFDCE6F8), borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[i]['icon'], color: const Color(0xFF2E5BA7)),
              const SizedBox(height: 8),
              Text(items[i]['title'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF2E5BA7))),
            ],
          ),
        ),
      ),
    );
  }
}