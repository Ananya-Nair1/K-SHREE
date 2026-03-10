import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ADSComplaintsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSComplaintsPage({super.key, required this.userData});

  @override
  State<ADSComplaintsPage> createState() => _ADSComplaintsPageState();
}

class _ADSComplaintsPageState extends State<ADSComplaintsPage> {
  final Color primaryColor = const Color(0xFF2B6CB0); // Matches ADS Dashboard
  final supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _isFetching = true;

  List<Map<String, dynamic>> complaints = [];

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  // --- 1. FETCH COMPLAINTS ---
  Future<void> _fetchComplaints() async {
    try {
      // Get the ward number to filter complaints for this specific ADS
      final wardStr = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();
      final wardInt = int.tryParse(wardStr) ?? 0;

      final response = await supabase
          .from('complaints')
          // Assuming you have a foreign key on member_id to get the name. 
          // If you get an error here, change this to just select('*')
          .select('*, Registered_Members(full_name)') 
          .eq('ward', wardInt)
          .inFilter('status', ['Forwarded to ADS', 'Resolved by ADS', 'Forwarded to CDS']) 
          .order('created_at', ascending: false);

      setState(() {
        complaints = (response as List).map((row) {
          final memberInfo = row['Registered_Members'] ?? {};
          final dateObj = row['created_at'] != null 
              ? DateTime.tryParse(row['created_at']) ?? DateTime.now() 
              : DateTime.now();

          return {
            'db_id': row['complaint_id'], 
            'id': row['complaint_id'].toString().substring(0, 8).toUpperCase(), 
            'memberName': memberInfo['full_name'] ?? row['member_id'] ?? 'Unknown Member',
            'unitNumber': row['unit_number'] ?? 'Unknown Unit',
            'subject': row['subject'] ?? 'No Subject',
            'description': row['description'] ?? 'No Description',
            'status': row['status'] ?? 'Pending',
            'dateApplied': DateFormat('dd-MMM-yyyy').format(dateObj),
          };
        }).toList();
        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading complaints: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 2. UPDATE COMPLAINT STATUS ---
  Future<void> _updateComplaintStatus(int index, String newStatus) async {
    setState(() => _isLoading = true);
    final complaint = complaints[index];

    try {
      await supabase
          .from('complaints')
          .update({'status': newStatus})
          .eq('complaint_id', complaint['db_id']);

      setState(() {
        complaints[index]['status'] = newStatus;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'Resolved by ADS' 
                ? 'Complaint marked as Resolved!' 
                : 'Complaint Forwarded to CDS Chairperson.'),
            backgroundColor: newStatus == 'Resolved by ADS' ? Colors.green : Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating complaint: $e'), backgroundColor: const Color.fromARGB(255, 147, 106, 201)),
        );
      }
    }
  }

  // --- 3. DYNAMIC ACTION BUTTONS ---
  Widget _buildActionArea(Map<String, dynamic> complaint, int index) {
    final String status = complaint['status'];

    if (status == 'Forwarded to ADS') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Resolve'),
              onPressed: () => _updateComplaintStatus(index, 'Resolved by ADS'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Forward to CDS'),
              onPressed: () => _updateComplaintStatus(index, 'Forwarded to CDS'),
            ),
          ),
        ],
      );
    } else {
      // Read-only state for Resolved / Forwarded
      final isResolved = status == 'Resolved by ADS';
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isResolved ? Colors.green[50] : Colors.blue[50],
            foregroundColor: isResolved ? Colors.green[700] : Colors.blue[700],
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(isResolved ? Icons.check_circle : Icons.escalator_warning),
          label: Text(isResolved ? 'Resolved by you' : 'Forwarded to CDS'),
          onPressed: null, // Disabled
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('Complaints Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor, // <-- Changed to blue
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetching 
        ? Center(child: CircularProgressIndicator(color: primaryColor)) // <-- Changed to blue
        : complaints.isEmpty
          ? const Center(child: Text("No complaints to review.", style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];

                    Color statusColor = Colors.orange;
                    if (complaint['status'] == 'Resolved by ADS') statusColor = Colors.green;
                    if (complaint['status'] == 'Forwarded to CDS') statusColor = Colors.blue;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: ${complaint['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    complaint['status'],
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.1), // <-- Changed to blue
                                  child: Icon(Icons.report_problem, color: primaryColor), // <-- Changed to blue
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(complaint['memberName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text('Unit No: ${complaint['unitNumber']}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Text(complaint['dateApplied'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(complaint['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                            const SizedBox(height: 8),
                            Text(complaint['description'], style: const TextStyle(color: Colors.black87, height: 1.4)),
                            const SizedBox(height: 20),
                            
                            _buildActionArea(complaint, index),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(child: CircularProgressIndicator(color: primaryColor)), // <-- Changed to blue
                  )
              ],
            ),
    );
  }
}