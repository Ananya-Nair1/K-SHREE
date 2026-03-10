
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Added this import

class WardMembersPage extends StatefulWidget {
  final Map<String, dynamic> adsData;

  const WardMembersPage({super.key, required this.adsData});

  @override
  State<WardMembersPage> createState() => _WardMembersPageState();
}

class _WardMembersPageState extends State<WardMembersPage> {
  late final Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchWardMembers();
  }

  // Function to trigger the phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch phone dialer")),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWardMembers() async {
    try {
      final wardValue = widget.adsData['ward'] ?? widget.adsData['ward_number'];
      final int? wardId = int.tryParse(wardValue.toString());
      if (wardId == null) return [];

      final response = await Supabase.instance.client
          .from('Registered_Members') 
          .select('*')
          .eq('ward', wardId) 
          .order('unit_number', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  void _showMemberInfo(Map<String, dynamic> member) {
    final String phone = member['phone_number']?.toString() ?? 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Member Details", 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 15),
                    
                    _buildDetailRow(Icons.person, "Full Name", member['full_name'] ?? 'N/A'),
                    
                    // Updated Phone Row with Call Action
                    _buildDetailRow(
                      Icons.phone, 
                      "Phone Number", 
                      phone,
                      trailing: phone != 'N/A' ? IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _makePhoneCall(phone),
                      ) : null,
                    ),
                    
                    _buildDetailRow(Icons.badge, "Aadhar Number", member['aadhar_number'] ?? 'N/A'),
                    _buildDetailRow(Icons.home_work, "Unit Number", "Unit ${member['unit_number']}"),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF2B6CB0)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayWard = (widget.adsData['ward'] ?? widget.adsData['ward_number'] ?? 'N/A').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text('Ward $displayWard Members', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2B6CB0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return const Center(child: Text("Error fetching members."));

          final members = snapshot.data ?? [];
          if (members.isEmpty) return const Center(child: Text("No members found."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final String unit = member['unit_number']?.toString() ?? 'N/A';
              
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEBF8FF),
                    child: Text(unit, style: const TextStyle(color: Color(0xFF2B6CB0), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(member['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${member['designation'] ?? 'Member'} • Unit $unit"),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: Color(0xFF2B6CB0)),
                    onPressed: () => _showMemberInfo(member),
                  ),
                  onTap: () => _showMemberInfo(member),
                ),
              );
            },
          );
        },
      ),
    );
  }
}