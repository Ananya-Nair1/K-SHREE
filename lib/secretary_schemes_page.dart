import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. MAIN SCHEMES MANAGEMENT PAGE
// ==========================================
class SecretarySchemesPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SecretarySchemesPage({super.key, required this.userData});

  void _showSchemeOptions(BuildContext context, Map<String, dynamic> scheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scheme['title'] ?? 'Unknown Scheme',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Category: ${scheme['category'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text("View Scheme Details"),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchemeDetailsPage(scheme: scheme),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.green),
              title: const Text("View Member Requests"),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchemeRequestsPage(
                      schemeId: scheme['id'], 
                      schemeTitle: scheme['title']
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.orange),
              title: const Text("Add Scheme Report"),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Add Report feature coming soon."))
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Schemes Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Fetching only active schemes from the government_schemes table
        stream: Supabase.instance.client
            .from('government_schemes')
            .stream(primaryKey: ['id'])
            .eq('is_active', true)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          final schemes = snapshot.data ?? [];
          
          if (schemes.isEmpty) {
            return const Center(child: Text("No active schemes found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.account_balance, color: Colors.blue),
                  ),
                  title: Text(scheme['title'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(scheme['category'] ?? 'General'),
                  trailing: const Icon(Icons.more_vert, color: Colors.grey),
                  onTap: () => _showSchemeOptions(context, scheme),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. SCHEME DETAILS PAGE
// ==========================================
class SchemeDetailsPage extends StatelessWidget {
  final Map<String, dynamic> scheme;
  const SchemeDetailsPage({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scheme Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scheme['title'] ?? 'N/A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 20),
            
            _buildDetailRow("Category", scheme['category'] ?? 'N/A'),
            const Divider(),
            _buildDetailRow("Subsidy Amount", "₹${scheme['subsidy_amount']?.toString() ?? '0.00'}"),
            const Divider(),
            
            const SizedBox(height: 10),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 5),
            Text(scheme['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 15, height: 1.4)),
            
            const SizedBox(height: 20),
            const Text("Eligibility Criteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 5),
            Text(scheme['eligibility_criteria'] ?? 'N/A', style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. SCHEME MEMBER REQUESTS PAGE
// ==========================================
class SchemeRequestsPage extends StatefulWidget {
  final String schemeId;
  final String schemeTitle;

  const SchemeRequestsPage({super.key, required this.schemeId, required this.schemeTitle});

  @override
  State<SchemeRequestsPage> createState() => _SchemeRequestsPageState();
}

class _SchemeRequestsPageState extends State<SchemeRequestsPage> {
  
  // Method to handle Forward / Reject actions
  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('scheme_applications')
          .update({'status': newStatus})
          .eq('id', applicationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application updated to: $newStatus"),
            backgroundColor: newStatus == 'Rejected' ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Member Requests", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Scheme: ${widget.schemeTitle}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Fetching applications strictly for THIS scheme
              stream: Supabase.instance.client
                  .from('scheme_applications')
                  .stream(primaryKey: ['id'])
                  .eq('scheme_id', widget.schemeId)
                  .order('applied_date', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final applications = snapshot.data ?? [];

                if (applications.isEmpty) {
                  return const Center(child: Text("No applications found for this scheme."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    final String status = app['status'] ?? 'Pending';
                    final bool isPending = status.toLowerCase() == 'pending';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    app['member_name'] ?? 'Unknown Member',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                _buildStatusBadge(status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Aadhar ID: ${app['member_id']}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            Text("Applied On: ${app['applied_date'].toString().split('T')[0]}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            
                            if (app['remarks'] != null && app['remarks'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text("Remarks: ${app['remarks']}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                            ],
                            
                            // Show action buttons ONLY if the application is currently "Pending"
                            if (isPending) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      onPressed: () => _updateApplicationStatus(app['id'], 'Rejected'),
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                                      onPressed: () => _updateApplicationStatus(app['id'], 'Pending at ADS'),
                                      child: const Text("Forward to ADS", style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to color-code statuses
  Widget _buildStatusBadge(String status) {
    Color bgColor = Colors.grey[300]!;
    Color textColor = Colors.black87;

    if (status.toLowerCase() == 'pending') {
      bgColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
    } else if (status.toLowerCase() == 'pending at ads') {
      bgColor = Colors.blue[100]!;
      textColor = Colors.blue[800]!;
    } else if (status.toLowerCase() == 'approved') {
      bgColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
    } else if (status.toLowerCase() == 'rejected') {
      bgColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}