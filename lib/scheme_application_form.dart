import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'application_success_page.dart'; 

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
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _submitApplication() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a supporting document"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final extension = _selectedFile!.path.split('.').last;
      final fileName = "app_${widget.memberId}_${DateTime.now().millisecondsSinceEpoch}.$extension";
      
      // 1. Upload to 'scheme-documents' bucket
      await supabase.storage
          .from('scheme-documents') 
          .upload(fileName, _selectedFile!);

      // 2. Get Public URL
      final String publicUrl = supabase.storage.from('scheme-documents').getPublicUrl(fileName);

      // 3. Insert into database table
      await supabase.from('scheme_applications').insert({
        'scheme_id': widget.scheme['id'],
        'member_id': widget.memberId,
        'member_name': widget.memberName,
        'document_url': publicUrl,
        'status': 'Pending Review',
        'applied_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        // 4. Navigate to Success Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicationSuccessPage(
              schemeName: widget.scheme['title'],
              applicationDate: DateFormat('dd MMM yyyy').format(DateTime.now()),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Failed: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Apply for Scheme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Applying for:", style: TextStyle(color: Colors.grey.shade600)),
            Text(widget.scheme['title'], 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)
            ),
            const Divider(height: 40, thickness: 1),
            const Text("Supporting Document", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text("Upload Ration Card/Income Certificate (PDF/JPG)", 
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            
            // Upload Container
            InkWell(
              onTap: _isUploading ? null : _pickDocument,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile == null ? Colors.teal.withOpacity(0.2) : Colors.teal, 
                    width: 2
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.teal.shade400),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFile == null ? "Tap to Select File" : _selectedFile!.path.split('/').last,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _submitApplication,
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Submit Application", 
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}