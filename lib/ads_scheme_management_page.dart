import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ads_scheme_request_page.dart';
import 'ads_scheme_ward_stats_page.dart';

class ADSSchemesManagementPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ADSSchemesManagementPage({super.key, required this.userData});

  @override
  State<ADSSchemesManagementPage> createState() => _ADSSchemesManagementPageState();
}

class _ADSSchemesManagementPageState extends State<ADSSchemesManagementPage> {
  final supabase = Supabase.instance.client;
  final Color adsBlue = const Color(0xFF2B6CB0);

  Future<void> _submitSelfApplication(Map<String, dynamic> scheme) async {
    try {
      await supabase.from('scheme_applications').insert({
        'scheme_id': scheme['id'],
        'member_id': widget.userData['aadhar_number'],
        'member_name': widget.userData['full_name'],
        'status': 'Pending at CDS', // Direct to CDS for ADS users
        'applied_date': DateTime.now().toIso8601String(),
        'remarks': 'Self-applied by ADS Chairperson',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Submitted!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _showSchemeActions(BuildContext context, Map<String, dynamic> scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Key for preventing overflow
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scheme['title'] ?? 'Scheme', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.assignment_ind_rounded,
                color: Colors.teal,
                title: "Review Ward Applications",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ADSSchemeRequestsPage(scheme: scheme, userData: widget.userData)));
                },
              ),
              _buildActionTile(
                icon: Icons.person_add_rounded,
                color: Colors.deepPurple,
                title: "Apply for myself",
                onTap: () {
                  Navigator.pop(context);
                  _submitSelfApplication(scheme);
                },
              ),
              _buildActionTile(
  icon: Icons.analytics_outlined,
  color: Colors.orange,
  title: "Ward Statistics",
  onTap: () {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ADSSchemeWardStatsPage(
        scheme: scheme, 
        userData: widget.userData
      )
    ));
  },
),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schemes Management"), backgroundColor: adsBlue, foregroundColor: Colors.white),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('government_schemes').stream(primaryKey: ['id']).eq('is_active', true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final schemes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            itemBuilder: (context, index) => Card(
              child: ListTile(
                title: Text(schemes[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(schemes[index]['category'] ?? 'General'),
                trailing: const Icon(Icons.more_vert),
                onTap: () => _showSchemeActions(context, schemes[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}