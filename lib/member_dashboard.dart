import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifications_page.dart';
import 'member.dart'; 
import 'member_meetings_page.dart';
import 'member_grievance_page.dart';
import 'login_page.dart'; 
import 'member_profile_page.dart';
import 'member_savings_page.dart';
import 'member_settings_page.dart';
import 'member_loans_page.dart';
import 'member_schemes_page.dart'; 
import 'member_election_page.dart'; 

class MemberDashboard extends StatefulWidget {
  final Member member;

  const MemberDashboard({Key? key, required this.member}) : super(key: key);

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final supabase = Supabase.instance.client;
  String _latestNews = "Loading latest unit updates...";
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnitNews();
  }

  Future<void> _fetchUnitNews() async {
    try {
      final response = await supabase
          .from('unit_notifications')
          .select()
          .eq('unit_number', '4') 
          .order('created_at', ascending: false);

      if (response != null && (response as List).isNotEmpty) {
        setState(() {
          _latestNews = response[0]['title'] + ": " + (response[0]['message'] ?? "");
          _unreadNotifications = response.length;
        });
      } else {
        setState(() {
          _latestNews = "No active announcements for Unit 4.";
          _unreadNotifications = 0;
        });
      }
    } catch (e) {
      setState(() => _latestNews = "Welcome to K-SHREE Dashboard");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.member.fullName ?? 'Member';
    final String userId = widget.member.userId ?? 'N/A';
    final String unit = '4'; 
    final String ward = 'Ward 2'; 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), 
      appBar: AppBar(
        title: const Text('K-SHREE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // FIXED: Passing the required userData Map instead of just the unitNumber
                      builder: (context) => NotificationsPage(
                        userData: {
                          'unit_number': unit,
                          'designation': 'Member',
                        },
                      ),
                    ),
                  );
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_unreadNotifications', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context, name, widget.member.photoUrl),
      body: RefreshIndicator(
        onRefresh: _fetchUnitNews,
        color: Colors.teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(name, userId, unit, ward),
              _buildNewsTicker(_latestNews, unit),
              const SizedBox(height: 25),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
              const SizedBox(height: 15),
              _buildQuickActions(context, userId),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("My Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
              const SizedBox(height: 15),
              _buildServicesGrid(context, userId, name, unit),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT HELPERS ---

  Widget _buildHeaderSection(String name, String userId, String unit, String ward) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120, width: double.infinity,
          decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
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
                    CircleAvatar(
                      radius: 32, backgroundColor: const Color(0xFFE0F2F1),
                      backgroundImage: (widget.member.photoUrl != null && widget.member.photoUrl!.isNotEmpty) ? NetworkImage(widget.member.photoUrl!) : null,
                      child: (widget.member.photoUrl == null || widget.member.photoUrl!.isEmpty) ? const Icon(Icons.person, size: 35, color: Colors.teal) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          Text('ID: $userId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                    _buildInfoChip(Icons.map, "Ward", ward),
                    _buildInfoChip(Icons.verified_user, "Status", "Active"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context, String userId, String name, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3, 
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.9,
        children: [
          _buildModernGridItem(context, 'Meetings', Icons.groups, Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberMeetingsPage(unitNumber: unit)))),
          _buildModernGridItem(context, 'Savings', Icons.savings, Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberSavingsPage(memberId: userId)))),
          _buildModernGridItem(context, 'My Loans', Icons.monetization_on, Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberLoansPage(memberId: userId)))),
          _buildModernGridItem(context, 'Schemes', Icons.account_balance, Colors.blue, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MemberSchemesPage(memberId: userId, memberName: name)));
          }),
          _buildModernGridItem(context, 'Trainings', Icons.school, Colors.orange),
          _buildModernGridItem(context, 'Complaints', Icons.report_problem, Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberGrievancePage(memberId: userId, unitNumber: unit)))),
          
          // Election Navigation Included
          _buildModernGridItem(context, 'Elections', Icons.how_to_reg, Colors.purple, onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => MemberElectionPage(unitNumber: unit, currentMemberId: userId))
            );
          }),

          _buildModernGridItem(context, 'Profile', Icons.person, Colors.pink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberProfilePage(memberId: userId)))),
          _buildModernGridItem(context, 'Settings', Icons.settings, Colors.grey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberSettingsPage(memberId: userId)))),
        ],
      ),
    );
  }

  Widget _buildNewsTicker(String news, String unit) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // FIXED: Passing the required userData Map here as well
            builder: (context) => NotificationsPage(
              userData: {
                'unit_number': unit,
                'designation': 'Member',
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 25, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign, color: Colors.amber.shade800, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                news,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.amber.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              context,
              title: 'My Passbook',
              icon: Icons.menu_book,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberSavingsPage(memberId: userId))),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildQuickActionCard(
              context,
              title: 'Apply for Loan',
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemberLoansPage(memberId: userId))),
            ),
          ),
        ],
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
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
              child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.teal) : null,
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard, color: Colors.blueGrey), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
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
      Row(children: [Icon(icon, size: 14, color: Colors.teal), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
    ]);
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
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color, size: 28)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 13))]),
      ),
    );
  }

  Widget _buildModernGridItem(BuildContext context, String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap, 
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11))]),
        ),
      ),
    );
  }
}