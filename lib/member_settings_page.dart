import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart'; 

class MemberSettingsPage extends StatefulWidget {
  final String memberId;

  const MemberSettingsPage({Key? key, required this.memberId}) : super(key: key);

  @override
  State<MemberSettingsPage> createState() => _MemberSettingsPageState();
}

class _MemberSettingsPageState extends State<MemberSettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  bool _hideBalancesEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Account & Security"),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.phone_android,
                  title: "Update Phone Number",
                  subtitle: "Change your registered mobile number",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _UpdatePhoneDialog(memberId: widget.memberId),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  subtitle: "Update your login password",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _ChangePasswordDialog(memberId: widget.memberId),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  title: "Biometric Login",
                  subtitle: "Use fingerprint to open the app",
                  value: _biometricEnabled,
                  onChanged: (val) => setState(() => _biometricEnabled = val),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader("Financial Details"),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.account_balance,
                  title: "Linked Bank Account",
                  subtitle: "Manage your account for loan disbursements",
                  onTap: () => _showSnackBar("Bank Account management coming soon!"),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.visibility_off_outlined,
                  title: "Hide Dashboard Balances",
                  subtitle: "Hide your savings/loans on the home screen",
                  value: _hideBalancesEnabled,
                  onChanged: (val) => setState(() => _hideBalancesEnabled = val),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader("App Preferences"),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.language,
                  title: "Language",
                  subtitle: "English",
                  onTap: () => _showLanguageDialog(),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: "Push Notifications",
                  subtitle: "Alerts for meetings and thrift",
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: "Dark Mode",
                  subtitle: "Easier on the eyes",
                  value: _darkModeEnabled,
                  onChanged: (val) => setState(() => _darkModeEnabled = val),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader("Help & Legal"),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.help_outline,
                  title: "Help Center / FAQ",
                  onTap: () => _showHelpCenterDialog(),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.support_agent,
                  title: "Contact ADS / Secretary",
                  onTap: () => _showContactSupportDialog(),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.gavel,
                  title: "Kudumbashree Bylaws",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MemberBylawsPage()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Center(
              child: Text(
                "K-SHREE App v1.0.0\nMade in Kerala",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.teal, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.teal, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      activeColor: Colors.teal,
      value: value,
      onChanged: onChanged,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              trailing: const Icon(Icons.check_circle, color: Colors.teal),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text("മലയാളം (Malayalam)"),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar("Malayalam translation coming soon!");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpCenterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Help Center / FAQ", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ListTile(
                title: Text("How do I deposit thrift?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Contact your NHG secretary during the weekly meeting."),
              ),
              ListTile(
                title: Text("How can I apply for a loan?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Use the 'Apply for Loan' button on the dashboard."),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Support Contact", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("For financial data issues, reach out below:"),
            const SizedBox(height: 20),
            _buildContactRow(Icons.phone, "+91 98765 43210", "ADS Helpline"),
            const SizedBox(height: 12),
            _buildContactRow(Icons.email, "support@kshree.gov.in", "Official Email"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String detail, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(detail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

// =========================================================================
// Dialog Widgets defined below to avoid "Undefined" errors
// =========================================================================

class _UpdatePhoneDialog extends StatefulWidget {
  final String memberId;
  const _UpdatePhoneDialog({Key? key, required this.memberId}) : super(key: key);
  @override
  State<_UpdatePhoneDialog> createState() => _UpdatePhoneDialogState();
}

class _UpdatePhoneDialogState extends State<_UpdatePhoneDialog> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePhone() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('Registered_Members')
          .update({'phone_number': _phoneController.text})
          .eq('aadhar_number', widget.memberId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number updated!'), backgroundColor: Colors.green));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Phone"),
      content: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: "New Mobile Number"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _isLoading ? null : _updatePhone, child: const Text("Update")),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final String memberId;
  const _ChangePasswordDialog({Key? key, required this.memberId}) : super(key: key);
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.from('Registered_Members').select('password').eq('aadhar_number', widget.memberId).maybeSingle();
      if (res != null && res['password'] == _currentController.text) {
        await Supabase.instance.client.from('Registered_Members').update({'password': _newController.text}).eq('aadhar_number', widget.memberId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed!'), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _currentController, obscureText: true, decoration: const InputDecoration(labelText: "Current Password")),
          TextField(controller: _newController, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _isLoading ? null : _updatePassword, child: const Text("Save")),
      ],
    );
  }
}

class MemberBylawsPage extends StatelessWidget {
  const MemberBylawsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NHG Bylaws"), backgroundColor: Colors.teal),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text("1. Membership Rules", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          SizedBox(height: 10),
          Text("Membership is restricted to one woman per family residing in the NHG area."),
          Divider(height: 40),
          Text("2. Thrift Deposits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          SizedBox(height: 10),
          Text("Weekly thrift contributions are mandatory for all active members."),
        ],
      ),
    );
  }
}