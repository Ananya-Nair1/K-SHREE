import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member_details_page.dart';

class MemberSearchPage extends StatefulWidget {
  final String panchayat;
  const MemberSearchPage({super.key, required this.panchayat});

  @override
  State<MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      // Search by name or aadhar number within the specific panchayat
      final response = await supabase
          .from('Registered_Members')
          .select()
          .eq('panchayat', widget.panchayat)
          .or('full_name.ilike.%$query%,aadhar_number.eq.$query');

      setState(() {
        _searchResults = response as List<dynamic>;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Member Directory"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by Name or Aadhar",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(child: Text("No members found."))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final member = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: member['photo_url'] != null
                                  ? NetworkImage(member['photo_url'])
                                  : null,
                              child: member['photo_url'] == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(member['full_name'] ?? "Unknown"),
                            subtitle: Text("Ward: ${member['ward']} | Unit: ${member['unit_number']}"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MemberDetailsPage(member: member),
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
}