import 'package:flutter/material.dart';
import 'pending_requests_page.dart';
import 'meeting_management.dart'; 
import 'unit_members_page.dart';
// ADD THIS IMPORT: Make sure this points to your actual login page file
import 'login_page.dart'; 

class SecretaryDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const SecretaryDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Safely extract dynamic data
    final String name = userData['full_name'] ?? 'Secretary';
    final String aadhar = userData['aadhar_number']?.toString() ?? 'N/A';
    final String unit = userData['unit_number']?.toString() ?? 'N/A';
    // Checking both 'ward' and 'ward_number' just in case of DB variations
    final String ward = (userData['ward'] ?? userData['ward_number'])?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Clean modern background
      appBar: AppBar(
        title: const Text('NHG Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, name),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header with overlapping Profile Card
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Curved Teal Background
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
                // Profile Card
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
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFFE0F2F1),
                              child: Icon(Icons.person, size: 35, color: Colors.teal),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  const SizedBox(height: 4),
                                  Text('ID: $aadhar', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                            Container(width: 1, height: 30, color: Colors.grey[300]), // Divider
                            _buildInfoChip(Icons.map, "Ward", ward),
                            Container(width: 1, height: 30, color: Colors.grey[300]), // Divider
                            _buildInfoChip(Icons.star, "Role", "Secretary"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Quick Actions Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Primary Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Member Requests',
                      icon: Icons.person_add_alt_1,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PendingRequestsPage(unitNumber: userData['unit_number'])),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Unit Complaints',
                      icon: Icons.report_problem,
                      color: Colors.orange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaints Module Coming Soon")));
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Grid Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                  _buildModernGridItem(
                    'Meetings', 
                    Icons.calendar_month, 
                    Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MeetingManagementScreen(userData: userData)),
                      );
                    },
                  ),
                  _buildModernGridItem(
                    'Members', 
                    Icons.groups, 
                    Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UnitMembersPage(secretaryData: userData)),
                      );
                    },
                  ),
                  _buildModernGridItem('Reports', Icons.analytics, Colors.teal),
                  _buildModernGridItem('Loans', Icons.account_balance_wallet, Colors.green),
                  _buildModernGridItem('Schemes', Icons.account_balance, Colors.blue),
                  _buildModernGridItem('Trainings', Icons.school, Colors.orange),
                  _buildModernGridItem('Savings', Icons.savings, Colors.pink),
                  _buildModernGridItem('Elections', Icons.how_to_reg, Colors.redAccent),
                  _buildModernGridItem('Settings', Icons.settings, Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Helper to build the Drawer
  Widget _buildDrawer(BuildContext context, String name) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text("NHG Secretary"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.teal),
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

  /// Helper for the Unit and Ward chips inside the profile card
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

  /// Helper for the large Quick Action buttons (Requests & Complaints)
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

  /// Helper for the clean grid items
  Widget _buildModernGridItem(String title, IconData icon, Color color, {VoidCallback? onTap}) {
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
          onTap: onTap, 
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