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
      setState(() => _hasVoted = true);
      _calculateTopNominees();
    }
  }

  Future<void> _calculateTopNominees() async {
    // Fetch only the candidate IDs from the anonymous table
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
    
    setState(() {
      _topNominees = sortedEntries.take(3).toList();
    });
  }

  Future<void> _submitVote() async {
    if (_selectedCandidateId == null) return;

    try {
      // 1. Mark voter as "Voted" (identifiable, but doesn't show who they picked)
      await supabase.from('voter_receipts').insert({
        'unit_number': widget.unitNumber,
        'voter_id': widget.currentMemberId,
      });

      // 2. Drop the ballot in the box (anonymous, no link to voter)
      await supabase.from('anonymous_ballots').insert({
        'unit_number': widget.unitNumber,
        'candidate_id': _selectedCandidateId,
      });

      setState(() => _hasVoted = true);
      _calculateTopNominees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You have already voted or an error occurred.")));
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
      ),
      body: _hasVoted ? _buildNomineeResults() : _buildVoterList(),
    );
  }

  // --- UI: Voter List ---
  Widget _buildVoterList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.teal.withOpacity(0.05),
          child: const Row(
            children: [
              Icon(Icons.security, color: Colors.teal),
              SizedBox(width: 10),
              Expanded(child: Text("Your vote is 100% anonymous. No one, including the Secretary, can see your choice.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
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
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  bool isSelected = _selectedCandidateId == m['aadhar_number'];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isSelected ? Colors.teal : Colors.grey.shade200)),
                    child: ListTile(
                      onTap: () => setState(() => _selectedCandidateId = m['aadhar_number']),
                      leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Colors.teal)),
                      title: Text(m['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(isSelected ? Icons.check_circle : Icons.radio_button_off, color: isSelected ? Colors.teal : Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _selectedCandidateId == null ? null : _submitVote,
              child: const Text("Submit Anonymous Vote", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        )
      ],
    );
  }

  // --- UI: Results ---
  Widget _buildNomineeResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text("Thank You!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Your choice has been recorded anonymously.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            const Text("Top 3 Nominees for Discussion:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 20),
            ..._topNominees.map((n) => _buildResultCard(n.key, n.value)).toList(),
            const SizedBox(height: 40),
            const Text("Next Step:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            const Text("Discuss with the group to finalize the leader.", textAlign: TextAlign.center),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text("$votes Votes", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}