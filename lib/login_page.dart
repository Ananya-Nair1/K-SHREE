import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member.dart'; 
import 'member_dashboard.dart';
import 'admin_dashboard.dart'; 
import 'secretary_dashboard.dart'; // Friend's new dashboard
import 'inter_membership_page.dart';

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

  // Merged roles list including the new "NHG_SECRETARY"
  final List<String> roles = [
    "Member", 
    "NHG_SECRETARY", 
    "ADS Member", 
    "ADS Chairperson", 
    "CDS Member", 
    "CDS Chairperson"
  ];

  /// Handles login routing based on the selected role
  Future<void> _attemptLogin() async {
    setState(() => _isLoading = true);
    try {
      if (selectedRole == 'NHG_SECRETARY') {
        // Friend's Logic: Query for Secretary
        final response = await Supabase.instance.client
            .from('Registered_Members')
            .select()
            .eq('aadhar_number', userIdController.text.trim()) // Secretary uses Aadhar
            .eq('password', passwordController.text.trim())
            .eq('designation', 'NHG_SECRETARY')
            .maybeSingle();

        if (response != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SecretaryDashboard(userData: response)),
          );
        } else {
          _showErrorDialog("Invalid Secretary Credentials. Please check your Aadhar and password.");
        }
      } else {
        // Original Logic: Query for Members & Admins
        final response = await Supabase.instance.client
            .from('members')
            .select()
            .eq('user_id', userIdController.text.trim())
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
            // Redirects to Admin Panel for ADS/CDS roles
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
      backgroundColor: const Color(0xFFE6F2EE), // Light background theme
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text("K-SHREE", 
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 2)),
              // Friend's added subtitle
              const Text("Kudumbashree Management System", 
                style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 30),
              
              /// White Box Container for Login Fields
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
                        keyboardType: TextInputType.text, // Kept text to support standard User IDs
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

  /// Helper for consistent input styling
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