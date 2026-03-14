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
  
  List<dynamic> _allSavingsData = [];
  List<dynamic> _allMembersData = [];
  List<String> _availableUnits = ['All'];
  String _selectedUnit = 'All';

  Map<String, double> _unitTotals = {};
  Map<String, double> _memberTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchWardSavings();
  }

  Future<void> _fetchWardSavings() async {
    try {
      final String ward = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '';
      final String panchayat = widget.userData['panchayat']?.toString() ?? '';
      final String district = widget.userData['district']?.toString() ?? '';

      if (ward.isEmpty) throw Exception("Ward information missing.");

      // 1. Fetch ALL members in this ward to get every unit (even ones with 0 savings)
      final membersResponse = await supabase
          .from('Registered_Members')
          .select('unit_number, full_name')
          .eq('ward', ward)
          .ilike('panchayat', panchayat)
          .ilike('district', district);

      _allMembersData = membersResponse;

      // 2. Fetch the actual savings data
      final savingsResponse = await supabase
          .from('savings')
          .select('amount, unit_number, transaction_type, Registered_Members!inner(full_name, panchayat, district)')
          .eq('ward_number', ward)
          .ilike('Registered_Members.panchayat', panchayat)
          .ilike('Registered_Members.district', district);

      _allSavingsData = savingsResponse;
      
      _extractAvailableUnits();
      _processData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching data: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  // Extracts all unique units from the Registered_Members table
  void _extractAvailableUnits() {
    Set<String> units = {};
    for (var member in _allMembersData) {
      if (member['unit_number'] != null) {
        units.add(member['unit_number'].toString());
      }
    }
    
    // Sort numerically if possible, otherwise alphabetically
    var sortedUnits = units.toList()..sort((a, b) {
      int? numA = int.tryParse(a);
      int? numB = int.tryParse(b);
      if (numA != null && numB != null) return numA.compareTo(numB);
      return a.compareTo(b);
    });

    _availableUnits = ['All', ...sortedUnits];
    
    if (!_availableUnits.contains(_selectedUnit)) {
      _selectedUnit = 'All';
    }
  }

  void _processData() {
    double tempTotal = 0.0;
    Map<String, double> tempUnitTotals = {};
    Map<String, double> tempMemberTotals = {};

    // 1. Initialize everything to 0.0 so empty units/members still show up
    if (_selectedUnit == 'All') {
      for (String unit in _availableUnits) {
        if (unit != 'All') tempUnitTotals[unit] = 0.0;
      }
    } else {
      for (var member in _allMembersData) {
        if (member['unit_number']?.toString() == _selectedUnit) {
          final memberName = member['full_name'] ?? 'Unknown Member';
          tempMemberTotals[memberName] = 0.0;
        }
      }
    }

    // 2. Add up the actual savings
    for (var record in _allSavingsData) {
      final String unit = record['unit_number']?.toString() ?? 'Unknown';
      final String memberName = record['Registered_Members']?['full_name'] ?? 'Unknown Member';
      final String type = record['transaction_type']?.toString() ?? 'Deposit';
      
      double amount = double.tryParse(record['amount']?.toString() ?? '0') ?? 0.0;
      if (type == 'Withdrawal') amount = -amount; 

      if (_selectedUnit == 'All') {
        tempTotal += amount;
        if (tempUnitTotals.containsKey(unit)) {
          tempUnitTotals[unit] = tempUnitTotals[unit]! + amount;
        }
      } else if (_selectedUnit == unit) {
        tempTotal += amount;
        if (tempMemberTotals.containsKey(memberName)) {
          tempMemberTotals[memberName] = tempMemberTotals[memberName]! + amount;
        } else {
          tempMemberTotals[memberName] = amount;
        }
      }
    }

    if (mounted) {
      setState(() {
        _grandTotal = tempTotal;
        
        // Sort keys alphabetically
        _unitTotals = Map.fromEntries(tempUnitTotals.entries.toList()..sort((a, b) {
           int? numA = int.tryParse(a.key);
           int? numB = int.tryParse(b.key);
           if (numA != null && numB != null) return numA.compareTo(numB);
           return a.key.compareTo(b.key);
        }));
        _memberTotals = Map.fromEntries(tempMemberTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
        
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
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
                          Text(
                            _selectedUnit == 'All' ? "Total Ward Savings" : "Total Savings for Unit $_selectedUnit",
                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(_grandTotal),
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // --- DROPDOWN FILTER ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedUnit,
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          items: _availableUnits.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit == 'All' ? 'View All Units' : 'Unit $unit', 
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedUnit = newValue;
                                _processData(); // Recalculate totals based on new selection
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    
                    Text(
                      _selectedUnit == 'All' ? "Savings by Unit" : "Savings by Member",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 15),

                    // --- LIST VIEW ---
                    if (_selectedUnit == 'All' ? _unitTotals.isEmpty : _memberTotals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.savings_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No units/members found.", style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedUnit == 'All' ? _unitTotals.length : _memberTotals.length,
                        itemBuilder: (context, index) {
                          String titleName;
                          double amount;
                          IconData leadingIcon;

                          if (_selectedUnit == 'All') {
                            // Display Unit Totals
                            titleName = _unitTotals.keys.elementAt(index);
                            if (!titleName.toLowerCase().contains('unit')) titleName = 'Unit $titleName';
                            amount = _unitTotals[_unitTotals.keys.elementAt(index)]!;
                            leadingIcon = Icons.groups;
                          } else {
                            // Display Member Totals
                            titleName = _memberTotals.keys.elementAt(index);
                            amount = _memberTotals[_memberTotals.keys.elementAt(index)]!;
                            leadingIcon = Icons.person;
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
                                child: Icon(leadingIcon, color: primaryColor),
                              ),
                              title: Text(titleName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                              trailing: Text(
                                _formatCurrency(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16, 
                                  color: amount == 0 ? Colors.grey.shade500 : Colors.green.shade700
                                ),
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