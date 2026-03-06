import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:local_auth/local_auth.dart';
import 'login_page.dart'; 
import 'member_profile_page.dart'; // REQUIRED IMPORT

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
  String _currentLanguage = "English";
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ==========================================
  // SIMPLE TRANSLATION DICTIONARY
  // ==========================================
  final Map<String, String> _malayalamTranslations = {
    'Settings': 'ക്രമീകരണങ്ങൾ',
    'Account & Security': 'അക്കൗണ്ടും സുരക്ഷയും',
    'Update Phone Number': 'ഫോൺ നമ്പർ മാറ്റുക',
    'Change your registered mobile number': 'നിങ്ങളുടെ രജിസ്റ്റർ ചെയ്ത മൊബൈൽ നമ്പർ മാറ്റുക',
    'Change Password': 'പാസ്‌വേഡ് മാറ്റുക',
    'Update your login password': 'നിങ്ങളുടെ ലോഗിൻ പാസ്‌വേഡ് അപ്ഡേറ്റ് ചെയ്യുക',
    'Biometric Login': 'ബയോമെട്രിക് ലോഗിൻ',
    'Use fingerprint to open the app': 'ആപ്പ് തുറക്കാൻ വിരലടയാളം ഉപയോഗിക്കുക',
    'Financial Details': 'സാമ്പത്തിക വിവരങ്ങൾ',
    'Linked Bank Account': 'ലിങ്ക് ചെയ്ത ബാങ്ക് അക്കൗണ്ട്',
    'Manage your account for loan disbursements': 'ലോൺ നൽകുന്നതിനായി നിങ്ങളുടെ അക്കൗണ്ട് കൈകാര്യം ചെയ്യുക',
    'Hide Dashboard Balances': 'ഡാഷ്‌ബോർഡ് ബാലൻസുകൾ മറയ്ക്കുക',
    'Hide your savings/loans on the home screen': 'ഹോം സ്ക്രീനിൽ നിങ്ങളുടെ സമ്പാദ്യം/ലോണുകൾ മറയ്ക്കുക',
    'App Preferences': 'ആപ്പ് മുൻഗണനകൾ',
    'Language': 'ഭാഷ',
    'Push Notifications': 'പുഷ് അറിയിപ്പുകൾ',
    'Alerts for meetings and thrift': 'മീറ്റിംഗുകൾക്കും സമ്പാദ്യത്തിനുമുള്ള അലേർട്ടുകൾ',
    'Help & Legal': 'സഹായവും നിയമപരവും',
    'Help Center / FAQ': 'സഹായ കേന്ദ്രം / FAQ',
    'Contact ADS / Secretary': 'ADS / സെക്രട്ടറിയെ ബന്ധപ്പെടുക',
    'Kudumbashree Bylaws': 'കുടുംബശ്രീ നിയമാവലി',
    'Log Out': 'ലോഗ് ഔട്ട് ചെയ്യുക',
  };

  String _t(String englishText) {
    if (_currentLanguage == "Malayalam") {
      return _malayalamTranslations[englishText] ?? englishText;
    }
    return englishText;
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? "English";
      _biometricEnabled = prefs.getBool('biometric') ?? false;
      _hideBalancesEnabled = prefs.getBool('hideBalances') ?? false;
    });
  }

  Future<void> _changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _currentLanguage = lang);
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(_t('Settings'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(_t("Account & Security")),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.phone_android,
                  title: _t("Update Phone Number"),
                  subtitle: _t("Change your registered mobile number"),
                  onTap: () => showDialog(context: context, builder: (context) => _UpdatePhoneDialog(memberId: widget.memberId)),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: _t("Change Password"),
                  subtitle: _t("Update your login password"),
                  onTap: () => showDialog(context: context, builder: (context) => _ChangePasswordDialog(memberId: widget.memberId)),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  title: _t("Biometric Login"),
                  subtitle: _t("Use fingerprint to open the app"),
                  value: _biometricEnabled,
                  onChanged: (val) async {
                    if (val == true) {
                      final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
                      if (canAuthenticate) {
                        final bool didAuthenticate = await _localAuth.authenticate(
                          localizedReason: 'Verify your identity to enable biometric login',
                          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
                        );
                        if (didAuthenticate) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('biometric', true);
                          setState(() => _biometricEnabled = true);
                        }
                      } else {
                        _showSnackBar("Biometrics not supported on this device");
                      }
                    } else {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('biometric', false);
                      setState(() => _biometricEnabled = false);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader(_t("Financial Details")),
            _buildSettingsCard(
              children: [
                // UPDATED: Navigates to Profile Page instead of showing a Snackbar
                _buildListTile(
                  icon: Icons.account_balance,
                  title: _t("Linked Bank Account"),
                  subtitle: _t("Manage your account for loan disbursements"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberProfilePage(memberId: widget.memberId),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.visibility_off_outlined,
                  title: _t("Hide Dashboard Balances"),
                  subtitle: _t("Hide your savings/loans on the home screen"),
                  value: _hideBalancesEnabled,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hideBalances', val);
                    setState(() => _hideBalancesEnabled = val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader(_t("App Preferences")),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.language,
                  title: _t("Language"),
                  subtitle: _currentLanguage == "Malayalam" ? "മലയാളം" : "English",
                  onTap: () => _showLanguageDialog(),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: _t("Push Notifications"),
                  subtitle: _t("Alerts for meetings and thrift"),
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader(_t("Help & Legal")),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.help_outline,
                  title: _t("Help Center / FAQ"),
                  onTap: () => _showHelpCenterDialog(),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.support_agent,
                  title: _t("Contact ADS / Secretary"),
                  onTap: () => _showContactSupportDialog(),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.gavel,
                  title: _t("Kudumbashree Bylaws"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MemberBylawsPage()));
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
                label: Text(_t("Log Out"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await _secureStorage.deleteAll(); 
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('biometric', false);

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Center(
              child: Text("K-SHREE App v1.0.0\nMade in Kerala", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
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
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
              trailing: _currentLanguage == "English" ? const Icon(Icons.check_circle, color: Colors.teal) : null,
              onTap: () => _changeLanguage("English"),
            ),
            ListTile(
              title: const Text("മലയാളം (Malayalam)"),
              trailing: _currentLanguage == "Malayalam" ? const Icon(Icons.check_circle, color: Colors.teal) : null,
              onTap: () => _changeLanguage("Malayalam"),
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
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.teal, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("ADS Helpline", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("+91 98765 43210", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

// =========================================================================
// Dialog Widgets 
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
      await Supabase.instance.client.from('Registered_Members').update({'phone_number': _phoneController.text}).eq('aadhar_number', widget.memberId);
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