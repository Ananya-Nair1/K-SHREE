import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

// Your Imports
import 'member.dart'; 
import 'member_dashboard.dart';
import 'secretary_dashboard.dart'; 
import 'inter_membership_page.dart';
import 'ads_chairperson_dashboard.dart';
import 'cds_dashboard.dart';

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

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // FIXED: Role names now exactly match your database 'designation' strings
  final List<String> roles = [
    "Member", 
    "NHG_SECRETARY", 
    "ADS Member", 
    "ADS_Chairperson", 
    "CDS Member", 
    "CDS_Chairperson" 
  ];

  @override
  void initState() {
    super.initState();
    _attemptBiometricAutoLogin();
  }

  Future<void> _attemptBiometricAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isBiometricEnabled = prefs.getBool('biometric') ?? false;

    if (isBiometricEnabled) {
      try {
        final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
        if (canAuthenticate) {
          final bool didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Scan your fingerprint to open K-SHREE',
            options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
          );

          if (didAuthenticate) {
            final savedAadhar = await _secureStorage.read(key: 'aadhar');
            final savedPassword = await _secureStorage.read(key: 'password');
            final savedRole = await _secureStorage.read(key: 'role');

            if (savedAadhar != null && savedPassword != null && savedRole != null) {
              setState(() {
                userIdController.text = savedAadhar;
                passwordController.text = savedPassword;
                selectedRole = savedRole;
              });
              await _attemptLogin(isAutoLogin: true);
            }
          }
        }
      } catch (e) {
        debugPrint("Biometric error: $e");
      }
    }
  }

  Future<void> _attemptLogin({bool isAutoLogin = false}) async {
    if (!isAutoLogin && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final aadhar = userIdController.text.trim();
      final password = passwordController.text.trim();
      
      // 1. Logic for Administrative Roles (Secretary, ADS, CDS)
      if (selectedRole == 'NHG_SECRETARY' || selectedRole == 'ADS_Chairperson' || selectedRole == 'CDS_Chairperson') {
        final response = await Supabase.instance.client
            .from('Registered_Members')
            .select()
            .eq('aadhar_number', aadhar)
            .eq('password', password)
            .eq('designation', selectedRole!) // FIXED: Using 'designation' column
            .maybeSingle();

        if (response != null && mounted) {
          await _saveCredentialsSecurely(aadhar, password, selectedRole!);
          
          if (selectedRole == 'NHG_SECRETARY') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SecretaryDashboard(userData: response)));
          } else if (selectedRole == 'ADS_Chairperson') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ADSChairpersonDashboard(userData: response)));
          } else if (selectedRole == 'CDS_Chairperson') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CDSDashboard(userData: response)));
          }
        } else {
          _showErrorDialog("Login Failed. Ensure you are registered as $selectedRole and your credentials are correct.");
        }
      } 
      // 2. Logic for General Members
      else {
        final response = await Supabase.instance.client
            .from('Registered_Members')
            .select()
            .eq('aadhar_number', aadhar)
            .eq('password', password)
            .maybeSingle();

        if (response != null && mounted) {
          final String userDesignation = response['designation'] ?? 'Member';
          
          if (selectedRole == "Member") {
            final member = Member.fromMap(response);
            await _saveCredentialsSecurely(aadhar, password, selectedRole!);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MemberDashboard(member: member)));
          } else {
             _showErrorDialog("Role mismatch. Your account is registered as $userDesignation, not $selectedRole.");
          }
        } else {
          _showErrorDialog("Account not found. Please check your Aadhar and password.");
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCredentialsSecurely(String aadhar, String password, String role) async {
    await _secureStorage.write(key: 'aadhar', value: aadhar);
    await _secureStorage.write(key: 'password', value: password);
    await _secureStorage.write(key: 'role', value: role);
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
              const Text("K-SHREE", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 2)),
              const Text("Kudumbashree Management System", style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 30),
              
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
                      const Center(child: Text("Login to your account", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500))),
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
                        keyboardType: TextInputType.number,
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _isLoading ? null : () => _attemptLogin(),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MembershipPage())),
                child: const Text("Don't have an account? Apply here", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}