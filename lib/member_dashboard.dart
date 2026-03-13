import 'package:flutter/material.dart';
import 'member.dart'; // Ensure this points to your updated Member model class

<<<<<<< Updated upstream
class MemberDashboard extends StatelessWidget {
  final Member member; // Receives the logged-in member's data
=======
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
import 'member_trainings_page.dart'; 

class MemberDashboard extends StatefulWidget {
  final Member member;
>>>>>>> Stashed changes

  const MemberDashboard({Key? key, required this.member}) : super(key: key);

  @override
<<<<<<< Updated upstream
  Widget build(BuildContext context) {
    // Safely extract data with fallbacks
    final String name = member.fullName ?? 'Member';
    final String userId = member.userId ?? 'N/A';
    final String role = 'Member'; // Hardcoded to fix the getter error
    
    // Placeholders for now. You can add these to your Member class later!
    final String unit = 'Unit 4'; 
    final String ward = 'Ward 2'; 
=======
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final supabase = Supabase.instance.client;
  
  // Dynamic State Variables
  String _latestNews = "Loading latest unit updates...";
  int _unreadNotifications = 0;
  String _unit = "Loading...";
  String _ward = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Load member details first, then fetch the news for their specific unit
  Future<void> _loadDashboardData() async {
    await _fetchMemberDetails();
    if (_unit != "Loading..." && _unit != "N/A") {
      await _fetchUnitNews();
    } else {
      setState(() => _latestNews = "No active announcements.");
    }
  }

  // Fetch Unit and Ward from Registered_Members table
  Future<void> _fetchMemberDetails() async {
    try {
      final userId = widget.member.userId;
      if (userId == null) return;

      final response = await supabase
          .from('Registered_Members')
          .select('unit_number, ward') 
          .eq('aadhar_number', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _unit = response['unit_number']?.toString() ?? 'N/A';
          String dbWard = response['ward']?.toString() ?? 'N/A';
          _ward = dbWard.toLowerCase().contains('ward') ? dbWard : 'Ward $dbWard';
        });
      } else {
        setState(() {
          _unit = 'N/A';
          _ward = 'N/A';
        });
      }
    } catch (e) {
      debugPrint("Error fetching member details: $e");
      setState(() {
        _unit = 'N/A';
        _ward = 'N/A';
      });
    }
  }

