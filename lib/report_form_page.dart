
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ReportSubmissionPage extends StatefulWidget {
  final Map<String, dynamic> meeting;
  final bool isEditing; // Added missing variable

  const ReportSubmissionPage({super.key, required this.meeting, required this.isEditing});

  @override
  State<ReportSubmissionPage> createState() => _ReportSubmissionPageState();
}

class _ReportSubmissionPageState extends State<ReportSubmissionPage> {
  bool _isUploading = false;

  Future<void> _uploadPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        File file = File(result.files.single.path!);
        String fileName = 'report_${widget.meeting['meet_id']}.pdf';

        // 1. Upload to storage bucket
        await Supabase.instance.client.storage.from('meeting_reports').upload(
          fileName, file, fileOptions: const FileOptions(upsert: true)
        );

        final publicUrl = Supabase.instance.client.storage.from('meeting_reports').getPublicUrl(fileName);

        // 2. Update meetings table status
        await Supabase.instance.client.from('meetings').update({
          'report_url': publicUrl,
          'status': 'executed' 
        }).eq('meet_id', widget.meeting['meet_id']);

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? "Edit Minutes" : "Submit Minutes")),
      body: Center(
        child: _isUploading 
          ? const CircularProgressIndicator() 
          : ElevatedButton(onPressed: _uploadPDF, child: const Text("Select PDF")),
      ),
    );
  }
}