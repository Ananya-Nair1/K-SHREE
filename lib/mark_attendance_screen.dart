import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String meetId;
  final Map<String, dynamic> secretaryData;

  const MarkAttendanceScreen({
    Key? key,
    required this.meetId,
    required this.secretaryData,
  }) : super(key: key);

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final supabase = Supabase.instance.client;
  
  List<dynamic> _unitMembers = [];
  Set<String> _presentAadhars = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final unitNumber = widget.secretaryData['unit_number'].toString();

      // 1. Get all members in the Secretary's unit
      final membersRes = await supabase
          .from('Registered_Members')
          .select()
          .eq('unit_number', unitNumber)
          .order('full_name', ascending: true);

      // 2. Get members who already marked attendance in the database
      final attendanceRes = await supabase
          .from('attendance')
          .select('aadhar_number')
          .eq('meet_id', widget.meetId);

      // Convert the attendance list into a Set of Aadhar numbers for fast lookup
      final presentSet = (attendanceRes as List).map((e) => e['aadhar_number'].toString()).toSet();

      if (mounted) {
        setState(() {
          _unitMembers = membersRes;
          _presentAadhars = presentSet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAttendance(String aadhar, bool isCurrentlyPresent) async {
    // Optimistic UI Update: Change the switch immediately for a snappy feel
    setState(() {
      if (isCurrentlyPresent) {
        _presentAadhars.remove(aadhar);
      } else {
        _presentAadhars.add(aadhar);
      }
    });

    try {
      if (isCurrentlyPresent) {
        // Remove attendance
        await supabase
            .from('attendance')
            .delete()
            .eq('meet_id', widget.meetId)
            .eq('aadhar_number', aadhar);
      } else {
        // Add attendance
        await supabase.from('attendance').insert({
          'meet_id': widget.meetId,
          'aadhar_number': aadhar,
          'status': 'Present',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Revert the UI if the database update fails
      setState(() {
        if (isCurrentlyPresent) {
          _presentAadhars.add(aadhar);
        } else {
          _presentAadhars.remove(aadhar);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update database: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Manual Attendance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
        : Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.teal,
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Present:", style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text("${_presentAadhars.length} / ${_unitMembers.length}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _unitMembers.length,
                  itemBuilder: (context, index) {
                    final member = _unitMembers[index];
                    final aadhar = member['aadhar_number'].toString();
                    final isPresent = _presentAadhars.contains(aadhar);

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green.shade100 : Colors.grey.shade200,
                          child: Icon(
                            isPresent ? Icons.check : Icons.person,
                            color: isPresent ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(member['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: $aadhar", style: const TextStyle(fontSize: 12)),
                        trailing: Switch(
                          value: isPresent,
                          activeColor: Colors.green,
                          onChanged: (val) => _toggleAttendance(aadhar, isPresent),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}