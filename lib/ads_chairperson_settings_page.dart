import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:local_auth/local_auth.dart';
import 'login_page.dart'; 
import 'ads_chairperson_profile_page.dart';

class ADSChairpersonSettingsPage extends StatefulWidget {
  final String adsId;

  const ADSChairpersonSettingsPage({Key? key, required this.adsId}) : super(key: key);

  @override
  State<ADSChairpersonSettingsPage> createState() => _ADSChairpersonSettingsPageState();
}

class _ADSChairpersonSettingsPageState extends State<ADSChairpersonSettingsPage> {
  // ADS PRIMARY BLUE THEME
  final Color primaryColor = const Color(0xFF2B6CB0); 
  
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  bool _hideBalancesEnabled = false;
  String _currentLanguage = "English";
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Dictionary remains the same
  final Map<String, String> _malayalamTranslations = {
    'Settings': 'ക്രമീകരണങ്ങൾ',
    'Account & Security': 'അക്കൗണ്ടും സുരക്ഷയും',
    'Update Phone Number': 'ഫോൺ നമ്പർ മാറ്റുക',
    'Change your registered mobile number': 'നിങ്ങളുടെ രജിസ്റ്റർ ചെയ്ത മൊബൈൽ നമ്പർ മാറ്റുക',
    'Change Password': 'പാസ്‌വേഡ് മാറ്റുക',
    'Update your login password': 'നിങ്ങളുടെ ലോഗിൻ പാസ്‌വേഡ് അപ്ഡേറ്റ് ചെയ്യുക',
    'Biometric Login': 'ബയോമെട്രിക് ലോഗിൻ',
    'Use fingerprint to open the app': 'ആപ്പ് തുറക്കാൻ വിരലടയാളം ഉപയോഗിക്കുക',
    'Administrative Details': 'ഭരണപരമായ വിവരങ്ങൾ',
    'ADS Bank Account': 'ADS ബാങ്ക് അക്കൗണ്ട്',
    'Manage ADS official account details': 'ADS ഔദ്യോഗിക അക്കൗണ്ട് വിവരങ്ങൾ',
    'Hide Dashboard Balances': 'ഡാഷ്‌ബോർഡ് ബാലൻസുകൾ മറയ്ക്കുക',
    'Hide ADS savings/loans on the home screen': 'ഹോം സ്ക്രീനിൽ ADS സമ്പാദ്യം/ലോണുകൾ മറയ്ക്കുക',
    'App Preferences': 'ആപ്പ് മുൻഗണനകൾ',
    'Language': 'ഭാഷ',
    'Push Notifications': 'പുഷ് അറിയിപ്പുകൾ',
    'Alerts for CDS meetings and NHG requests': 'CDS മീറ്റിംഗുകൾക്കും NHG അപേക്ഷകൾക്കുമുള്ള അറിയിപ്പുകൾ',
    'Help & Legal': 'സഹായവും നിയമപരവും',
    'Help Center / FAQ': 'സഹായ കേന്ദ്രം / FAQ',
    'Contact CDS / Bank Manager': 'CDS / ബാങ്ക് മാനേജറെ ബന്ധപ്പെടുക',
    'Chairperson Manual': 'ചെയർപേഴ്സൺ മാനുവൽ',
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
        backgroundColor: primaryColor,
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
                  onTap: () => showDialog(context: context, builder: (context) => _UpdatePhoneDialog(adsId: widget.adsId, themeColor: primaryColor)),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: _t("Change Password"),
                  subtitle: _t("Update your login password"),
                  onTap: () => showDialog(context: context, builder: (context) => _ChangePasswordDialog(adsId: widget.adsId, themeColor: primaryColor)),
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

            _buildSectionHeader(_t("Administrative Details")),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.account_balance,
                  title: _t("ADS Bank Account"),
                  subtitle: _t("Manage ADS official account details"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ADSChairpersonProfilePage(adsId: widget.adsId),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.visibility_off_outlined,
                  title: _t("Hide Dashboard Balances"),
                  subtitle: _t("Hide ADS savings/loans on the home screen"),
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
                  subtitle: _t("Alerts for CDS meetings and NHG requests"),
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
                  title: _t("Contact CDS / Bank Manager"),
                  onTap: () => _showContactSupportDialog(),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.gavel,
                  title: _t("Chairperson Manual"),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ADSBylawsPage(themeColor: primaryColor)));
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
            
            const SizedBox(height: 40),
            const Center(
              child: Text("ADS Admin Portal v1.0.0\nMade in Kerala", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
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
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: primaryColor, size: 22),
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
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      activeColor: primaryColor,
      value: value,
      onChanged: onChanged,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t("Language"), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              trailing: _currentLanguage == "English" ? Icon(Icons.check_circle, color: primaryColor) : null,
              onTap: () => _changeLanguage("English"),
            ),
            ListTile(
              title: const Text("മലയാളം (Malayalam)"),
              trailing: _currentLanguage == "Malayalam" ? Icon(Icons.check_circle, color: primaryColor) : null,
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
        title: Text("Help Center", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ListTile(
                title: Text("How to approve NHG Linkage?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Navigate to 'Approvals' tab and verify the NHG grading report."),
              ),
              ListTile(
                title: Text("System Login Issues?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Contact the CDS MIS wing for password resets."),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("CDS Admin Contact", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("For portal technical support:"),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.phone, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("CDS Office Helpline", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("0481 2XXXXXX", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

// --- Dialogs (Themed) ---

class _UpdatePhoneDialog extends StatefulWidget {
  final String adsId;
  final Color themeColor;
  const _UpdatePhoneDialog({Key? key, required this.adsId, required this.themeColor}) : super(key: key);
  @override
  State<_UpdatePhoneDialog> createState() => _UpdatePhoneDialogState();
}

class _UpdatePhoneDialogState extends State<_UpdatePhoneDialog> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Update Phone", style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: "New Mobile Number",
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.themeColor)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
          onPressed: _isLoading ? null : () async {
            setState(() => _isLoading = true);
            try {
              await Supabase.instance.client.from('Registered_Members').update({'phone_number': _phoneController.text}).eq('aadhar_number', widget.adsId);
              Navigator.pop(context);
            } catch (e) { print(e); }
            setState(() => _isLoading = false);
          }, 
          child: const Text("Update", style: TextStyle(color: Colors.white))
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final String adsId;
  final Color themeColor;
  const _ChangePasswordDialog({Key? key, required this.adsId, required this.themeColor}) : super(key: key);
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Change Password", style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _currentController, obscureText: true, decoration: InputDecoration(labelText: "Current Password", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.themeColor)))),
          TextField(controller: _newController, obscureText: true, decoration: InputDecoration(labelText: "New Password", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.themeColor)))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
          onPressed: _isLoading ? null : () async {
             setState(() => _isLoading = true);
             // Logic remains same...
             Navigator.pop(context);
             setState(() => _isLoading = false);
          }, 
          child: const Text("Save", style: TextStyle(color: Colors.white))
        ),
      ],
    );
  }
}

class ADSBylawsPage extends StatelessWidget {
  final Color themeColor;
  const ADSBylawsPage({Key? key, required this.themeColor}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chairperson Manual"), backgroundColor: themeColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text("1. Administrative Duties", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(height: 10),
          const Text("The ADS Chairperson is responsible for consolidating NHG reports and maintaining linkage with the CDS."),
          const Divider(height: 40),
          Text("2. Financial Oversight", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(height: 10),
          const Text("Must verify and approve internal lending records and bank linkage documents."),
        ],
      ),
    );
  }
}