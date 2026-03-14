import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CDSSchemesPage extends StatefulWidget {
  final String panchayat;
  const CDSSchemesPage({super.key, required this.panchayat});

  @override
  State<CDSSchemesPage> createState() => _CDSSchemesPageState();
}

class _CDSSchemesPageState extends State<CDSSchemesPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subsidyController = TextEditingController();
  final _categoryController = TextEditingController();
  final _eligibilityController = TextEditingController();

  Future<void> _addNewScheme() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // UPDATED: Matching your exact database columns
      await supabase.from('government_schemes').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'subsidy_amount': double.tryParse(_subsidyController.text) ?? 0.0,
        'category': _categoryController.text.isNotEmpty ? _categoryController.text : 'General',
        'eligibility_criteria': _eligibilityController.text,
        'is_active': true, // Using the boolean from your schema
        // Removed 'panchayat' and 'deadline' as they don't exist in your table
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New Scheme Launched Successfully!"), backgroundColor: Colors.green)
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      debugPrint("Error adding scheme: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showAddSchemeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Launch New Scheme", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Scheme Title"), validator: (v) => v!.isEmpty ? "Required" : null),
                TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2, validator: (v) => v!.isEmpty ? "Required" : null),
                TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: "Category (e.g., Agriculture, Education)")),
                TextFormField(controller: _subsidyController, decoration: const InputDecoration(labelText: "Subsidy Amount (₹)"), keyboardType: TextInputType.number),
                TextFormField(controller: _eligibilityController, decoration: const InputDecoration(labelText: "Eligibility Criteria (e.g., BPL only)"), maxLines: 2),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(15)),
                    onPressed: _addNewScheme,
                    child: const Text("Launch Scheme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Government Schemes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: _showAddSchemeSheet,
        label: const Text("Add Scheme", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // UPDATED: Removed .eq('panchayat') because schemes are global in your DB.
        // Changed ordering to 'created_at' to match your schema.
        future: supabase.from('government_schemes').select().order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          
          final schemes = snapshot.data ?? [];
          if (schemes.isEmpty) return const Center(child: Text("No government schemes available."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              final bool isActive = scheme['is_active'] ?? true;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(scheme['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(5)),
                        child: Text(isActive ? "ACTIVE" : "INACTIVE", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(scheme['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text("Eligibility: ${scheme['eligibility_criteria'] ?? 'None specified'}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(5)),
                            child: Text("Subsidy: ₹${scheme['subsidy_amount'] ?? 0}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const Spacer(),
                          const Icon(Icons.category, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(scheme['category'] ?? 'General', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}