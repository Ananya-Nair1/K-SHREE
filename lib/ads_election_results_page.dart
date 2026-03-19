import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ADSElectionResultsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSElectionResultsPage({super.key, required this.userData});

  @override
  State<ADSElectionResultsPage> createState() => _ADSElectionResultsPageState();
}

class _ADSElectionResultsPageState extends State<ADSElectionResultsPage> {
  final supabase = Supabase.instance.client;
  final Color adsBlue = const Color(0xFF2B6CB0);

  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedResults = {};
  Map<String, int> _totalVotesPerPosition = {};
  Map<String, bool> _activeStatusPerPosition = {};

  @override
  void initState() {
    super.initState();
    _fetchWardResults();
  }

  Future<void> _fetchWardResults() async {
    try {
      final String adsWard = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();
      final String adsPanchayat = widget.userData['panchayat']?.toString() ?? '';

      // 1. Fetch active statuses from the new table
      final statusResponse = await supabase
          .from('ward_election_status')
          .select('position_name, is_active')
          .eq('ward_number', adsWard)
          .eq('panchayat', adsPanchayat);

      final Map<String, bool> activePositions = {};
      for (var row in statusResponse) {
        activePositions[row['position_name'].toString()] = row['is_active'] == true;
      }

      // 2. Fetch all ward ballots from the new table
      final ballotsResponse = await supabase
          .from('ward_anonymous_ballots')
          .select('candidate_id, position_name')
          .eq('ward_number', adsWard);

      // Tally the votes
      final Map<String, Map<String, int>> rawVoteCounts = {};
      for (var ballot in ballotsResponse) {
        final candId = ballot['candidate_id']?.toString() ?? '';
        final posName = ballot['position_name']?.toString() ?? 'General';
        
        if (candId.isNotEmpty) {
          rawVoteCounts.putIfAbsent(posName, () => {});
          rawVoteCounts[posName]![candId] = (rawVoteCounts[posName]![candId] ?? 0) + 1;
        }
      }

      // 3. Match candidate IDs to their real names in Registered_Members
      final Map<String, List<Map<String, dynamic>>> compiledGroups = {};
      final Map<String, int> totalVotesGrouped = {};

      for (var entry in rawVoteCounts.entries) {
        final position = entry.key;
        final candVotes = entry.value;
        final candidateIds = candVotes.keys.toList();
        
        int totalForPosition = 0;

        // Fetch candidate details
        final candidatesResponse = await supabase
            .from('Registered_Members')
            .select('aadhar_number, full_name, photo_url')
            .inFilter('aadhar_number', candidateIds);

        final List<Map<String, dynamic>> positionResults = [];
        for (var cand in candidatesResponse) {
          final id = cand['aadhar_number'].toString();
          final votes = candVotes[id] ?? 0;
          totalForPosition += votes;
          
          positionResults.add({
            'id': id,
            'name': cand['full_name'] ?? 'Unknown Member',
            'photo_url': cand['photo_url'],
            'votes': votes,
          });
        }

        positionResults.sort((a, b) => (b['votes'] as int).compareTo(a['votes'] as int));
        compiledGroups[position] = positionResults;
        totalVotesGrouped[position] = totalForPosition;
        
        // Ensure even closed elections show up if they have votes, but keep status tracked
        if (!activePositions.containsKey(position)) {
           activePositions[position] = false; 
        }
      }

      if (mounted) {
        setState(() {
          _groupedResults = compiledGroups;
          _totalVotesPerPosition = totalVotesGrouped;
          _activeStatusPerPosition = activePositions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error reading database: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Ward Election Results", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: adsBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWardResults,
              child: _groupedResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _groupedResults.length,
                      itemBuilder: (context, index) {
                        final positionName = _groupedResults.keys.elementAt(index);
                        return _buildPositionSection(
                          positionName, 
                          _groupedResults[positionName]!, 
                          _totalVotesPerPosition[positionName] ?? 0, 
                          _activeStatusPerPosition[positionName] ?? false
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildPositionSection(String positionName, List<Map<String, dynamic>> candidates, int totalVotes, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(positionName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isActive ? Colors.orange : Colors.green, borderRadius: BorderRadius.circular(12)),
                child: Text(isActive ? "LIVE" : "CLOSED", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text("Total Votes: $totalVotes", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          ...candidates.asMap().entries.map((entry) {
            final int rank = entry.key;
            final candidate = entry.value;
            final bool isWinner = rank == 0 && !isActive && totalVotes > 0;
            final double votePercentage = totalVotes > 0 ? (candidate['votes'] / totalVotes) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isWinner ? Border.all(color: Colors.amber, width: 2) : Border.all(color: Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: adsBlue.withOpacity(0.1),
                          backgroundImage: candidate['photo_url'] != null ? NetworkImage(candidate['photo_url']) : null,
                          child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  if (isWinner) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("${candidate['votes']} Votes", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                        FractionallySizedBox(
                          widthFactor: votePercentage,
                          child: Container(height: 8, decoration: BoxDecoration(color: isWinner ? Colors.amber : adsBlue, borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100.0),
        child: Column(
          children: [
            Icon(Icons.how_to_vote, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("No votes have been cast yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}