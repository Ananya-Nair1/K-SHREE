import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchemeApplicationForm extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final String memberId;
  final String memberName;

  const SchemeApplicationForm({
    Key? key, 
    required this.scheme, 
    required this.memberId,
    required this.memberName
  }) : super(key: key);

  @override
  State<SchemeApplicationForm> createState() => _SchemeApplicationFormState();
}

class _SchemeApplicationFormState extends State<SchemeApplicationForm> {
  final supabase = Supabase.instance.client;
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _submitApplication() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload a supporting document")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload file to Supabase Storage
      final fileName = "${widget.memberId}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final String path = await supabase.storage
          .from('scheme-documents')
          .upload(fileName, _selectedFile!);

      // 2. Get Public URL
      final String publicUrl = supabase.storage.from('scheme-documents').getPublicUrl(fileName);

      // 3. Save application details to Table
      await supabase.from('scheme_applications').insert({
        'scheme_id': widget.scheme['id'],
        'member_id': widget.memberId,
        'member_name': widget.memberName,
        'document_url': publicUrl,
        'status': 'Pending Review',
      });

      if (mounted) {
        Navigator.pop(context); // Close form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted successfully!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply for Scheme"), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Applying for:", style: TextStyle(color: Colors.grey.shade600)),
            Text(widget.scheme['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(height: 40),
            
            const Text("Supporting Document", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Upload your Ration Card, Income Certificate, or Aadhar copy (PDF/JPG)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            
            InkWell(
              onTap: _pickDocument,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.teal.shade300),
                    const SizedBox(height: 10),
                    Text(_selectedFile == null ? "Tap to Select File" : "File Selected: ${_selectedFile!.path.split('/').last}"),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isUploading ? null : _submitApplication,
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Submit Application", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}