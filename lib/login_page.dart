import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member.dart'; 
import 'member_dashboard.dart';
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

  final List<String> roles = ["Member", "ADS Member", "ADS Chairperson", "CDS Member", "CDS Chairperson"];

  Future<void> _attemptLogin() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('members')
          .select()
          .eq('user_id', userIdController.text.trim())
          .eq('password', passwordController.text.trim())
          .maybeSingle();

      if (response != null) {
        final member = Member.fromMap(response);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MemberDashboard(member: member)),
          );
        }
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("User Not Found"),
        content: const Text("Account not found. Would you like to register?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
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
              const Text("K-SHREE", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: "Select Role", border: OutlineInputBorder()),
                      items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => selectedRole = val),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(controller: userIdController, decoration: const InputDecoration(labelText: "User ID", border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: _isLoading ? null : () { if (_formKey.currentState!.validate()) _attemptLogin(); },
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MembershipPage())),
                      child: const Text("Apply for Membership", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}