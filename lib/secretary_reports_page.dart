import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW: Import url_launcher

class SecretaryReportsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SecretaryReportsPage({super.key, required this.userData});

  @override
  State<SecretaryReportsPage> createState() => _SecretaryReportsPageState();
}

class _SecretaryReportsPageState extends State<SecretaryReportsPage> {
  final supabase = Supabase.instance.client;
  bool _isUploading = false;

  Future<void> _uploadPdf(String meetingId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) return;
      setState(() => _isUploading = true);

      final file = result.files.first;
      final fileBytes = file.bytes;
      final fileName = "report_${meetingId}_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (fileBytes == null) return;

      // Upload to Supabase Storage
      await supabase.storage.from('meeting-reports').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      // Get the public URL
      final String publicUrl = supabase.storage.from('meeting-reports').getPublicUrl(fileName);

      // Save the URL to the meeting row
      await supabase.from('meetings').update({'report': publicUrl}).eq('meet_id', meetingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report uploaded successfully!"), backgroundColor: Colors.green));
        setState(() {}); // Refresh the view to show the new report status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // NEW: Function to launch the PDF URL
  Future<void> _viewPdf(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open the document.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error opening document: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extracting Aadhar safely from userData
    final String secretaryAadhar = widget.userData['aadhar_number']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meeting Reports", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            // We build the query directly inside the future
            future: supabase
                .from('meetings')
                .select()
                .eq('status', 'HELD') // FIXED: Must be uppercase 'HELD' to match your database!
                .eq('created_by', secretaryAadhar)
                .order('meeting_date', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.teal));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              final meetings = snapshot.data ?? [];

              if (meetings.isEmpty) {
                return const Center(child: Text("No meetings marked as 'HELD' yet.\nMembers must mark attendance first!", textAlign: TextAlign.center));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: meetings.length,
                itemBuilder: (context, index) {
                  final meeting = meetings[index];
                  final String meetId = meeting['meet_id'].toString();
                  final String? reportUrl = meeting['report'];
                  final bool hasReport = reportUrl != null && reportUrl.isNotEmpty;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: hasReport ? Colors.green[100] : Colors.teal[50],
                        child: Icon(hasReport ? Icons.task_alt : Icons.picture_as_pdf, 
                                    color: hasReport ? Colors.green : Colors.teal),
                      ),
                      title: Text(meeting['reason'] ?? "Meeting", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Date: ${meeting['meeting_date']}\nVenue: ${meeting['venue']}"),
                      
                      // NEW: Wrap trailing buttons in a Row to show both View and Edit
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasReport) ...[
                            TextButton.icon(
                              onPressed: () => _viewPdf(reportUrl),
                              icon: const Icon(Icons.visibility, color: Colors.blue, size: 18),
                              label: const Text("View", style: TextStyle(color: Colors.blue)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : () => _uploadPdf(meetId),
                            icon: Icon(hasReport ? Icons.edit : Icons.upload_file, size: 18),
                            label: Text(hasReport ? "Edit" : "Add PDF"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasReport ? Colors.orange : Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 15),
                        Text("Uploading PDF...", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}