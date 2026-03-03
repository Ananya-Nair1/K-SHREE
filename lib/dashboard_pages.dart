import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member.dart';

class ComplaintsPage extends StatefulWidget {
  final Member? member;
  const ComplaintsPage({super.key, this.member});
  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // New vs History
  }

  Future<void> _submitComplaint() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client.from('complaints').insert({
        'member_id': widget.member?.userId ?? 'Unknown',
        'member_name': widget.member?.fullName ?? 'Anonymous',
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'Pending',
      });
      if (mounted) {
        _subjectController.clear(); _messageController.clear();
        _tabController.animateTo(1); // Auto-switch to history
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaints"), 
        backgroundColor: Colors.blue,
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "New", icon: Icon(Icons.add)), Tab(text: "History", icon: Icon(Icons.history))]),
      ),
      body: TabBarView(controller: _tabController, children: [_buildForm(), _buildHistory()]),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: _subjectController, decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _messageController, maxLines: 4, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitComplaint, child: _isSubmitting ? const CircularProgressIndicator() : const Text("Submit"))),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('complaints').stream(primaryKey: ['id']).eq('member_id', widget.member?.userId ?? '').order('created_at'),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (ctx, i) => Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(data[i]['subject']),
              subtitle: Text("Status: ${data[i]['status']}", style: TextStyle(color: data[i]['status'] == 'Resolved' ? Colors.green : Colors.orange)),
              children: [Padding(padding: const EdgeInsets.all(16), child: Text("Message: ${data[i]['message']}"))],
            ),
          ),
        );
      },
    );
  }
}

// Static Module Screens
class MeetingReportPage extends StatelessWidget {
  const MeetingReportPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Meeting Reports")), body: const Center(child: Text("Weekly Attendance: 85%")));
}

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Loans")), body: const Center(child: Text("Active Loan: ₹10,000")));
}

class SchemesPage extends StatelessWidget {
  const SchemesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Schemes")), body: const Center(child: Text("Amrutham Nutrimix - Eligible")));
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text("$title Coming Soon!")));
}