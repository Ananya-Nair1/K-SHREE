
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

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

      await supabase.storage.from('meeting-reports').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      final String publicUrl = supabase.storage.from('meeting-reports').getPublicUrl(fileName);

      await supabase.from('meetings').update({'report': publicUrl}).eq('meet_id', meetingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report uploaded successfully!")));
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
          // Using FutureBuilder for more reliable data fetching
          FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase
                .from('meetings')
                .select()
                .eq('status', 'held') // Ensuring only 'held' meetings show
                .eq('created_by', secretaryAadhar)
                .order('meeting_date', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final meetings = snapshot.data ?? [];

              if (meetings.isEmpty) {
                return const Center(child: Text("No meetings marked as 'held' yet."));
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
                      trailing: ElevatedButton.icon(
                        onPressed: _isUploading ? null : () => _uploadPdf(meetId),
                        icon: Icon(hasReport ? Icons.edit : Icons.upload_file, size: 18),
                        label: Text(hasReport ? "Edit" : "Add PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasReport ? Colors.orange : Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            const Center(child: CircularProgressIndicator(color: Colors.teal)),
        ],
      ),
    );
  }
}
