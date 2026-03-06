import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditProfilePage({Key? key, required this.currentProfile}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Bank Controllers
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accNoCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _panCtrl;

  // Welfare Controllers
  late TextEditingController _rationCtrl;
  late TextEditingController _emergencyCtrl;
  
  String? _selectedCategory;
  String? _selectedBloodGroup;

  final List<String> _categories = ['APL', 'BPL', 'Antyodaya'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    // Pre-fill existing data
    _bankNameCtrl = TextEditingController(text: widget.currentProfile['bank_name']);
    _accNoCtrl = TextEditingController(text: widget.currentProfile['account_number']);
    _ifscCtrl = TextEditingController(text: widget.currentProfile['ifsc_code']);
    _panCtrl = TextEditingController(text: widget.currentProfile['pan_card']);
    _rationCtrl = TextEditingController(text: widget.currentProfile['ration_card_number']);
    _emergencyCtrl = TextEditingController(text: widget.currentProfile['emergency_contact']);

    // Handle Dropdowns (ensure existing values match the lists, otherwise null)
    _selectedCategory = _categories.contains(widget.currentProfile['card_category']) ? widget.currentProfile['card_category'] : null;
    _selectedBloodGroup = _bloodGroups.contains(widget.currentProfile['blood_group']) ? widget.currentProfile['blood_group'] : null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
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

      if (mounted) {
        Navigator.pop(context, true); // Return 'true' to tell the profile page to refresh
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Edit Additional Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Bank & KYC Details"),
              _buildTextField(_bankNameCtrl, "Bank Name", Icons.account_balance),
              const SizedBox(height: 15),
              _buildTextField(_accNoCtrl, "Account Number", Icons.numbers, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField(_ifscCtrl, "IFSC Code", Icons.account_tree),
              const SizedBox(height: 15),
              _buildTextField(_panCtrl, "PAN Card Number", Icons.credit_card),
              
              const SizedBox(height: 30),
              
              _buildSectionHeader("Health & Welfare"),
              _buildTextField(_rationCtrl, "Ration Card Number", Icons.featured_play_list, isNumber: true),
              const SizedBox(height: 15),
              _buildDropdown("Card Category", Icons.category, _categories, _selectedCategory, (val) => setState(() => _selectedCategory = val)),
              const SizedBox(height: 15),
              _buildDropdown("Blood Group", Icons.bloodtype, _bloodGroups, _selectedBloodGroup, (val) => setState(() => _selectedBloodGroup = val)),
              const SizedBox(height: 15),
              _buildTextField(_emergencyCtrl, "Emergency Contact No.", Icons.contact_emergency, isNumber: true),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Details", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}