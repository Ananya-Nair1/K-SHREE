import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import all the pages we built
import 'cds_financial_summary_page.dart';
import 'cds_grievance_management_page.dart';
import 'cds_loan_approval_page.dart';
import 'cds_schemes_page.dart';
import 'cds_meeting_monitor_page.dart';
import 'member_search_page.dart';
import 'cds_calendar_page.dart';
import 'cds_report_generator.dart'; // The PDF generator
import 'cds_scheme_approvals_page.dart';
import 'cds_unit_analytics_page.dart';

class CDSDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CDSDashboard({super.key, required this.userData});

  @override
  State<CDSDashboard> createState() => _CDSDashboardState();
}

class _CDSDashboardState extends State<CDSDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  int _totalMembers = 0;
  int _totalADS = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final panchayat = widget.userData['panchayat'];

      final membersResponse = await supabase
          .from('Registered_Members')
          .select('aadhar_number')
          .eq('panchayat', panchayat);

      final adsResponse = await supabase
          .from('Registered_Members')
          .select('aadhar_number')
          .eq('panchayat', panchayat)
          .eq('designation', 'ADS_Chairperson');

      if (mounted) {
        setState(() {
          _totalMembers = (membersResponse as List).length;
          _totalADS = (adsResponse as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('CDS Command Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => CDSReportGenerator.generatePanchayatReport(
              panchayat: widget.userData['panchayat'] ?? "N/A",
              chairperson: widget.userData['full_name'] ?? "N/A",
              totalMembers: _totalMembers,
              totalADS: _totalADS,
              savings: 0.0, // You can fetch real totals here
              loans: 0.0,
            ),
          ),
          IconButton(
            onPressed: () => supabase.auth.signOut().then((_) => Navigator.pushReplacementNamed(context, '/login')),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(primaryColor),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(),
                        const SizedBox(height: 25),
                        const Text("Management Modules", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 15),
                        _buildActionGrid(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Official Dashboard,", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          Text(widget.userData['full_name'] ?? "CDS Chairperson",
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Panchayat: ${widget.userData['panchayat']?.toUpperCase()}",
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard("Total Members", _totalMembers.toString(), Icons.people, Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard("ADS Units", _totalADS.toString(), Icons.account_balance, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _menuCard("Financials", Icons.account_balance_wallet, Colors.teal, () => _nav(CDSFinancialSummaryPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Grievances", Icons.gavel, Colors.orange, () => _nav(CDSGrievanceManagementPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Loan Apps", Icons.assignment_turned_in, Colors.blue, () => _nav(CDSLoanApprovalPage(panchayat: widget.userData['panchayat']))),
        _menuCard("New Schemes", Icons.library_add, Colors.purple, () => _nav(CDSSchemesPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Scheme Apps", Icons.how_to_reg, Colors.cyan, () => _nav(CDSSchemeApprovalsPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Calendar", Icons.event_note, Colors.brown, () => _nav(CDSCalendarPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Meeting Audit", Icons.monitor_heart, Colors.red, () => _nav(CDSMeetingMonitorPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Unit Rank", Icons.bar_chart, Colors.indigo, () => _nav(CDSUnitAnalyticsPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Member Search", Icons.person_search, Colors.green, () => _nav(MemberSearchPage(panchayat: widget.userData['panchayat']))),
        _menuCard("Broadcast", Icons.campaign, Colors.pink, () => _showBroadcastDialog()),
      ],
    );
  }

  Widget _menuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _nav(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (context) => page));

  void _showBroadcastDialog() {
    final t = TextEditingController();
    final m = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Panchayat Broadcast"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: t, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: m, decoration: const InputDecoration(labelText: "Message"), maxLines: 3),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            await supabase.from('unit_notifications').insert({'title': t.text, 'message': m.text, 'panchayat': widget.userData['panchayat'], 'target_audience': 'All Members', 'is_urgent': true});
            Navigator.pop(c);
          }, child: const Text("Send")),
        ],
      ),
    );
  }
}