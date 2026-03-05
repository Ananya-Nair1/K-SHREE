import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member.dart'; 
import 'member_dashboard.dart';
import 'admin_dashboard.dart'; 
import 'secretary_dashboard.dart'; 
import 'inter_membership_page.dart';
import 'ads_chairperson_dashboard.dart'; // 1. Added import for ADS Dashboard

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedRole;
  bool _isLoading = false;

  final List<String> roles = [
    "Member", 
    "NHG_SECRETARY", 
    "ADS Member", 
    "ADS_Chairperson", // Matches the role in your login logic
    "CDS Member", 
    "CDS Chairperson"
  ];

  Future<void> _attemptLogin() async {
    setState(() => _isLoading = true);
    try {
      // 2. Logic for roles stored in 'Registered_Members' table (Secretary and ADS Chairperson)
      if (selectedRole == 'NHG_SECRETARY' || selectedRole == 'ADS_Chairperson') {
        final response = await Supabase.instance.client
            .from('Registered_Members')
            .select()
            .eq('aadhar_number', userIdController.text.trim())
            .eq('password', passwordController.text.trim())
            .eq('designation', selectedRole!)
            .maybeSingle();

        if (response != null && mounted) {
          if (selectedRole == 'NHG_SECRETARY') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SecretaryDashboard(userData: response)),
            );
          } else if (selectedRole == 'ADS_Chairperson') {
            // 3. Navigation to your new ADS Chairperson Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ADSChairpersonDashboard(userData: response)),
            );
          }
        } else {
          _showErrorDialog("Invalid $selectedRole Credentials. Please check your Aadhar and password.");
        }
      } else {
        // 4. Original Logic for general Members & Admins stored in 'members' table
        final response = await Supabase.instance.client
            .from('Registered_Members').select()
            .eq('aadhar_number', userIdController.text.trim())
            .eq('password', passwordController.text.trim())
            .maybeSingle();

        if (response != null && mounted) {
          final member = Member.fromMap(response);
          if (selectedRole == "Member") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MemberDashboard(member: member)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          }
        } else {
          _showErrorDialog("Account not found. Would you like to apply for membership?");
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Try Again")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (c) => const MembershipPage()));
            },
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F2EE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text("K-SHREE", 
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 2)),
              const Text("Kudumbashree Management System", 
                style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text("Login to your account", 
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 25),
                      
                      const Text(" Select Role", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: _inputDecoration("Choose your role", Icons.assignment_ind),
                        items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) => setState(() => selectedRole = val),
                        validator: (v) => v == null ? "Please select a role" : null,
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(" User ID / Aadhar", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: userIdController, 
                        decoration: _inputDecoration("Enter ID or Aadhar", Icons.person),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(" Password", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController, 
                        obscureText: true, 
                        decoration: _inputDecoration("Enter password", Icons.lock),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity, 
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : () { 
                            if (_formKey.currentState!.validate()) _attemptLogin(); 
                          },
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MembershipPage())),
                child: const Text("Don't have an account? Apply here", 
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}