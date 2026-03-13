import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scheme_application_form.dart'; 
import 'application_status_page.dart';

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
  List<dynamic> _appliedSchemeIds = []; 
  Map<String, dynamic>? _memberProfile;
  
  // Filters
  int _selectedFilterIndex = 0; // 0: All, 1: Eligible, 2: Applied
  String _selectedCategory = "All Types"; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchUserApplications(),
      _fetchMemberProfile(),
    ]);
  }

  Future<void> _fetchUserApplications() async {
    try {
      final response = await supabase
          .from('scheme_applications')
          .select('scheme_id')
          .eq('member_id', widget.memberId);
      
      if (response != null && mounted) {
        setState(() {
          _appliedSchemeIds = (response as List).map((a) => a['scheme_id']).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    }
  }

  Future<void> _fetchMemberProfile() async {
    try {
      final response = await supabase
          .from('Registered_Members')
          .select()
          .eq('aadhar_number', widget.memberId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _memberProfile = response;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  bool _isEligibleForScheme(Map<String, dynamic> scheme) {
    if (_memberProfile == null) return true; 

    final criteria = (scheme['eligibility_criteria'] ?? '').toString().toLowerCase();
    final memberCategory = (_memberProfile!['category'] ?? '').toString().toLowerCase();
    final memberAplBpl = (_memberProfile!['apl_bpl'] ?? '').toString().toLowerCase();
    
    if (criteria.contains('bpl') && memberAplBpl.contains('apl')) {
      return false; 
    }

    if ((criteria.contains('sc') || criteria.contains('st') || criteria.contains('sc/st')) && 
        !(memberCategory.contains('sc') || memberCategory.contains('st'))) {
      return false; 
    }

    return true; 
  }

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
      body: FutureBuilder(
        future: supabase.from('government_schemes').select().eq('is_active', true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading schemes: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final allSchemes = snapshot.data as List<dynamic>? ?? [];

          // Extract unique categories dynamically from the database
          final Set<String> uniqueCategories = {"All Types"};
          for (var s in allSchemes) {
            if (s['category'] != null && s['category'].toString().isNotEmpty) {
              uniqueCategories.add(s['category'].toString());
            }
          }
          final categoryList = uniqueCategories.toList();

          // Filtering Logic
          final schemes = allSchemes.where((s) {
            // 1. Search Query Filter
            final matchesSearch = s['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                  s['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
            if (!matchesSearch) return false;

            // 2. Type/Category Filter
            if (_selectedCategory != "All Types" && s['category'] != _selectedCategory) {
              return false;
            }

            // 3. Status/Eligibility Chips
            bool alreadyApplied = _appliedSchemeIds.contains(s['id']);
            bool isEligible = _isEligibleForScheme(s);

            if (_selectedFilterIndex == 1 && !isEligible) return false; 
            if (_selectedFilterIndex == 2 && !alreadyApplied) return false; 

            return true;
          }).toList();

          return Column(
            children: [
              _buildSearchBar(),
              _buildCategorySelector(categoryList),
              _buildFilterChips(),
              Expanded(
                child: schemes.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text("No schemes found for this filter.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: schemes.length,
                      itemBuilder: (context, index) => _buildSchemeCard(schemes[index]),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  Widget _buildCategorySelector(List<String> categories) {
    return Container(
      width: double.infinity,
      color: Colors.teal,
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = category),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.white : Colors.teal.shade300),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.teal.shade800 : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      width: double.infinity,
      color: Colors.teal,
      padding: const EdgeInsets.only(bottom: 12, left: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip("All Status", 0, Icons.list),
            const SizedBox(width: 8),
            _buildStatusChip("eligible", 1, Icons.auto_awesome),
            const SizedBox(width: 8),
            _buildStatusChip("Already Applied", 2, Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int index, IconData icon) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.teal.shade800 : Colors.white),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.teal.shade800 : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
      selected: isSelected,
      selectedColor: Colors.amberAccent, 
      backgroundColor: Colors.teal.shade800,
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilterIndex = index);
      },
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    bool alreadyApplied = _appliedSchemeIds.contains(scheme['id']);
    bool isRecommended = _isEligibleForScheme(scheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(scheme['category'] ?? 'General', style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    if (isRecommended && !alreadyApplied) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Colors.blue),
                            SizedBox(width: 4),
                            Text("MATCH", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    if (alreadyApplied) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text("APPLIED", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                ),
                Text("Max: ₹${scheme['subsidy_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(scheme['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(scheme['description'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.rule, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                const Text("Eligibility:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 4),
            Text(scheme['eligibility_criteria'] ?? 'Contact ADS for details', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyApplied ? Colors.grey : (isRecommended ? Colors.teal : Colors.blueGrey), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: alreadyApplied ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SchemeApplicationForm(
                        scheme: scheme,
                        memberId: widget.memberId,
                        memberName: widget.memberName,
                      ),
                    ),
                  ).then((_) => _loadData()); // Refresh list when returning
                },
                child: Text(
                  alreadyApplied ? "Application Under Review" : (isRecommended ? "View Details & Apply" : "Apply Anyway"), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}