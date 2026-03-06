import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberGrievancePage extends StatefulWidget {
  final String memberId;
  final String unitNumber;

  const MemberGrievancePage({Key? key, required this.memberId, required this.unitNumber}) : super(key: key);

  @override
  State<MemberGrievancePage> createState() => _MemberGrievancePageState();
}

class _MemberGrievancePageState extends State<MemberGrievancePage> {
  final supabase = Supabase.instance.client;
  
  final _descriptionController = TextEditingController();
  String? _selectedCategory;

  // NEW: General Complaint Categories
  final List<String> _complaintCategories = [
    "Loan Disbursement Delay",
    "Thrift/Savings Mismatch",
    "Meeting Attendance Dispute",
    "NHG Leadership Issue",
    "Training/Scheme Inquiry",
    "Behavioral Complaint",
    "Other"
  ];

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category and add details')));
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Status starts at 'Pending at NHG'
      await supabase.from('complaints').insert({
        'member_id': widget.memberId,
        'unit_number': widget.unitNumber,
        'subject': _selectedCategory,
        'description': _descriptionController.text,
        'status': 'Pending at NHG', 
      });

      if (mounted) {
        Navigator.pop(context); // Close loader
        Navigator.pop(context); // Close sheet
        _descriptionController.clear();
        setState(() { _selectedCategory = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted to NHG Secretary'), backgroundColor: Colors.teal)
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAddComplaintSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder( // Needed to update dropdown state inside sheet
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Grievance", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 15),
              
              // NEW: Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Complaint Category",
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _complaintCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setModalState(() => _selectedCategory = val),
              ),
              
              const SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Explain the issue...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitComplaint,
                  child: const Text("Submit to NHG Secretary", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
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
        title: const Text('Grievance Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: supabase.from('complaints').select().eq('member_id', widget.memberId).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          final complaints = snapshot.data as List<dynamic>? ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) => _buildComplaintCard(complaints[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddComplaintSheet,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("File Complaint", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status'] ?? 'Pending at NHG';
    
    // Status Flow UI
    Color statusColor = Colors.orange;
    if (status.contains('ADS')) statusColor = Colors.blue;
    if (status.contains('CDS')) statusColor = Colors.purple;
    if (status == 'Resolved') statusColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(complaint['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(),
            Text(complaint['description'], style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}