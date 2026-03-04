import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';

class MembershipApplicationPage extends StatefulWidget {
  const MembershipApplicationPage({Key? key}) : super(key: key);

  @override
  State<MembershipApplicationPage> createState() => _MembershipApplicationPageState();
}

class _MembershipApplicationPageState extends State<MembershipApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers
  final districtController = TextEditingController();
  final panchayatController = TextEditingController();
  final wardController = TextEditingController();
  final unitController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final aadharController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController(); // NEW: Password Controller

  // Image Variables
  Uint8List? _memberPhotoBytes;
  Uint8List? _signaturePhotoBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isMemberPhoto) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isMemberPhoto) _memberPhotoBytes = bytes;
        else _signaturePhotoBytes = bytes;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _generatePdf(String requestId) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("K-SHREE Membership Receipt", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text("Applicant: ${nameController.text.trim()}", style: const pw.TextStyle(fontSize: 18)),
                pw.Text("Request ID: $requestId", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                pw.SizedBox(height: 30),
                pw.Text("Date: ${DateTime.now().toString().substring(0, 10)}"),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Application Submitted!", style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your Request ID:"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(requestId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _generatePdf(requestId),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Download PDF Receipt"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: requestId));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
            },
            child: const Text("Copy ID"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_memberPhotoBytes == null || _signaturePhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload both your photo and signature.")));
      return;
    }

    setState(() => _isLoading = true);

    final panchayat = panchayatController.text.trim().toUpperCase();
    String code = panchayat.length >= 3 ? panchayat.substring(0, 3) : "REQ";
// Adds a unique 5-digit number to the end of every ID so they never collide!
final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
final generatedId = "REQ-$code-${wardController.text.trim()}-${unitController.text.trim()}-$timestamp";
    try {
      final storage = Supabase.instance.client.storage.from('applications');

      // 1. Upload Photo
      final photoPath = 'photos/$generatedId-photo.jpg';
      await storage.uploadBinary(photoPath, _memberPhotoBytes!, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final photoUrl = storage.getPublicUrl(photoPath);

      // 2. Upload Signature
      final signPath = 'signatures/$generatedId-sign.jpg';
      await storage.uploadBinary(signPath, _signaturePhotoBytes!, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final signUrl = storage.getPublicUrl(signPath);

      // 3. Save to Database (Including the new password)
      await Supabase.instance.client.from('pending_requests').insert({
        'pending_id': generatedId,
        'district': districtController.text.trim(),
        'panchayat': panchayatController.text.trim(),
        'ward': int.tryParse(wardController.text.trim()) ?? 0,
        'unit_number': int.tryParse(unitController.text.trim()) ?? 0,
        'full_name': nameController.text.trim(),
        'dob': dobController.text.trim(),
        'aadhar_number': aadharController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'password': passwordController.text.trim(), // NEW: Saving the password
        'status': 'Submitted',
        'photo_url': photoUrl,       
        'signature_url': signUrl,    
      });

      if (mounted) _showSuccessDialog(generatedId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImageUploadBox(String label, Uint8List? imageBytes, bool isMemberPhoto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(" $label", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickImage(isMemberPhoto),
            child: Container(
              height: isMemberPhoto ? 150 : 100, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.3), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(imageBytes, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isMemberPhoto ? Icons.add_a_photo : Icons.draw, color: Colors.teal, size: 30),
                        const SizedBox(height: 8),
                        Text("Tap to upload $label", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  /// UPGRADED: Now supports 'isPassword' to hide text
  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType keyboard = TextInputType.text, int lines = 1, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: isPassword ? 1 : lines, // Passwords must be single line
        obscureText: isPassword,          // Hides text if it's a password
        decoration: _inputDecoration(label, icon),
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter $label";
          if (label == "Aadhar Number" && (value.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(value))) return "Enter 12-digit Aadhar";
          if (label == "Phone Number" && (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value))) return "Enter 10-digit Phone";
          if ((label == "Ward Number" || label == "Unit Number") && !RegExp(r'^[0-9]+$').hasMatch(value)) return "Numbers only";
          if (isPassword && value.length < 6) return "Password must be at least 6 characters"; // Security check
          return null; 
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDEAE3),
      appBar: AppBar(
        title: const Text("Membership Application", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Personal Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 20),
                    
                    _buildField("District", districtController, Icons.location_city),
                    _buildField("Panchayat", panchayatController, Icons.map),
                    _buildField("Ward Number", wardController, Icons.numbers, keyboard: TextInputType.number),
                    _buildField("Unit Number", unitController, Icons.home_work, keyboard: TextInputType.number),
                    _buildField("Full Name", nameController, Icons.person),
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: _inputDecoration("Date of Birth", Icons.calendar_today),
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                      ),
                    ),

                    _buildField("Aadhar Number", aadharController, Icons.credit_card, keyboard: TextInputType.number),
                    _buildField("Phone Number", phoneController, Icons.phone, keyboard: TextInputType.phone),
                    _buildField("Full Address", addressController, Icons.home, lines: 3),
                    
                    // NEW: Password Field
                    _buildField("Create Password", passwordController, Icons.lock, isPassword: true),

                    const Divider(height: 40, thickness: 1),
                    
                    const Text("Upload Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 20),
                    
                    _buildImageUploadBox("Passport Size Photo", _memberPhotoBytes, true),
                    _buildImageUploadBox("Digital Signature", _signaturePhotoBytes, false),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Submit Application", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}