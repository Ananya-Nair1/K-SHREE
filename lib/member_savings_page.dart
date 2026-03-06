import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberSavingsPage extends StatefulWidget {
  final String memberId; // Aadhar number

  const MemberSavingsPage({Key? key, required this.memberId}) : super(key: key);

  @override
  State<MemberSavingsPage> createState() => _MemberSavingsPageState();
}

class _MemberSavingsPageState extends State<MemberSavingsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('My Passbook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        // Fetch all savings transactions for this specific member
        future: supabase
            .from('savings')
            .select()
            .eq('member_id', widget.memberId)
            .order('transaction_date', ascending: false), // Newest first
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final transactions = snapshot.data as List<dynamic>? ?? [];

          // Calculate total savings by summing up all the amounts
          double totalSavings = 0;
          for (var tx in transactions) {
            totalSavings += (tx['amount'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // TOP SECTION: Total Savings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Total Savings",
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹${totalSavings.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Updated securely via K-SHREE",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BOTTOM SECTION: Transaction History List
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
              ),
              
              const SizedBox(height: 10),

              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No transactions yet.", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return _buildTransactionCard(tx);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amount = tx['amount']?.toString() ?? '0';
    final type = tx['transaction_type'] ?? 'Deposit';
    final date = tx['transaction_date'] ?? 'Unknown Date';

    // Make fines red, everything else green
    final isFine = type.toString().toLowerCase().contains('fine');
    final color = isFine ? Colors.red : Colors.green;
    final icon = isFine ? Icons.money_off : Icons.trending_up;
    final prefix = isFine ? "-" : "+";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        subtitle: Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Text(
          "$prefix₹$amount",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ),
    );
  }
}