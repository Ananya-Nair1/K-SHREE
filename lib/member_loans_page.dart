import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MemberLoansPage extends StatefulWidget {
  final String memberId;

  const MemberLoansPage({Key? key, required this.memberId}) : super(key: key);

  @override
  State<MemberLoansPage> createState() => _MemberLoansPageState();
}

class _MemberLoansPageState extends State<MemberLoansPage> {
  final supabase = Supabase.instance.client;
  late Future<List<dynamic>> _loansFuture;

  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedLoanSource;

  // Authentic Kudumbashree Loan Sources
  final List<String> _loanSources = [
    'Internal (Thrift Savings) Loan',
    'Bank Linkage Loan (JLG)',
    'Linking / Matching Grant',
    'Special Scheme (Housing/Edu)'
  ];

  @override
  void initState() {
    super.initState();
    _refreshLoans();
  }

  void _refreshLoans() {
    setState(() {
      _loansFuture = supabase
          .from('loans')
          .select()
          .eq('member_id', widget.memberId)
          .order('applied_date', ascending: false);
    });
  }

  String _formatCurrency(dynamic amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    return format.format(amount ?? 0);
  }

  // ==========================================
  // MEETING REQUEST LOGIC
  // ==========================================
  Future<void> _submitMeetingRequest() async {
    if (_selectedLoanSource == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select loan type and amount')));
      return;
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

      await supabase.from('loans').insert({
        'member_id': widget.memberId,
        'loan_type': _selectedLoanSource,
        'principal_amount': double.parse(_amountController.text),
        'outstanding_amount': double.parse(_amountController.text),
        'remarks': _reasonController.text.trim(),
        'status': 'Pending Discussion (Next Meeting)', 
      });

      if (mounted) {
        Navigator.pop(context); // Close loader
        Navigator.pop(context); // Close sheet
        _amountController.clear();
        _reasonController.clear();
        _refreshLoans();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request added to next NHG Meeting Agenda'),
          backgroundColor: Colors.teal,
        ));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showRequestLoanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Request Loan for Meeting", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 8),
              const Text("This request will be presented to all members in the next NHG meeting for approval.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              
              // FIXED DROPDOWN WITH OVERFLOW PROTECTION
              DropdownButtonFormField<String>(
                isExpanded: true, // Prevents Right Overflow
                value: _selectedLoanSource,
                decoration: _inputStyle("Loan Source", Icons.account_balance_wallet),
                items: _loanSources.map((s) => DropdownMenuItem(
                  value: s, 
                  child: Text(
                    s, 
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis, // Extra safety for long text
                  )
                )).toList(),
                onChanged: (val) => setModalState(() => _selectedLoanSource = val),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _inputStyle("Required Amount (₹)", Icons.currency_rupee),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: _inputStyle("Purpose / Reason", Icons.note_alt_outlined),
              ),
              const SizedBox(height: 25),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, 
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: _submitMeetingRequest,
                  child: const Text("Add to Meeting Agenda", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // MODERN INPUT DECORATION HELPER
  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.teal, size: 22),
      filled: true,
      fillColor: Colors.teal.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.teal, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Loan Passbook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          final loans = snapshot.data ?? [];
          if (loans.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) => _buildLoanCard(loans[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestLoanSheet,
        backgroundColor: Colors.teal,
        elevation: 4,
        icon: const Icon(Icons.forum_outlined, color: Colors.white),
        label: const Text("Request for Meeting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final status = loan['status'];
    Color statusColor = Colors.orange;
    if (status == 'Active') statusColor = Colors.green;
    if (status == 'Rejected') statusColor = Colors.red;
    if (status == 'Closed') statusColor = Colors.grey;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loan['loan_type'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValue("Amount", _formatCurrency(loan['principal_amount'])),
                _buildValue("Balance", _formatCurrency(loan['outstanding_amount'])),
                _buildValue("EMI", loan['emi_amount'] != null ? _formatCurrency(loan['emi_amount']) : "N/A"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValue(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No loan history found.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}