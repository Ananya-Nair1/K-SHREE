
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'report_form_page.dart';

class ReportsManagementPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ReportsManagementPage({super.key, required this.userData});

  @override
  State<ReportsManagementPage> createState() => _ReportsManagementPageState();
}

class _ReportsManagementPageState extends State<ReportsManagementPage> {
  late final Stream<List<Map<String, dynamic>>> _meetingsStream;

  @override
  void initState() {
    super.initState();
    // Listening to the 'meetings' table stream
    _meetingsStream = Supabase.instance.client
        .from('meetings')
        .stream(primaryKey: ['meet_id'])
        .order('meeting_date', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        appBar: AppBar(
          title: const Text('Meeting Reports', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2B6CB0),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "ADS Meetings"),
              Tab(text: "NHG Meetings"),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _meetingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

            final allMeetings = snapshot.data ?? [];
            
            // IMPROVED FILTER: 
            // Using .contains() ensures "ADS Internal" or "ADS Executive" are captured.
            final adsMeetings = allMeetings.where((m) {
              final level = m['meeting_level']?.toString().toUpperCase() ?? '';
              return level.contains('ADS');
            }).toList();
            
            // NHG Meetings are defined as anything that does NOT contain "ADS"
            final nhgMeetings = allMeetings.where((m) {
              final level = m['meeting_level']?.toString().toUpperCase() ?? '';
              return !level.contains('ADS');
            }).toList();

            return TabBarView(
              children: [
                _buildMeetingList(adsMeetings, canUpload: true),
                _buildMeetingList(nhgMeetings, canUpload: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMeetingList(List<Map<String, dynamic>> meetings, {required bool canUpload}) {
    if (meetings.isEmpty) {
      return const Center(
        child: Text("No meetings found.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meet = meetings[index];
        final bool hasReport = meet['report_url'] != null && meet['report_url'].toString().isNotEmpty;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              meet['reason'] ?? 'Meeting', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("Date: ${meet['meeting_date']}"),
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                // View Button
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: hasReport ? () => _viewPdf(meet['report_url']) : null,
                  tooltip: 'View Report',
                ),
                // Upload/Edit Button (Only for ADS tab based on your canUpload logic)
                if (canUpload)
                  IconButton(
                    icon: Icon(
                      hasReport ? Icons.edit_note : Icons.upload_file, 
                      color: Colors.green
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportSubmissionPage(
                          meeting: meet, 
                          isEditing: hasReport
                        ),
                      ),
                    ),
                    tooltip: hasReport ? 'Edit Report' : 'Upload Report',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _viewPdf(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch $url");
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }
}