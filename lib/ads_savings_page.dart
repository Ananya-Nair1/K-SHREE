import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ADSWardSavingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSWardSavingsPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<ADSWardSavingsPage> createState() => _ADSWardSavingsPageState();
}

class _ADSWardSavingsPageState extends State<ADSWardSavingsPage> {
  final supabase = Supabase.instance.client;
  final Color primaryColor = const Color(0xFF2B6CB0); // ADS Blue

  bool _isLoading = true;
  double _grandTotal = 0.0;
  Map<String, double> _unitTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchWardSavings();
  }

  Future<void> _fetchWardSavings() async {
    try {
      final String ward = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '';

      if (ward.isEmpty) {
        throw Exception("Ward information missing for this ADS Chairperson.");
      }

      // Fetch savings for this ward
      final response = await supabase
          .from('savings') 
          // REMOVED 'transaction_type' from select, we just need unit and amount!
          .select('unit_number, amount') 
          .eq('ward_number', ward); 

      double tempTotal = 0.0;
      Map<String, double> tempUnitTotals = {};

      for (var record in response) {
        // We removed the 'if' statement here so it counts EVERYTHING!
        final double amount = double.tryParse(record['amount']?.toString() ?? '0') ?? 0.0;
        final String unit = record['unit_number']?.toString() ?? 'Unknown Unit';

        tempTotal += amount;
        
        if (tempUnitTotals.containsKey(unit)) {
          tempUnitTotals[unit] = tempUnitTotals[unit]! + amount;
        } else {
          tempUnitTotals[unit] = amount;
        }
      }

      var sortedKeys = tempUnitTotals.keys.toList()..sort();
      Map<String, double> sortedUnitTotals = {
        for (var key in sortedKeys) key: tempUnitTotals[key]!
      };

      if (mounted) {
        setState(() {
          _grandTotal = tempTotal;
          _unitTotals = sortedUnitTotals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching savings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final String wardName = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? 'Ward';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text('Ward $wardName Savings', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchWardSavings,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- GRAND TOTAL CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            "Total Ward Savings",
                            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(_grandTotal),
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    const Text(
                      "Savings by Unit",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 15),

                    // --- UNIT LIST ---
                    if (_unitTotals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.savings_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No savings data found for this ward.", style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _unitTotals.length,
                        itemBuilder: (context, index) {
                          String unitName = _unitTotals.keys.elementAt(index);
                          double amount = _unitTotals[unitName]!;
                          
                          if (!unitName.toLowerCase().contains('unit')) {
                            unitName = 'Unit $unitName';
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Icon(Icons.groups, color: primaryColor),
                              ),
                              title: Text(unitName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                              trailing: Text(
                                _formatCurrency(amount),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}