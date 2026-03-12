import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String meetId;
  final Map<String, dynamic> secretaryData;

  const MarkAttendanceScreen({super.key, required this.meetId, required this.secretaryData});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _members = [];
  Map<String, bool> _attendanceState = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final secPanchayat = widget.secretaryData['panchayat']?.toString() ?? '';
    final secWard = (widget.secretaryData['ward'] ?? widget.secretaryData['ward_number'])?.toString() ?? '';
    final secUnit = widget.secretaryData['unit_number']?.toString() ?? '';

    try {
      final membersResponse = await supabase.from('Registered_Members')
          .select('full_name, aadhar_number')
          .eq('panchayat', secPanchayat).eq('ward', secWard).eq('unit_number', secUnit)
          .order('full_name', ascending: true);

      final attendanceResponse = await supabase.from('attendance').select('aadhar_number, status').eq('meet_id', widget.meetId);

      final Map<String, bool> existingRecords = {};
      for (var record in attendanceResponse) {
        existingRecords[record['aadhar_number']] = (record['status'] == 'Present');
      }

      setState(() {
        _members = List<Map<String, dynamic>>.from(membersResponse);
        for (var member in _members) {
          _attendanceState[member['aadhar_number']] = existingRecords[member['aadhar_number']] ?? false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSaving = true);
    List<Map<String, dynamic>> attendanceData = _members.map((m) => {
      'meet_id': widget.meetId,
      'aadhar_number': m['aadhar_number'].toString().replaceAll(' ', ''),
      'status': _attendanceState[m['aadhar_number']] == true ? 'Present' : 'Absent',
    }).toList();

    try {
      await supabase.from('attendance').upsert(attendanceData);
      await supabase.from('meetings').update({'status': 'held'}).eq('meet_id', widget.meetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance Saved!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance"), backgroundColor: Colors.teal),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final aadhar = member['aadhar_number'];
                return CheckboxListTile(
                  title: Text(member['full_name'] ?? 'Unknown'),
                  subtitle: Text("ID: $aadhar"),
                  value: _attendanceState[aadhar],
                  onChanged: (val) => setState(() => _attendanceState[aadhar] = val ?? false),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
              onPressed: _isSaving ? null : _submitAttendance,
              child: _isSaving ? const CircularProgressIndicator() : const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}