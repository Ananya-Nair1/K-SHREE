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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scheme['title'] ?? 'Unknown Scheme',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade50, // Fixed: Capitalized Colors
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scheme['category'] ?? 'General',
                style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const Divider(height: 32, color: Colors.black12),
            _buildOptionTile(
              icon: Icons.info_outline_rounded,
              color: Colors.teal, // Fixed: Capitalized Colors
              title: "View Scheme Details & Apply",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchemeDetailsPage(scheme: scheme, userData: userData),
                  ),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.people_alt_outlined,
              color: Colors.green,
              title: "View Member Requests",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchemeRequestsPage(
                      schemeId: scheme['id'],
                      schemeTitle: scheme['title'],
                    ),
                  ),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.post_add_rounded,
              color: Colors.orange,
              title: "Add Scheme Report",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Add Report feature coming soon."),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Schemes Management", style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final schemes = snapshot.data ?? [];
          if (schemes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No active schemes found.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal.shade50, // Fixed: Capitalized Colors
                    child: Icon(Icons.account_balance_rounded, color: Colors.teal.shade700),
                  ),
                  title: Text(scheme['title'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(scheme['category'] ?? 'General', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  trailing: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
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
class SchemeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> userData;
  const SchemeDetailsPage({super.key, required this.scheme, required this.userData});

  @override
  State<SchemeDetailsPage> createState() => _SchemeDetailsPageState();
}

class _SchemeDetailsPageState extends State<SchemeDetailsPage> {
  bool _isApplying = false;

  void _showApplyDialog() {
    final TextEditingController remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Apply for Scheme", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You are applying for ${widget.scheme['title']}."),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Add remarks (optional)",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              _submitApplication(remarksController.text.trim());
            },
            child: const Text("Confirm Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication(String remarks) async {
    setState(() => _isApplying = true);
    try {
      final String memberId = widget.userData['aadhar_number'] ?? 'UNKNOWN';
      final String memberName = widget.userData['full_name'] ?? 'Unknown Member';
      await Supabase.instance.client.from('scheme_applications').insert({
        'scheme_id': widget.scheme['id'],
        'member_id': memberId,
        'member_name': memberName,
        'status': 'Pending at ADS',
        'applied_date': DateTime.now().toIso8601String(),
        'remarks': remarks.isNotEmpty ? remarks : 'Applied via Secretary Dashboard',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("Application Submitted!")]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Scheme Details", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scheme['title'] ?? 'N/A', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  _buildDetailRow("Category", scheme['category'] ?? 'N/A'),
                  const Divider(height: 24),
                  _buildDetailRow("Subsidy Amount", "₹${scheme['subsidy_amount']?.toString() ?? '0.00'}", isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(scheme['description'] ?? 'No description provided.', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            const Text("Eligibility Criteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(scheme['eligibility_criteria'] ?? 'N/A', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700)),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _isApplying ? null : _showApplyDialog,
              child: _isApplying ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text("Apply for this Scheme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isHighlight ? Colors.teal.shade700 : Colors.black87)),
      ],
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
  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await Supabase.instance.client.from('scheme_applications').update({'status': newStatus}).eq('id', applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application marked as $newStatus"),
            backgroundColor: newStatus.contains('Rejected') ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Member Requests", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Scheme Name", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.schemeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('scheme_applications').stream(primaryKey: ['id']).eq('scheme_id', widget.schemeId).order('applied_date', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));

                final applications = snapshot.data ?? [];
                if (applications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("No applications found.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    final String status = app['status']?.toString().trim() ?? 'Pending';
                    final String lowercaseStatus = status.toLowerCase();
                    final bool isPending = lowercaseStatus == 'pending' || lowercaseStatus == 'pending at nhg';

                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(app['member_name'] ?? 'Unknown Member', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                _buildStatusBadge(status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.badge_rounded, "Aadhar: ${app['member_id']}"),
                            const SizedBox(height: 6),
                            _buildInfoRow(Icons.calendar_today_rounded, "Applied: ${app['applied_date'].toString().split('T')[0]}"),
                            if (app['remarks'] != null && app['remarks'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.format_quote_rounded, size: 16, color: Colors.grey.shade400),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text("${app['remarks']}", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey.shade700))),
                                  ],
                                ),
                              ),
                            ],
                            if (isPending) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      onPressed: () => _updateApplicationStatus(app['id'], 'Rejected'),
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      onPressed: () => _updateApplicationStatus(app['id'], 'Pending at ADS'),
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                      label: const Text("Forward", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text("Action taken / Processed", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13))),
                              ),
                            ],
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey.shade500), const SizedBox(width: 6), Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))]);
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bgColor = Colors.orange.shade50;
    Color textColor = Colors.orange.shade800;
    if (s.contains('approved')) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
    } else if (s.contains('rejected')) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
    } else if (s.contains('pending at ads')) {
      bgColor = Colors.teal.shade50; // Fixed: Capitalized Colors
      textColor = Colors.teal.shade800; // Fixed: Capitalized Colors
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withOpacity(0.3))),
      child: Text(status, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}