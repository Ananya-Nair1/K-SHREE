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
  double _totalLoansRepaid = 0.0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    try {
      // Fetching all transactions linked to this panchayat
      final response = await supabase
          .from('transactions')
          .select()
          .eq('panchayat', widget.panchayat);

      double savings = 0.0;
      double loans = 0.0;

      for (var row in response) {
        double amount = double.tryParse(row['amount'].toString()) ?? 0.0;
        String type = row['type']?.toString().toUpperCase() ?? '';
        
        if (type == 'SAVINGS') {
          savings += amount;
        } else if (type == 'LOAN_REPAYMENT') {
          loans += amount;
        }
      }

      setState(() {
        _totalSavings = savings;
        _totalLoansRepaid = loans;
        _transactionCount = (response as List).length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Finance Fetch Error: $e");
      setState(() => _isLoading = false);
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
                  _buildDetailRow("Loan Repayments", "₹${_totalLoansRepaid.toStringAsFixed(2)}", Colors.blue, Icons.payments),
                  const Divider(height: 30),
                  _buildDetailRow("Total Transactions", _transactionCount.toString(), Colors.orange, Icons.receipt_long),
                  const SizedBox(height: 40),
                  _buildInfoNote(),
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
          Text("₹${(_totalSavings + _totalLoansRepaid).toStringAsFixed(2)}", 
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "This data is aggregated from all verified NHG transactions in the Panchayat.",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }
}