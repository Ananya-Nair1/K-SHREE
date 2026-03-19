import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberSearchPage extends StatefulWidget {
  final String panchayat;
  const MemberSearchPage({super.key, required this.panchayat});

  @override
  State<MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  final supabase = Supabase.instance.client;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    var query = supabase
        .from('Registered_Members')
        .select()
        .eq('panchayat', widget.panchayat);

    if (_searchQuery.isNotEmpty) {
      query = query.or('full_name.ilike.%$_searchQuery%,aadhar_number.ilike.%$_searchQuery%');
    }

    final response = await query.order('full_name', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Member Directory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Search by Name or Aadhar",
                labelStyle: const TextStyle(color: Colors.teal),
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text("No members found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    
                    final String name = member['full_name'] ?? "Unknown Member";
                    final String aadhar = member['aadhar_number'] ?? "N/A";
                    final String ward = member['ward']?.toString() ?? "N/A";
                    final String unit = member['unit_number']?.toString() ?? "N/A";
                    final String designation = member['designation'] ?? "Member";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          radius: 25,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        // FIXED OVERFLOW: Added Expanded/ellipsis to title
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Aadhar: $aadhar", style: const TextStyle(color: Colors.blueGrey)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(5)),
                                  child: Text("Ward: $ward", style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(5)),
                                  child: Text("Unit: $unit", style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // FIXED OVERFLOW: Wrapped in SizedBox with Fixed Width and FittedBox
                        trailing: SizedBox(
                          width: 85, 
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(designation == 'Member' ? Icons.person : Icons.star, 
                                  color: designation == 'Member' ? Colors.grey : Colors.amber, size: 20),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(designation, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          _showMemberDetails(context, member);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member['full_name'] ?? 'Member Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: ${member['phone_number'] ?? 'N/A'}"),
            const SizedBox(height: 5),
            Text("DOB: ${member['dob'] ?? 'N/A'}"),
            const SizedBox(height: 5),
            Text("Bank: ${member['bank_name'] ?? 'N/A'}"),
            const SizedBox(height: 5),
            Text("A/C No: ${member['account_number'] ?? 'N/A'}"),
            const SizedBox(height: 5),
            Text("IFSC: ${member['ifsc_code'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}