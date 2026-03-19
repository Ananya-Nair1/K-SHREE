import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CDSFinancialSummaryPage extends StatefulWidget {
  final String panchayat;
  const CDSFinancialSummaryPage({super.key, required this.panchayat});

  @override
  State<CDSFinancialSummaryPage> createState() => _CDSFinancialSummaryPageState();
}

class _CDSFinancialSummaryPageState extends State<CDSFinancialSummaryPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _totalSavings = 0.0;
  double _totalLoansDisbursed = 0.0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    try {
      // 1. Fetch all records from the 'savings' table
      final savingsResponse = await supabase.from('savings').select('amount');
      
      double savings = 0.0;
      for (var row in savingsResponse) {
        savings += double.tryParse(row['amount'].toString()) ?? 0.0;
      }

      // 2. Fetch all approved/disbursed loans from the 'loans' table
      final loansResponse = await supabase
          .from('loans')
          .select('principal_amount')
          .inFilter('status', ['APPROVED', 'DISBURSED']); // Only count active/cleared loans
          
      double loans = 0.0;
      for (var row in loansResponse) {
        loans += double.tryParse(row['principal_amount'].toString()) ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _totalSavings = savings;
          _totalLoansDisbursed = loans;
          _transactionCount = (savingsResponse as List).length + (loansResponse as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Finance Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Financial Summary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalBalanceCard(),
                  const SizedBox(height: 25),
                  const Text("Breakdown by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  _buildDetailRow("Total Savings Collected", "₹${_totalSavings.toStringAsFixed(2)}", Colors.green, Icons.savings),
                  const Divider(height: 30),
                  // Updated label to reflect the 'loans' table data
                  _buildDetailRow("Loans Disbursed", "₹${_totalLoansDisbursed.toStringAsFixed(2)}", Colors.blue, Icons.payments),
                  const Divider(height: 30),
                  _buildDetailRow("Total Records", _transactionCount.toString(), Colors.orange, Icons.receipt_long),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("Total Funds Managed", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          // Adding savings and loans gives a rough idea of total capital moved
          Text("₹${(_totalSavings + _totalLoansDisbursed).toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Across all ADS Units", style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, Color color, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 15),
        // FIXED OVERFLOW: Wrapped Title inside Expanded
        Expanded(
          child: Text(
            title, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10), // Replaced Spacer() with a fixed 10px gap
        Text(
          value, 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}