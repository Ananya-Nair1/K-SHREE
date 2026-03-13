import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberElectionPage extends StatefulWidget {
  final String unitNumber;
  final String currentMemberId;

  const MemberElectionPage({Key? key, required this.unitNumber, required this.currentMemberId}) : super(key: key);

  @override
  State<MemberElectionPage> createState() => _MemberElectionPageState();
}

class _MemberElectionPageState extends State<MemberElectionPage> {
  final supabase = Supabase.instance.client;
  String? _selectedCandidateId;
  bool _hasVoted = false;
  List<MapEntry<String, int>> _topNominees = [];

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyVoted();
  }

  Future<void> _checkIfAlreadyVoted() async {
    final response = await supabase
        .from('voter_receipts')
        .select()
        .eq('voter_id', widget.currentMemberId)
        .maybeSingle();
    
    if (response != null) {
      if (mounted) setState(() => _hasVoted = true);
      _calculateTopNominees();
    }
  }

  Future<void> _calculateTopNominees() async {
    final ballots = await supabase
        .from('anonymous_ballots')
        .select('candidate_id')
        .eq('unit_number', widget.unitNumber);

    Map<String, int> counts = {};
    for (var b in ballots) {
      String cid = b['candidate_id'];
      counts[cid] = (counts[cid] ?? 0) + 1;
    }

    var sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (mounted) {
      setState(() {
        _topNominees = sortedEntries.take(3).toList();
      });
    }
  }

  Future<void> _submitVote() async {
    if (_selectedCandidateId == null) return;

    try {
      // 1. Mark voter as "Voted"
      await supabase.from('voter_receipts').insert({
        'unit_number': widget.unitNumber,
        'voter_id': widget.currentMemberId,
      });

      // 2. Drop anonymous ballot
      await supabase.from('anonymous_ballots').insert({
        'unit_number': widget.unitNumber,
        'candidate_id': _selectedCandidateId,
      });

      if (mounted) setState(() => _hasVoted = true);
      _calculateTopNominees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error submitting vote.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Secret Ballot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Listen to the election status for this specific unit
        stream: supabase.from('election_status').stream(primaryKey: ['unit_number']).eq('unit_number', widget.unitNumber),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final bool noElection = snapshot.data == null || snapshot.data!.isEmpty;
          final bool isInactive = !noElection && snapshot.data!.first['is_active'] == false;
          final String positionName = !noElection ? snapshot.data!.first['position_name'] : "Election";

          // If no election exists or it's closed
          if (noElection || isInactive) {
            return _buildLockedScreen(noElection ? "No Active Election" : "Election Closed", positionName);
          }

          // If election is live
          return _hasVoted ? _buildNomineeResults(positionName) : _buildVoterList(positionName);
        },
      ),
    );
  }

  // --- UI: Locked Screen ---
  Widget _buildLockedScreen(String title, String position) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded, size: 80, color: Colors.teal.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text("The election for $position is not currently accepting votes. Please contact your Secretary.", 
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- UI: Voter List ---
  Widget _buildVoterList(String position) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.teal.shade700,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("VOTING FOR", style: TextStyle(color: Colors.teal.shade100, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(position, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Text("Encrypted & Anonymous", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: supabase.from('Registered_Members').select().eq('unit_number', widget.unitNumber),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final members = snapshot.data as List;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  bool isSelected = _selectedCandidateId == m['aadhar_number'];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.teal : Colors.white),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedCandidateId = m['aadhar_number']),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.teal : Colors.grey.shade100,
                        child: Icon(Icons.person_outline, color: isSelected ? Colors.white : Colors.grey),
                      ),
                      title: Text(m['full_name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.teal.shade900 : Colors.black87)),
                      trailing: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.teal : Colors.grey.shade300),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          onPressed: _selectedCandidateId == null ? null : _submitVote,
          child: const Text("Confirm & Submit Vote", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  // --- UI: Results ---
  Widget _buildNomineeResults(String position) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 100, color: Colors.teal),
            const SizedBox(height: 24),
            const Text("Vote Recorded", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            Text("Your ballot for $position has been submitted.", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.teal.withOpacity(0.1))),
              child: Column(
                children: [
                  const Text("Top Candidates (Unordered)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14)),
                  const SizedBox(height: 16),
                  ..._topNominees.map((n) => _buildResultCard(n.key, n.value)).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text("Final Decision", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
            const Text("Results are for discussion only. The NHG group must finalize the leader together.", 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String aadhar, int votes) {
    return FutureBuilder(
      future: supabase.from('Registered_Members').select('full_name').eq('aadhar_number', aadhar).single(),
      builder: (context, snapshot) {
        String name = snapshot.hasData ? (snapshot.data as Map)['full_name'] : "Loading...";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text("$votes", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}