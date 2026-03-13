import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecretaryElectionsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SecretaryElectionsPage({super.key, required this.userData});

  @override
  State<SecretaryElectionsPage> createState() => _SecretaryElectionsPageState();
}

class _SecretaryElectionsPageState extends State<SecretaryElectionsPage> {
  final supabase = Supabase.instance.client;

  // Function to open the "Create Election" Dialog
  void _showCreateElectionDialog() {
    final TextEditingController positionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Start New Election", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Warning: This will clear ALL current votes for a fresh start.",
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: positionController,
              decoration: InputDecoration(
                labelText: "Position (e.g., President, Treasurer)",
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () async {
              if (positionController.text.isEmpty) return;
              await _startNewElection(positionController.text);
              Navigator.pop(context);
            },
            child: const Text("Start Now", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _startNewElection(String position) async {
    final unitNum = widget.userData['unit_number'];
    try {
      // 1. Clear old data from ballots and receipts
      await supabase.from('anonymous_ballots').delete().eq('unit_number', unitNum);
      await supabase.from('voter_receipts').delete().eq('unit_number', unitNum);

      // 2. Upsert the election status
      await supabase.from('election_status').upsert({
        'unit_number': unitNum,
        'position_name': position,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Election Live!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _toggleElectionStatus(bool status) async {
    final unitNum = widget.userData['unit_number'];
    await supabase.from('election_status').update({'is_active': status}).eq('unit_number', unitNum);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status ? "Election Re-opened" : "Election Closed Successfully"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitNum = widget.userData['unit_number'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Unit Elections", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('election_status').stream(primaryKey: ['unit_number']).eq('unit_number', unitNum),
        builder: (context, statusSnapshot) {
          final bool hasActivePoll = statusSnapshot.hasData && statusSnapshot.data!.isNotEmpty;
          final String currentPosition = hasActivePoll ? statusSnapshot.data!.first['position_name'] : "No Active Poll";
          final bool isLive = hasActivePoll ? statusSnapshot.data!.first['is_active'] : false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CURRENT STATUS CARD ---
                _buildStatusHeader(currentPosition, isLive),
                const SizedBox(height: 24),
                
                // --- MANAGEMENT ACTIONS ---
                const Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: "Create Fresh Poll",
                  subtitle: "Clear all data and start new vote",
                  icon: Icons.add_to_photos_rounded,
                  color: Colors.teal,
                  onTap: _showCreateElectionDialog,
                ),
                const SizedBox(height: 12),
                if (hasActivePoll)
                  _buildActionCard(
                    title: isLive ? "Close Election" : "Re-open Election",
                    subtitle: isLive ? "Stop members from voting" : "Allow members to vote again",
                    icon: isLive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    color: isLive ? Colors.orange : Colors.green,
                    onTap: () => _toggleElectionStatus(!isLive),
                  ),

                const SizedBox(height: 32),
                
                // --- LIVE RESULTS SECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Live Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (isLive) 
                      const Chip(label: Text("LIVE"), backgroundColor: Colors.redAccent, labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('anonymous_ballots').stream(primaryKey: ['id']).eq('unit_number', unitNum),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    Map<String, int> counts = {};
                    for (var b in snapshot.data!) {
                      String cid = b['candidate_id'];
                      counts[cid] = (counts[cid] ?? 0) + 1;
                    }
                    
                    var sortedResults = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                    if (sortedResults.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = sortedResults[index];
                        return _buildSecretaryResultCard(entry.key, entry.value, snapshot.data!.length);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildStatusHeader(String position, bool isLive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal, Colors.teal.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CURRENT ELECTION", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isLive ? Colors.green.shade400 : Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(isLive ? "ACTIVE" : "CLOSED", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(position, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("No votes recorded yet", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildSecretaryResultCard(String aadhar, int votes, int totalVotes) {
    double progress = totalVotes > 0 ? votes / totalVotes : 0;

    return FutureBuilder(
      future: supabase.from('Registered_Members').select('full_name').eq('aadhar_number', aadhar).single(),
      builder: (context, snapshot) {
        String name = snapshot.hasData ? snapshot.data!['full_name'] : "Loading...";
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("$votes Votes", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                color: Colors.teal,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      },
    );
  }
}