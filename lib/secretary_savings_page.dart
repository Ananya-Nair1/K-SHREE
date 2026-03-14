import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SavingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SavingsPage({super.key, required this.userData});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _unitMembers = [];
  double _totalSavings = 0.0;
  bool _isLoading = true;

  String? _selectedMemberId;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final secUnit = widget.userData['unit_number'].toString();
    final secWard = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();
    final secPanchayat = widget.userData['panchayat']?.toString() ?? '';
    final secDistrict = widget.userData['district']?.toString() ?? '';

    try {
      final membersData = await supabase
          .from('Registered_Members')
          .select('aadhar_number, full_name')
          .eq('unit_number', secUnit)
          .eq('ward', secWard)
          .ilike('panchayat', secPanchayat) 
          .ilike('district', secDistrict)    
          .ilike('designation', 'Member');   

      final savingsData = await supabase
          .from('savings')
          .select('*, Registered_Members(full_name)')
          .eq('unit_number', secUnit)
          .eq('ward_number', secWard)
          .order('created_at', ascending: false);

      double total = 0;
      for (var item in savingsData) {
        if (item['transaction_type'] == 'Withdrawal') {
          total -= (item['amount'] as num).toDouble();
        } else {
          total += (item['amount'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _unitMembers = List<Map<String, dynamic>>.from(membersData);
          _transactions = List<Map<String, dynamic>>.from(savingsData);
          _totalSavings = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching data: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSavings() async {
    if (_selectedMemberId == null || _amountController.text.isEmpty) return;

    try {
      await supabase.from('savings').insert({
        'member_id': _selectedMemberId,
        'unit_number': widget.userData['unit_number'].toString(),
        'ward_number': (widget.userData['ward'] ?? widget.userData['ward_number']).toString(),
        'amount': double.parse(_amountController.text),
        'transaction_type': 'Deposit',
        'transaction_date': DateTime.now().toIso8601String().split('T')[0],
        'created_at': DateTime.now().toIso8601String(),
      });

      _amountController.clear();
      _selectedMemberId = null;
      
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isLoading = true); 
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Savings added successfully"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error adding savings: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await supabase.from('savings').delete().eq('transaction_id', transactionId);
      _fetchData(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction deleted"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting transaction: $e")),
        );
      }
    }
  }

  Future<void> _editTransaction(String transactionId, String currentAmount) async {
    TextEditingController editAmountController = TextEditingController(text: currentAmount);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Savings Amount"),
          content: TextField(
            controller: editAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "New Amount (₹)", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
              onPressed: () async {
                if (editAmountController.text.isEmpty) return;
                Navigator.pop(context); 
                setState(() => _isLoading = true);

                try {
                  await supabase
                      .from('savings')
                      .update({'amount': double.parse(editAmountController.text)})
                      .eq('transaction_id', transactionId);

                  _fetchData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Transaction updated successfully"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error updating transaction: $e"), backgroundColor: Colors.red),
                    );
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Add Member Savings"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Member", border: OutlineInputBorder()),
                  value: _selectedMemberId,
                  items: _unitMembers.map((member) {
                    return DropdownMenuItem<String>(
                      value: member['aadhar_number'].toString(),
                      child: Text(member['full_name']),
                    );
                  }).toList(),
                  onChanged: (value) => setStateDialog(() => _selectedMemberId = value),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                onPressed: _addSavings,
                child: const Text("Add"),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Unit Savings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink))
        : Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Text("Total Unit Savings", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("₹ ${_totalSavings.toStringAsFixed(2)}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.pink)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
              ),
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text("No savings recorded yet.", style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        color: Colors.pink,
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final txn = _transactions[index];
                            final memberName = txn['Registered_Members']?['full_name'] ?? 'Member ID: ${txn['member_id']}';
                            final amount = txn['amount']?.toString() ?? '0';
                            final dateStr = txn['created_at'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(txn['created_at'])) : '';
                            final type = txn['transaction_type'] ?? 'Deposit';
                            final transactionId = txn['transaction_id']?.toString() ?? '';

                            return Dismissible(
                              key: Key(transactionId.isNotEmpty ? transactionId : index.toString()),
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                color: Colors.blue,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  // Delete action
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm"),
                                        content: const Text("Are you sure you want to delete this transaction?"),
                                        actions: <Widget>[
                                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                                          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                        ],
                                      );
                                    },
                                  );
                                } else if (direction == DismissDirection.startToEnd) {
                                  // Edit action
                                  _editTransaction(transactionId, amount);
                                  return false; // Don't dismiss the item, just show the dialog
                                }
                                return false;
                              },
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  _deleteTransaction(transactionId);
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.pink.withOpacity(0.1),
                                    child: const Icon(Icons.account_balance_wallet, color: Colors.pink),
                                  ),
                                  title: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                                  trailing: Text(
                                    type == 'Withdrawal' ? "- ₹$amount" : "+ ₹$amount", 
                                    style: TextStyle(
                                      color: type == 'Withdrawal' ? Colors.red : Colors.green, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 16
                                    )
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Savings"),
      ),
    );
  }
}