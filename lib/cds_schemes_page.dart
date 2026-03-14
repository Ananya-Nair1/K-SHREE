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
  final _deadlineController = TextEditingController();

  Future<void> _addNewScheme() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await supabase.from('schemes').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'subsidy_amount': double.tryParse(_subsidyController.text) ?? 0.0,
        'deadline': _deadlineController.text,
        'panchayat': widget.panchayat,
        'status': 'ACTIVE',
        'created_at': DateTime.now().toIso8601String(),
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
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Scheme Title (e.g. Poultry Farming)"), validator: (v) => v!.isEmpty ? "Required" : null),
                TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3, validator: (v) => v!.isEmpty ? "Required" : null),
                TextFormField(controller: _subsidyController, decoration: const InputDecoration(labelText: "Subsidy Amount (₹)"), keyboardType: TextInputType.number),
                TextFormField(controller: _deadlineController, decoration: const InputDecoration(labelText: "Application Deadline (YYYY-MM-DD)"), keyboardType: TextInputType.datetime),
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
        title: const Text("Panchayat Schemes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        future: supabase.from('schemes').select().eq('panchayat', widget.panchayat).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final schemes = snapshot.data ?? [];
          if (schemes.isEmpty) return const Center(child: Text("No schemes active in this Panchayat."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(scheme['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(scheme['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(5)),
                            child: Text("Subsidy: ₹${scheme['subsidy_amount']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const Spacer(),
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("Ends: ${scheme['deadline']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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