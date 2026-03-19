import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CDSLoanApprovalPage extends StatefulWidget {
  final String panchayat;
  const CDSLoanApprovalPage({super.key, required this.panchayat});

  @override
  State<CDSLoanApprovalPage> createState() => _CDSLoanApprovalPageState();
}

class _CDSLoanApprovalPageState extends State<CDSLoanApprovalPage> {
  final supabase = Supabase.instance.client;

  // UPDATED: Now accepts the full loan object and an optional reason
  Future<void> _finalizeLoan(Map<String, dynamic> loan, String status, {String? reason}) async {
    try {
      final updateData = {'status': status};
      
      // If a reason was provided, save it to a 'remarks' column
      if (reason != null && reason.isNotEmpty) {
        updateData['remarks'] = reason; 
      }

      await supabase.from('loans').update(updateData).eq('id', loan['id']);

      // NEW: Automatically trigger a notification if rejected
      if (status == 'REJECTED' && reason != null) {
        await supabase.from('unit_notifications').insert({
          'title': 'Loan Application Update',
          'message': 'Your loan application (ID: ${loan['id']}) was not approved. Reason: $reason',
          'panchayat': loan['panchayat'],
          'ward': loan['ward'],
          'unit_number': loan['unit_number'],
          'target_audience': loan['member_id'], // Or 'Specific Member' depending on your app's privacy flow
          'is_urgent': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loan $status Successfully"), backgroundColor: Colors.teal),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      debugPrint("Approval Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // NEW: Dialog box for typed rejection reasons
  Future<void> _showRejectDialog(Map<String, dynamic> loan) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Loan", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide a reason for rejecting this loan application. The member will be notified."),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Reason for Rejection",
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _finalizeLoan(loan, 'REJECTED', reason: reasonController.text);
            },
            child: const Text("Confirm Rejection", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Final Loan Approvals", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('loans').select().eq('panchayat', widget.panchayat).eq('status', 'Pending at CDS').order('applied_date', ascending: false), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final loans = snapshot.data ?? [];
          if (loans.isEmpty) return const Center(child: Text("No loan applications pending at CDS level.", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("₹${loan['principal_amount'] ?? 0}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(5)),
                            child: const Text("AWAITING CDS", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Member ID: ${loan['member_id'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Ward: ${loan['ward']} | Unit: ${loan['unit_number']}", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      Text("Type: ${loan['loan_type'] ?? 'General Loan'}", style: const TextStyle(color: Colors.black87)),
                      const Divider(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              // UPDATED: Now calls the Dialog instead of rejecting immediately
                              onPressed: () => _showRejectDialog(loan), 
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const FittedBox(fit: BoxFit.scaleDown, child: Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              // UPDATED: Passes the full loan object
                              onPressed: () => _finalizeLoan(loan, 'DISBURSED'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const FittedBox(fit: BoxFit.scaleDown, child: Text("APPROVE & DISBURSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}