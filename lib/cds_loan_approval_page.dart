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

  Future<void> _finalizeLoan(String loanId, String status) async {
    try {
      await supabase.from('loans').update({
        'status': status,
        'cds_acknowledged_at': DateTime.now().toIso8601String(),
        'final_approver': 'CDS Chairperson'
      }).eq('id', loanId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loan $status Successfully"), backgroundColor: Colors.teal),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      debugPrint("Approval Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Final Loan Approvals", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('loans')
            .select()
            .eq('panchayat', widget.panchayat)
            .eq('status', 'ADS_APPROVED') // Only show loans already cleared by ADS
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final loans = snapshot.data ?? [];
          if (loans.isEmpty) {
            return const Center(
              child: Text("No pending loan approvals for this Panchayat.", 
                style: TextStyle(color: Colors.grey))
            );
          }

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
                          Text("₹${loan['amount']}", 
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(5)),
                            child: const Text("AWAITING CDS", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(loan['member_name'] ?? "Unknown Member", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Ward: ${loan['ward']} | Unit: ${loan['unit_name']}", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      Text("Purpose: ${loan['purpose'] ?? 'General Loan'}", style: const TextStyle(color: Colors.black87)),
                      const Divider(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _finalizeLoan(loan['id'].toString(), 'REJECTED'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("REJECT"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _finalizeLoan(loan['id'].toString(), 'DISBURSED'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const Text("APPROVE & DISBURSE", style: TextStyle(color: Colors.white)),
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
        }, // Properly closing the builder
      ), // Properly closing the FutureBuilder
    );
  }
}