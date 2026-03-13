import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecretaryEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const SecretaryEditProfilePage({Key? key, required this.currentProfile}) : super(key: key);

  @override
  State<SecretaryEditProfilePage> createState() => _SecretaryEditProfilePageState();
}

class _SecretaryEditProfilePageState extends State<SecretaryEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _bankNameCtrl, _accNoCtrl, _ifscCtrl, _panCtrl, _rationCtrl, _emergencyCtrl;
  String? _selectedCategory, _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _bankNameCtrl = TextEditingController(text: widget.currentProfile['bank_name']);
    _accNoCtrl = TextEditingController(text: widget.currentProfile['account_number']);
    _ifscCtrl = TextEditingController(text: widget.currentProfile['ifsc_code']);
    _panCtrl = TextEditingController(text: widget.currentProfile['pan_card']);
    _rationCtrl = TextEditingController(text: widget.currentProfile['ration_card_number']);
    _emergencyCtrl = TextEditingController(text: widget.currentProfile['emergency_contact']);
    _selectedCategory = widget.currentProfile['card_category'];
    _selectedBloodGroup = widget.currentProfile['blood_group'];
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('Registered_Members').update({
        'bank_name': _bankNameCtrl.text.trim(),
        'account_number': _accNoCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim().toUpperCase(),
        'pan_card': _panCtrl.text.trim().toUpperCase(),
        'ration_card_number': _rationCtrl.text.trim(),
        'emergency_contact': _emergencyCtrl.text.trim(),
        'card_category': _selectedCategory,
        'blood_group': _selectedBloodGroup,
      }).eq('aadhar_number', widget.currentProfile['aadhar_number']);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Secretary Details"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_bankNameCtrl, "Bank Name", Icons.account_balance),
              _buildField(_accNoCtrl, "Account Number", Icons.numbers, isNum: true),
              _buildField(_ifscCtrl, "IFSC", Icons.code),
              _buildField(_panCtrl, "PAN", Icons.credit_card),
              _buildField(_rationCtrl, "Ration Card", Icons.list_alt, isNum: true),
              _buildField(_emergencyCtrl, "Emergency Contact", Icons.phone, isNum: true),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Update Secretary Profile", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}