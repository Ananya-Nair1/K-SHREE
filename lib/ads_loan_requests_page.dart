import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ADSLoanRequestsPage extends StatefulWidget {
  final Map<String, dynamic> userData; // ADS Chairperson data

  const ADSLoanRequestsPage({super.key, required this.userData});

  @override
  State<ADSLoanRequestsPage> createState() => _ADSLoanRequestsPageState();
}

class _ADSLoanRequestsPageState extends State<ADSLoanRequestsPage> {
  final supabase = Supabase.instance.client;
  bool _isFetching = true;
  bool _isUpdating = false;
  List<Map<String, dynamic>> loanRequests = [];

  final Color adsBlue = const Color(0xFF2B6CB0); // Consistent ADS Theme Color

  @override
  void initState() {
    super.initState();
    _fetchADSLevelLoans();
  }

  // --- 1. FETCH LOANS WITH GEOGRAPHIC FILTERING ---
  Future<void> _fetchADSLevelLoans() async {
    setState(() => _isFetching = true);
    try {
      // Data normalization to match Supabase types
      final String district = widget.userData['district']?.toString() ?? "";
      final String panchayat = widget.userData['panchayat']?.toString() ?? "";
      
      // Parsing ward to int to match the 'int8' column type in Registered_Members
      final int ward = int.tryParse(widget.userData['ward']?.toString() ?? 
                       widget.userData['ward_number']?.toString() ?? "0") ?? 0;

      final response = await supabase
          .from('loans')
          .select('''
            id,
            member_id,
            loan_type,
            principal_amount,
            status,
            applied_date,
            remarks,
            Registered_Members!inner (
              full_name, 
              unit_number, 
              phone_number,
              district,
              panchayat,
              ward
            ) 
          ''')
          .eq('status', 'Pending at ADS') 
          .eq('Registered_Members.district', district)
          .eq('Registered_Members.panchayat', panchayat)
          .eq('Registered_Members.ward', ward) 
          .order('applied_date', ascending: false);

      if (mounted) {
        setState(() {
          loanRequests = List<Map<String, dynamic>>.from(response);
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 2. UPDATE LOAN STATUS ---
  Future<void> _processLoan(String loanId, String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await supabase
          .from('loans')
          .update({'status': newStatus})
          .eq('id', loanId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Loan ${newStatus == 'Pending at CDS' ? 'Forwarded to CDS' : 'Rejected'}"),
            backgroundColor: newStatus.contains('Rejected') ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _fetchADSLevelLoans(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB), 
      appBar: AppBar(
        title: const Text('ADS Verification', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: adsBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchADSLevelLoans,
          )
        ],
      ),
      body: _isFetching
          ? Center(child: CircularProgressIndicator(color: adsBlue))
          : loanRequests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: adsBlue,
                  onRefresh: _fetchADSLevelLoans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: loanRequests.length,
                    itemBuilder: (context, index) => _buildLoanCard(loanRequests[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 80, color: adsBlue.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No pending loan requests for your ward", 
            style: TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final member = loan['Registered_Members'];
    final DateTime appliedDate = DateTime.parse(loan['applied_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: adsBlue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member['full_name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("NHG Unit: ${member['unit_number']}",
                              style: TextStyle(color: adsBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: adsBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text("₹${loan['principal_amount']}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: adsBlue)),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildInfoTile(Icons.phone_outlined, "Contact", member['phone_number'] ?? 'N/A'),
                const SizedBox(height: 10),
                _buildInfoTile(Icons.account_balance_outlined, "Loan Type", loan['loan_type'] ?? 'N/A'),
                const SizedBox(height: 10),
                _buildInfoTile(Icons.event_note_outlined, "Applied Date", DateFormat('dd MMM yyyy').format(appliedDate)),
                
                if (loan['remarks'] != null && loan['remarks'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                    child: Text("Remarks: ${loan['remarks']}", 
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic)),
                  ),
                ],

                const SizedBox(height: 24),
                
                if (_isUpdating)
                  Center(child: CircularProgressIndicator(color: adsBlue))
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processLoan(loan['id'], 'Rejected at ADS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade100),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _processLoan(loan['id'], 'Pending at CDS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: adsBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Forward to CDS", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade300),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)))),
      ],
    );
  }
}