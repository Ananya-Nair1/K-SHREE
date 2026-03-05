import 'package:flutter/material.dart';
import 'member.dart'; 
import 'member_meetings_page.dart';
// ADD THIS IMPORT: Make sure this points to your actual login page file
import 'login_page.dart'; 

class MemberDashboard extends StatelessWidget {
  final Member member; // Receives the logged-in member's data

  const MemberDashboard({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely extract data with fallbacks
    final String name = member.fullName ?? 'Member';
    final String userId = member.userId ?? 'N/A';
    final String role = 'Member'; 
    
    final String unit = '4'; 
    final String ward = 'Ward 2'; 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), 
      appBar: AppBar(
        title: const Text('Member Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, name, member.photoUrl),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFFE0F2F1),
                              backgroundImage: (member.photoUrl != null && member.photoUrl!.isNotEmpty) 
                                  ? NetworkImage(member.photoUrl!) 
                                  : null,
                              child: (member.photoUrl == null || member.photoUrl!.isEmpty) 
                                  ? const Icon(Icons.person, size: 35, color: Colors.teal) 
                                  : null,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  const SizedBox(height: 4),
                                  Text('ID: $userId', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoChip(Icons.home_work, "Unit", unit),
                            Container(width: 1, height: 30, color: Colors.grey[300]),
                            _buildInfoChip(Icons.map, "Ward", ward),
                            Container(width: 1, height: 30, color: Colors.grey[300]),
                            _buildInfoChip(Icons.star, "Role", role),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'My Passbook',
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passbook Coming Soon")));
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Apply for Loan',
                      icon: Icons.account_balance_wallet,
                      color: Colors.orange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loan Application Coming Soon")));
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("My Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3, 
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9,
                children: [
                  _buildModernGridItem(context, 'Meetings', Icons.groups, Colors.indigo, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MemberMeetingsPage(unitNumber: unit)),
                    );
                  }),
                  _buildModernGridItem(context, 'Savings', Icons.savings, Colors.teal),
                  _buildModernGridItem(context, 'My Loans', Icons.monetization_on, Colors.green),
                  _buildModernGridItem(context, 'Schemes', Icons.account_balance, Colors.blue),
                  _buildModernGridItem(context, 'Trainings', Icons.school, Colors.orange),
                  _buildModernGridItem(context, 'Complaints', Icons.report_problem, Colors.redAccent),
                  _buildModernGridItem(context, 'Elections', Icons.how_to_reg, Colors.purple),
                  _buildModernGridItem(context, 'Profile', Icons.person, Colors.pink),
                  _buildModernGridItem(context, 'Settings', Icons.settings, Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String name, String? photoUrl) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text("Kudumbashree Member"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                  ? NetworkImage(photoUrl) 
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty) 
                  ? const Icon(Icons.person, size: 40, color: Colors.teal) 
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueGrey),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // UPDATED: Completely clears the navigation stack and sends user to Login Page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()), // Make sure your login class is named LoginPage
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.teal),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGridItem(BuildContext context, String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {}, 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}