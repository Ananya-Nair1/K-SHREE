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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Grievance", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 20),
              
              // ==========================================
              // MODERN & OVERFLOW-SAFE DROPDOWN
              // ==========================================
              DropdownButtonFormField<String>(
                isExpanded: true, // FIX: Forces text to truncate instead of overflowing
                value: _selectedCategory,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal, size: 28),
                elevation: 4,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: "Complaint Category",
                  labelStyle: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Colors.teal.withOpacity(0.04), // Subtle modern background
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.category_rounded, color: Colors.teal, size: 20),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none, // Removes default harsh border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _complaintCategories.map((c) => DropdownMenuItem(
                  value: c, 
                  child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87), overflow: TextOverflow.ellipsis)
                )).toList(),
                onChanged: (val) => setModalState(() => _selectedCategory = val),
              ),
              
              const SizedBox(height: 20),
              
              // MODERNIZED TEXT FIELD
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Explain the issue in detail...',
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.teal.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              // MODERNIZED BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitComplaint,
                  child: const Text("Submit to NHG Secretary", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
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

          if (complaints.isEmpty) {
            return const Center(
              child: Text("No grievances filed yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) => _buildComplaintCard(complaints[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddComplaintSheet,
        backgroundColor: Colors.teal,
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text("New Grievance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status'] ?? 'Pending at NHG';
    
    // Status Flow UI Colors
    Color statusColor = Colors.orange;
    Color bgColor = Colors.orange.withOpacity(0.1);
    
    if (status.contains('ADS')) {
      statusColor = Colors.blue;
      bgColor = Colors.blue.withOpacity(0.1);
    } else if (status.contains('CDS')) {
      statusColor = Colors.purple;
      bgColor = Colors.purple.withOpacity(0.1);
    } else if (status == 'Resolved') {
      statusColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0, // Flat modern look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaint['subject'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Text(complaint['description'], style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          ],
        ),
      ),
    );
  }
}