  Future<void> _fetchUnitNews() async {
    try {
      final response = await supabase
          .from('unit_notifications')
          .select()
          .eq('unit_number', _unit) 
          .order('created_at', ascending: false);

      if (response != null && (response as List).isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastSeenStr = prefs.getString('last_seen_notifications_$_unit');
        
        int newCount = 0;
        
        if (lastSeenStr != null) {
          final lastSeenDate = DateTime.parse(lastSeenStr);
          for (var notif in response) {
            if (notif['created_at'] != null) {
              final notifDate = DateTime.parse(notif['created_at'].toString());
              if (notifDate.isAfter(lastSeenDate)) {
                newCount++;
              }
            }
          }
        } else {
          newCount = response.length;
        }

        setState(() {
          _latestNews = response[0]['title'] + ": " + (response[0]['message'] ?? "");
          _unreadNotifications = newCount; 
        });
      } else {
        setState(() {
          _latestNews = "No active announcements for Unit $_unit.";
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
>>>>>>> Stashed changes

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Clean modern background
      appBar: AppBar(
<<<<<<< Updated upstream
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
                // Floating Profile Card
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
=======
        title: const Text('K-SHREE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
                onPressed: () async {
                  if (_unit != "Loading..." && _unit != "N/A") {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationsPage(unitNumber: _unit)),
                    );
                    _fetchUnitNews();
                  }
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
        onRefresh: _loadDashboardData, 
        color: Colors.teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(name, userId, _unit, _ward), 
              _buildNewsTicker(_latestNews, _unit), 
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
              _buildServicesGrid(context, userId, name, _unit), 
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT HELPERS ---

  // THIS IS THE MISSING FUNCTION THAT CAUSED THE ERROR!
  void _navigateIfReady(BuildContext context, Widget page) {
    if (_unit == "Loading...") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loading member details, please wait...")));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

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
>>>>>>> Stashed changes
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // UPDATED: Now displays the real photo from Supabase!
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

<<<<<<< Updated upstream
            const SizedBox(height: 30),

            // Quick Actions Section
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
=======
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
          _buildModernGridItem(context, 'Meetings', Icons.groups, Colors.indigo, onTap: () => _navigateIfReady(context, MemberMeetingsPage(unitNumber: unit, memberId: userId))),
          _buildModernGridItem(context, 'Savings', Icons.savings, Colors.teal, onTap: () => _navigateIfReady(context, MemberSavingsPage(memberId: userId))),
          _buildModernGridItem(context, 'My Loans', Icons.monetization_on, Colors.green, onTap: () => _navigateIfReady(context, MemberLoansPage(memberId: userId))),
          _buildModernGridItem(context, 'Schemes', Icons.account_balance, Colors.blue, onTap: () => _navigateIfReady(context, MemberSchemesPage(memberId: userId, memberName: name))),
          _buildModernGridItem(context, 'Trainings', Icons.school, Colors.orange, onTap: () => _navigateIfReady(context, const MemberTrainingsPage())),
          _buildModernGridItem(context, 'Complaints', Icons.report_problem, Colors.redAccent, onTap: () => _navigateIfReady(context, MemberGrievancePage(memberId: userId, unitNumber: unit))),
          _buildModernGridItem(context, 'Elections', Icons.how_to_reg, Colors.purple, onTap: () => _navigateIfReady(context, MemberElectionPage(unitNumber: unit, currentMemberId: userId))),
          _buildModernGridItem(context, 'Profile', Icons.person, Colors.pink, onTap: () => _navigateIfReady(context, MemberProfilePage(memberId: userId))),
          _buildModernGridItem(context, 'Settings', Icons.settings, Colors.grey, onTap: () => _navigateIfReady(context, MemberSettingsPage(memberId: userId))),
        ],
      ),
    );
  }

  Widget _buildNewsTicker(String news, String unit) {
    return InkWell(
      onTap: () async {
        if (unit != "Loading..." && unit != "N/A") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationsPage(unitNumber: unit)),
          );
          _fetchUnitNews();
        }
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
>>>>>>> Stashed changes
              ),
            ),

            const SizedBox(height: 30),

            // Grid Section
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
                  _buildModernGridItem('Meetings', Icons.groups, Colors.indigo),
                  _buildModernGridItem('Savings', Icons.savings, Colors.teal),
                  _buildModernGridItem('My Loans', Icons.monetization_on, Colors.green),
                  _buildModernGridItem('Schemes', Icons.account_balance, Colors.blue),
                  _buildModernGridItem('Trainings', Icons.school, Colors.orange),
                  _buildModernGridItem('Complaints', Icons.report_problem, Colors.redAccent),
                  _buildModernGridItem('Elections', Icons.how_to_reg, Colors.purple),
                  _buildModernGridItem('Profile', Icons.person, Colors.pink),
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

<<<<<<< Updated upstream
  /// Helper to build the Drawer (Updated to show the photo here too)
=======
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
              onTap: () => _navigateIfReady(context, MemberSavingsPage(memberId: userId)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildQuickActionCard(
              context,
              title: 'Apply for Loan',
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
              onTap: () => _navigateIfReady(context, MemberLoansPage(memberId: userId)),
            ),
          ),
        ],
      ),
    );
  }

>>>>>>> Stashed changes
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
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  /// Helper for the Unit, Ward, and Role chips inside the profile card
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

  /// Helper for the large Quick Action buttons
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
  Widget _buildModernGridItem(String title, IconData icon, Color color) {
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
          onTap: () {}, // Action for grid items goes here
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