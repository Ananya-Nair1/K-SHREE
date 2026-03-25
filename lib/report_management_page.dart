import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
           
            // Filter for ADS Meetings
            final adsMeetings = allMeetings.where((m) {
              final level = m['meeting_level']?.toString().toUpperCase() ?? '';
              return level.contains('ADS');
            }).toList();
           
            // Filter for NHG Meetings (Anything not ADS)
            final nhgMeetings = allMeetings.where((m) {
              final level = m['meeting_level']?.toString().toUpperCase() ?? '';
              return !level.contains('ADS');
            }).toList();

            return TabBarView(
              children: [
                _buildMeetingList(adsMeetings, canUpload: true),
                _buildMeetingList(nhgMeetings, canUpload: false), // NHG reports can only be viewed
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
        // Ensure we check the correct column name 'report' from your schema
        final bool hasReport = meet['report'] != null && meet['report'].toString().isNotEmpty;

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
              child: Text("Date: ${meet['meeting_date'] ?? 'N/A'}"),
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                // View Button (Available for both tabs if a report exists)
                IconButton(
                  icon: Icon(Icons.visibility, color: hasReport ? Colors.blue : Colors.grey.shade300),
                  onPressed: hasReport ? () => _viewPdf(meet['report']) : null,
                  tooltip: hasReport ? 'View Report' : 'No Report Available',
                ),
               
                // Upload/Edit Button (Only visible on the ADS tab)
                if (canUpload)
                  IconButton(
                    icon: Icon(
                      hasReport ? Icons.edit_note : Icons.upload_file,
                      color: Colors.green
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => UploadMeetingReportDialog(
                          meetId: meet['meet_id'].toString(),
                        ),
                      );
                    },
                    tooltip: hasReport ? 'Update Report' : 'Upload Report',
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

// ==========================================
// NEW: UPLOAD MEETING REPORT DIALOG (WEB SAFE)
// ==========================================
class UploadMeetingReportDialog extends StatefulWidget {
  final String meetId;

  const UploadMeetingReportDialog({
    super.key,
    required this.meetId,
  });

  @override
  State<UploadMeetingReportDialog> createState() => _UploadMeetingReportDialogState();
}

class _UploadMeetingReportDialogState extends State<UploadMeetingReportDialog> {
  Uint8List? _selectedFileBytes;
  bool _isUploading = false;
  String? _fileName;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (_selectedFileBytes == null) return;
    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final storagePath = '${widget.meetId}/$uniqueFileName';

      // 1. Upload to Storage Bucket named 'meeting_reports'
      await supabase.storage
          .from('meeting_reports')
          .uploadBinary(
            storagePath,
            _selectedFileBytes!,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      // 2. Get Public URL
      final fileUrl = supabase.storage
          .from('meeting_reports')
          .getPublicUrl(storagePath);

      // 3. Update the 'report' column in the meetings table
      await supabase
          .from('meetings')
          .update({'report': fileUrl})
          .eq('meet_id', widget.meetId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("Meeting Report uploaded!")]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Upload Meeting Report", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Select a PDF report for this meeting.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
         
          if (_selectedFileBytes != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_fileName ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: _isUploading ? null : () => setState(() => _selectedFileBytes = null),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text("Choose PDF File"),
            ),
        ],
      ),
      actions: [
        if (!_isUploading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2B6CB0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _selectedFileBytes == null || _isUploading ? null : _uploadAndSave,
          child: _isUploading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Upload & Save"),
        ),
      ],
    );
  }
}