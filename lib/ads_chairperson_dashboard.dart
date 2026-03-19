import 'package:flutter/material.dart';
import 'package:k_shree/report_management_page.dart';
import 'login_page.dart'; 
import 'member_meetings_page.dart'; 
import 'ads_notification_page.dart'; 
import 'ward_unit_page.dart';
import 'ads_member_meeting_page.dart';
import 'ads_chairperson_settings_page.dart'; 
import 'ads_chairperson_profile_page.dart';
import 'ads_loan_requests_page.dart'; 
import 'ads_complaints_page.dart'; 
import 'ads_chairperson_loans_page.dart'; 
import 'ads_savings_page.dart';
import 'ads_training_page.dart';
import 'ads_scheme_management_page.dart';
// Add these two new imports for the Election system
import 'ads_manage_election_page.dart';
import 'ads_election_results_page.dart';

class ADSChairpersonDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ADSChairpersonDashboard({super.key, required this.userData});

  // --- NEW: Bottom Sheet for Election Options ---
  void _showElectionOptions(BuildContext context, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ward Elections", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.redAccent.withOpacity(0.1), child: const Icon(Icons.how_to_reg, color: Colors.redAccent)),
              title: const Text("Manage Election", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Start or stop a ward-wide election"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ADSManageElectionPage(userData: userData)));
              },
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.indigo.withOpacity(0.1), child: const Icon(Icons.bar_chart, color: Colors.indigo)),
              title: const Text("View Results", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("See live tally and candidate standings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ADSElectionResultsPage(userData: userData)));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = userData['full_name'] ?? 'ADS Chairperson';
    final String aadhar = userData['aadhar_number']?.toString() ?? 'N/A';
    final String unit = userData['unit_number']?.toString() ?? 'N/A';
    final String ward = (userData['ward'] ?? userData['ward_number'])?.toString() ?? 'N/A';
    final String designation = userData['designation'] ?? 'ADS';

    const Color primaryColor = Color(0xFF2B6CB0); 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB), 
      appBar: AppBar(
        title: const Text('ADS Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            tooltip: 'View Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(userData: userData), 
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ADSChairpersonSettingsPage(adsId: aadhar),
                ),
              );
            },
          ),
          const SizedBox(width: 8), 
        ],
      ),
      drawer: _buildDrawer(context, name, aadhar), 
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
                    color: primaryColor,
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
                              backgroundColor: const Color(0xFFEBF8FF),
                              backgroundImage: userData['photo_url'] != null ? NetworkImage(userData['photo_url']) : null,
                              child: userData['photo_url'] == null ? const Icon(Icons.person, size: 35, color: primaryColor) : null,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
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
                            _buildInfoChip(Icons.home_work, "Unit", unit, primaryColor),
                            Container(width: 1, height: 30, color: Colors.grey[300]), 
                            _buildInfoChip(Icons.map, "Ward", ward, primaryColor),
                            Container(width: 1, height: 30, color: Colors.grey[300]), 
                            _buildInfoChip(Icons.star, "Role", designation, primaryColor),
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
              child: Text("Primary Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Loan Requests',
                      icon: Icons.attach_money,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ADSLoanRequestsPage(userData: userData),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'View Complaints',
                      icon: Icons.report_problem,
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ADSComplaintsPage(userData: userData),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
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
                        MaterialPageRoute(
                          builder: (context) => ADSMemberMeetingsPage(userData: userData),
                        ),
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
                        MaterialPageRoute(
                          builder: (context) => WardMembersPage(adsData: userData),
                        ),
                      );
                    },
                  ),
                  _buildModernGridItem(
                    'Reports', 
                    Icons.analytics_outlined, 
                    Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportsManagementPage(userData: userData),
                        ),
                      );
                    },
                  ),
                  _buildModernGridItem(
                    'My Loans', 
                    Icons.account_balance_wallet, 
                    Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ADSChairpersonLoansPage(memberId: aadhar),
                        ),
                      );
                    },
                  ),
                  _buildModernGridItem(
                    'Schemes', 
                    Icons.assignment_turned_in_rounded, 
                    Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ADSSchemesManagementPage(userData: userData),
                        ),
                      );
                    },
                  ),
                  _buildModernGridItem(
                    'Trainings', 
                    Icons.school, 
                    Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ADSTrainingsPage(userData: userData),
                        ),
                      );
                    },
                  ),
                  _buildModernGridItem(
                    'Ward Savings', 
                    Icons.savings, 
                    Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ADSWardSavingsPage(userData: userData),
                        ),
                      );
                    },
                  ),
                  
                  // --- NEW: Elections Grid Item connected to Bottom Sheet ---
                  _buildModernGridItem(
                    'Elections', 
                    Icons.how_to_reg, 
                    Colors.redAccent,
                    onTap: () => _showElectionOptions(context, userData),
                  ),

                  _buildModernGridItem(
                    'Settings', 
                    Icons.settings, 
                    Colors.grey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ADSChairpersonSettingsPage(adsId: aadhar),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String name, String aadhar) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2B6CB0)),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text("ADS Chairperson"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF2B6CB0)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueGrey),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.teal),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ADSChairpersonProfilePage(adsId: aadhar)),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748))),
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