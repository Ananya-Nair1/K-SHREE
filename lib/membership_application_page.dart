import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Built-in: No pubspec entry needed
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MembershipApplicationPage extends StatefulWidget {
  const MembershipApplicationPage({Key? key}) : super(key: key);

  @override
  State<MembershipApplicationPage> createState() => _MembershipApplicationPageState();
}

class _MembershipApplicationPageState extends State<MembershipApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final districtController = TextEditingController();
  final panchayatController = TextEditingController();
  final wardController = TextEditingController();
  final unitController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final aadharController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final panchayat = panchayatController.text.trim().toUpperCase();
    String code = panchayat.length >= 3 ? panchayat.substring(0, 3) : "REQ";
    final generatedId = "REQ-$code-${wardController.text.trim()}-${unitController.text.trim()}";

    try {
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
        'status': 'Submitted',
      });

      if (mounted) _showSuccessDialog(generatedId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            Text(requestId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _generatePdf(requestId),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Download PDF"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // This uses the built-in Clipboard
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDEAE3),
      appBar: AppBar(title: const Text("Apply for Membership"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("District", districtController),
              _buildField("Panchayat", panchayatController),
              _buildField("Ward", wardController, keyboard: TextInputType.number),
              _buildField("Unit Number", unitController, keyboard: TextInputType.number),
              _buildField("Full Name", nameController),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(labelText: "DOB", prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                ),
              ),
              _buildField("Aadhar", aadharController, keyboard: TextInputType.number),
              _buildField("Phone", phoneController, keyboard: TextInputType.phone),
              _buildField("Address", addressController, lines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType keyboard = TextInputType.text, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      ),
    );
  }
}