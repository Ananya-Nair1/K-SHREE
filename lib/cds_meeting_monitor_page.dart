import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CDSMeetingMonitorPage extends StatefulWidget {
  final String panchayat;
  const CDSMeetingMonitorPage({super.key, required this.panchayat});

  @override
  State<CDSMeetingMonitorPage> createState() => _CDSMeetingMonitorPageState();
}

class _CDSMeetingMonitorPageState extends State<CDSMeetingMonitorPage> {
  final supabase = Supabase.instance.client;
  String? _selectedWard;
  List<String> _wards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWards();
  }

  Future<void> _fetchWards() async {
    try {
      // UPDATED: Querying the 'members' table based on your schema
      final response = await supabase
          .from('members')
          .select('ward')
          .eq('panchayat', widget.panchayat);
      
      final wardList = (response as List)
          .map((e) => e['ward'].toString())
          .toSet()
          .toList();
      
      // Sort wards numerically
      wardList.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      if (mounted) {
        setState(() {
          _wards = wardList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching wards: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openReport(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the report URL."))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Meeting Monitor", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- WARD FILTER ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedWard,
              decoration: InputDecoration(
                labelText: "Filter by Ward",
                labelStyle: const TextStyle(color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
                prefixIcon: const Icon(Icons.filter_list, color: Colors.teal),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("All Wards")),
                ..._wards.map((w) => DropdownMenuItem(value: w, child: Text("Ward $w"))),
              ],
              onChanged: (val) => setState(() => _selectedWard = val),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: (() async {
                // 1. Initialize the query
                var query = supabase
                    .from('meetings')
                    .select()
                    .eq('panchayat', widget.panchayat);
                
                // 2. APPLY FILTERS FIRST
                if (_selectedWard != null) {
                  query = query.eq('ward', _selectedWard!);
                }

                // 3. APPLY ORDERING LAST
                final response = await query.order('meeting_date', ascending: false);
                
                return List<Map<String, dynamic>>.from(response as List);
              })(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading meetings: ${snapshot.error}"));
                }
                
                final meetings = snapshot.data ?? [];
                if (meetings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        const Text("No meetings found for this ward.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    final String? reportUrl = meeting['report'];
                    final bool hasReport = reportUrl != null && reportUrl.isNotEmpty;
                    final String status = (meeting['status'] ?? 'SCHEDULED').toString().toUpperCase();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: status == 'HELD' 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.orange.withOpacity(0.1),
                          child: Icon(
                            status == 'HELD' ? Icons.check_circle : Icons.calendar_today, 
                            color: status == 'HELD' ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(meeting['reason'] ?? "NHG Meeting", 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                // UPDATED: Changed 'unit_name' to 'unit_number'
                                Text("Ward: ${meeting['ward']} | Unit: ${meeting['unit_number'] ?? 'N/A'}"),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                // UPDATED: Changed 'meeting_time' to 'time'
                                Text("${meeting['meeting_date']} • ${meeting['time'] ?? 'N/A'}"),
                              ],
                            ),
                          ],
                        ),
                        trailing: hasReport 
                          ? IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                              onPressed: () => _openReport(reportUrl),
                              tooltip: "View Report",
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pending_actions, color: Colors.grey, size: 20),
                                const Text("Pending", style: TextStyle(fontSize: 8, color: Colors.grey)),
                              ],
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}