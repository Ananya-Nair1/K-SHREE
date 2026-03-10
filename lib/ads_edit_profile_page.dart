import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ADSEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const ADSEditProfilePage({Key? key, required this.currentProfile}) : super(key: key);

  @override
  State<ADSEditProfilePage> createState() => _ADSEditProfilePageState();
}

class _ADSEditProfilePageState extends State<ADSEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controllers for Administrative Fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _officeAddressController;
  late TextEditingController _cdsRegController;
  
  String? _selectedCommittee;
  final List<String> _committees = [
    'Health & Sanitation',
    'Education & Childfest',
    'Infrastructure & Social Audit',
    'Micro-Finance Oversight',
    'Employment (MGNREGS)'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile['full_name']);
    _phoneController = TextEditingController(text: widget.currentProfile['phone_number']);
    _officeAddressController = TextEditingController(text: widget.currentProfile['office_address'] ?? '');
    _cdsRegController = TextEditingController(text: widget.currentProfile['cds_reg_number'] ?? '');
    _selectedCommittee = widget.currentProfile['sub_committee'];
  }

  Future<void> _updateADSProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await supabase.from('Registered_Members').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'office_address': _officeAddressController.text.trim(),
        'cds_reg_number': _cdsRegController.text.trim(),
        'sub_committee': _selectedCommittee,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('aadhar_number', widget.currentProfile['aadhar_number']);

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ADS Records Updated Successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color adsBlue = Color(0xFF4285F4);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit ADS Records", style: TextStyle(color: Colors.white)),
        backgroundColor: adsBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: adsBlue))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("General Information"),
                  _buildTextField(_nameController, "Full Name", Icons.person),
                  _buildTextField(_phoneController, "Official Phone", Icons.phone, isPhone: true),
                  
                  const SizedBox(height: 25),
                  _buildHeader("Governance & Oversight"),
                  _buildTextField(_officeAddressController, "ADS Office Address", Icons.location_on),
                  _buildTextField(_cdsRegController, "CDS Registration No.", Icons.app_registration),
                  
                  const SizedBox(height: 20),
                  const Text("Sub-Committee Membership", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCommittee,
                    decoration: _inputDecoration("Select Committee", Icons.account_tree),
                    items: _committees.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCommittee = val),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: adsBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _updateADSProfile,
                      child: const Text("Save Official Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: _inputDecoration(label, icon),
        validator: (v) => v!.isEmpty ? "This field is required" : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4285F4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}