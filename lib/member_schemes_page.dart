import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scheme_application_form.dart'; // Ensure this is imported

class MemberSchemesPage extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MemberSchemesPage({
    Key? key, 
    required this.memberId, 
    required this.memberName
  }) : super(key: key);

  @override
  State<MemberSchemesPage> createState() => _MemberSchemesPageState();
}

class _MemberSchemesPageState extends State<MemberSchemesPage> {
  final supabase = Supabase.instance.client;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Government Schemes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder(
              future: supabase.from('government_schemes').select().eq('is_active', true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }
                final allSchemes = snapshot.data as List<dynamic>? ?? [];
                
                final schemes = allSchemes.where((s) => 
                  s['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();

                if (schemes.isEmpty) {
                  return const Center(child: Text("No matching schemes found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schemes.length,
                  itemBuilder: (context, index) => _buildSchemeCard(schemes[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search schemes (e.g. Housing, Edu)",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(scheme['category'] ?? 'General', style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text("Max: ₹${scheme['subsidy_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(scheme['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(scheme['description'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const Divider(height: 24),
            const Text("Eligibility:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            Text(scheme['eligibility_criteria'] ?? 'Contact ADS for details', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  // UPDATED: Navigates to the Application Form
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SchemeApplicationForm(
                        scheme: scheme,
                        memberId: widget.memberId,
                        memberName: widget.memberName,
                      ),
                    ),
                  );
                },
                child: const Text("View Details & Apply", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}