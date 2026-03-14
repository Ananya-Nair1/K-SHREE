import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CDSUnitAnalyticsPage extends StatefulWidget {
  final String panchayat;
  const CDSUnitAnalyticsPage({super.key, required this.panchayat});

  @override
  State<CDSUnitAnalyticsPage> createState() => _CDSUnitAnalyticsPageState();
}

class _CDSUnitAnalyticsPageState extends State<CDSUnitAnalyticsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _unitStats = [];

  @override
  void initState() {
    super.initState();
    _fetchUnitData();
  }

  Future<void> _fetchUnitData() async {
    try {
      // 1. Fetch all members and meetings to calculate per-unit stats
      final membersResponse = await supabase
          .from('Registered_Members')
          .select('ward, unit_number')
          .eq('panchayat', widget.panchayat);

      final meetingsResponse = await supabase
          .from('meetings')
          .select('ward, status')
          .eq('panchayat', widget.panchayat);

      // 2. Process data into a Map grouped by Ward
      Map<String, Map<String, dynamic>> statsMap = {};

      for (var member in membersResponse) {
        String ward = member['ward'].toString();
        statsMap.putIfAbsent(ward, () => {'ward': ward, 'members': 0, 'meetings': 0});
        statsMap[ward]!['members']++;
      }

      for (var meeting in meetingsResponse) {
        String ward = meeting['ward'].toString();
        if (statsMap.containsKey(ward) && meeting['status'] == 'HELD') {
          statsMap[ward]!['meetings']++;
        }
      }

      // 3. Convert to List and Sort by member count
      List<Map<String, dynamic>> sortedList = statsMap.values.toList();
      sortedList.sort((a, b) => b['members'].compareTo(a['members']));

      setState(() {
        _unitStats = sortedList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Analytics Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Performance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                _buildSummaryBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _unitStats.length,
                    itemBuilder: (context, index) {
                      final data = _unitStats[index];
                      return _buildUnitCard(data, index + 1);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      color: Colors.teal.shade50,
      child: const Row(
        children: [
          Icon(Icons.insights, color: Colors.teal),
          SizedBox(width: 10),
          Text("Ranking Wards by Member Strength", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> data, int rank) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: rank <= 3 ? Colors.amber : Colors.grey.shade200,
              child: Text("#$rank", style: TextStyle(color: rank <= 3 ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ward ${data['ward']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("${data['members']} Registered Members", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Held", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("${data['meetings']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Text("Meetings", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}