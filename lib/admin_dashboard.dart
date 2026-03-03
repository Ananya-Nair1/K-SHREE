import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Admin Panel - K-SHREE"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(context, "Manage Complaints", Icons.feedback, Colors.orange, const AdminComplaintsPage()),
            _buildAdminCard(context, "Pending Requests", Icons.person_add, Colors.blue, const PlaceholderPage(title: "Member Requests")),
            _buildAdminCard(context, "Loan Approvals", Icons.account_balance, Colors.green, const PlaceholderPage(title: "Loans")),
            _buildAdminCard(context, "System Settings", Icons.settings, Colors.grey, const PlaceholderPage(title: "Settings")),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}