import 'package:flutter/material.dart';
import 'package:k_shree/meeting_management.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

// Updated Imports
import 'secretary_pending_requests_page.dart';
import 'secretary_meeting_management_page.dart';
import 'secretary_unit_members_page.dart';
import 'secretary_unit_complaints_page.dart';
import 'secretary_reports_page.dart';
import 'secretary_loans_page.dart';
import 'secretary_schemes_page.dart';
import 'secretary_trainings_page.dart';
import 'secretary_savings_page.dart';
import 'secretary_settings_page.dart';
import 'secretary_notifications_page.dart'; 
import 'login_page.dart'; 
import 'secretary_elections_page.dart'; 

class SecretaryDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SecretaryDashboard({super.key, required this.userData});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _pendingMemberCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequestsCount();
  }

  Future<void> _fetchPendingRequestsCount() async {
    final supabase = Supabase.instance.client;
    final unit = widget.userData['unit_number'].toString();
    
    try {
      final response = await supabase
          .from('Pending_Approvals')
          .select('id')
          .eq('unit_number', unit);
      
      if (mounted) {
        setState(() {
          _pendingMemberCount = (response as List).length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching request count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.userData['full_name'] ?? 'Secretary';
    final String aadhar = widget.userData['aadhar_number']?.toString() ?? 'N/A';
    final String unit = widget.userData['unit_number']?.toString() ?? 'N/A';
    final String ward = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('NHG Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, name),
      body: RefreshIndicator(
        onRefresh: _fetchPendingRequestsCount,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name, aadhar, unit, ward), 

              const SizedBox(height: 30),

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
                      child: Stack(
                        children: [
                          _buildQuickActionCard(
                            context,
                            title: 'Member Requests',
                            icon: Icons.person_add_alt_1,
                            color: Colors.blue,
                            onTap: () async {
                              await Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => PendingRequestsPage(secretaryData: widget.userData)),
                              );
                              _fetchPendingRequestsCount(); 
                            },
                          ),
                          if (_pendingMemberCount > 0)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text('$_pendingMemberCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        title: 'Unit Complaints',
                        icon: Icons.report_problem,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UnitComplaintsPage(userData: widget.userData))),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

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
                    _buildModernGridItem('Meetings', Icons.calendar_month, Colors.deepPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MeetingManagementPage(userData: widget.userData)))),
                    _buildModernGridItem('Members', Icons.groups, Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UnitMembersPage(userData: widget.userData)))),
                    _buildModernGridItem('Reports', Icons.analytics, Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecretaryReportsPage(userData: widget.userData)))),
                    _buildModernGridItem('Loans', Icons.account_balance_wallet, Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoansPage(userData: widget.userData)))),
                    _buildModernGridItem('Schemes', Icons.account_balance, Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecretarySchemesPage(userData: widget.userData)))),
                    _buildModernGridItem('Trainings', Icons.school, Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecretaryTrainingsPage(userData: widget.userData)))),
                    _buildModernGridItem('Savings', Icons.savings, Colors.pink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SavingsPage(userData: widget.userData)))),
                    _buildModernGridItem('Announce', Icons.campaign, Colors.deepOrange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecretaryNotificationsPage(userData: widget.userData)))),
                    _buildModernGridItem('Election', Icons.how_to_vote, Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SecretaryElectionsPage(userData: widget.userData)))),
                    _buildModernGridItem('Settings', Icons.settings, Colors.grey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(userData: widget.userData)))),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildHeader(String name, String aadhar, String unit, String ward) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120, width: double.infinity,
          decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.teal)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _buildInfoChip(Icons.map, "Ward", ward),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _buildInfoChip(Icons.star, "Role", "Secretary"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, String name) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text("NHG Secretary"),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.teal)),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              const secureStorage = FlutterSecureStorage();
              await secureStorage.deleteAll(); 
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('biometric', false);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(children: [
      Row(children: [Icon(icon, size: 16, color: Colors.teal), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
    ]);
  }

  Widget _buildQuickActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color, size: 28)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
      ),
    );
  }

  Widget _buildModernGridItem(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap, 
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 32), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
        ),
      ),
    );
  }
}