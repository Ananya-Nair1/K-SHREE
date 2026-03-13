import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  bool _isLocationSet = false;
  String _searchQuery = "";
  
  List<Map<String, dynamic>> _members = [];
  Map<String, bool> _attendanceState = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final secUnit = widget.secretaryData['unit_number']?.toString() ?? '';

    try {
      // 1. Check if GPS location is already set for this meeting
      final meetResponse = await supabase
          .from('meetings')
          .select('latitude, longitude')
          .eq('meet_id', widget.meetId)
          .maybeSingle();
      
      if (meetResponse != null && meetResponse['latitude'] != null) {
        _isLocationSet = true;
      }

      // 2. Fetch Members only for this unit
      final membersResponse = await supabase.from('Registered_Members')
          .select('full_name, aadhar_number')
          .eq('unit_number', secUnit)
          .order('full_name', ascending: true);

      // 3. Fetch Existing Attendance
      final attendanceResponse = await supabase.from('attendance')
          .select('aadhar_number, status')
          .eq('meet_id', widget.meetId);

      final Map<String, bool> existingRecords = {};
      for (var record in attendanceResponse) {
        existingRecords[record['aadhar_number'].toString()] = (record['status'] == 'Present');
      }

      setState(() {
        _members = List<Map<String, dynamic>>.from(membersResponse);
        for (var member in _members) {
          final aadhar = member['aadhar_number'].toString();
          _attendanceState[aadhar] = existingRecords[aadhar] ?? false;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: Capture Venue GPS (Replaces Map Logic) ---
  Future<void> _captureVenueLocation() async {
    setState(() => _isSaving = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      await supabase.from('meetings').update({
        'latitude': position.latitude,
        'longitude': position.longitude
      }).eq('meet_id', widget.meetId);

      setState(() {
        _isLocationSet = true;
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Venue Location Captured! Members can now mark attendance."), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("GPS Capture Failed: $e")));
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSaving = true);
    
    // Format data for upsert
    List<Map<String, dynamic>> attendanceData = _members.map((m) {
      final aadhar = m['aadhar_number'].toString();
      return {
        'meet_id': widget.meetId,
        'aadhar_number': aadhar,
        'full_name': m['full_name'], // Added for reporting
        'status': _attendanceState[aadhar] == true ? 'Present' : 'Absent',
        'method': _attendanceState[aadhar] == true ? 'Secretary Manual' : 'N/A',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }).toList();

    try {
      await supabase.from('attendance').upsert(attendanceData, onConflict: 'meet_id, aadhar_number');
      
      // Update meeting status to closed
      await supabase.from('meetings').update({'status': 'HELD'}).eq('meet_id', widget.meetId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Closed & Attendance Saved!"), backgroundColor: Colors.teal));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _members.where((m) => 
      m['full_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Attendance Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo)) 
        : Column(
        children: [
          // GPS Status Card
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isLocationSet ? Colors.green.shade50 : Colors.orange.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300))
            ),
            child: Column(
              children: [
                Icon(
                  _isLocationSet ? Icons.verified_user : Icons.location_off, 
                  color: _isLocationSet ? Colors.green : Colors.orange, 
                  size: 35
                ),
                const SizedBox(height: 10),
                Text(
                  _isLocationSet ? "Venue GPS Locked" : "GPS Not Set",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isLocationSet ? Colors.green.shade700 : Colors.orange.shade800),
                ),
                const SizedBox(height: 5),
                Text(
                  _isLocationSet 
                    ? "Members can now use 'Mark Attendance' on their phones."
                    : "Stand at the meeting spot and tap the button below to enable mobile attendance.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                if (!_isLocationSet) ...[
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: _isSaving ? null : _captureVenueLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text("Capture Venue Location"),
                  ),
                ]
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search member name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Member List
          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                final aadhar = member['aadhar_number'].toString();
                final isPresent = _attendanceState[aadhar] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: CheckboxListTile(
                    activeColor: Colors.indigo,
                    title: Text(member['full_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("ID: $aadhar", style: const TextStyle(fontSize: 11)),
                    value: isPresent,
                    onChanged: (val) => setState(() => _attendanceState[aadhar] = val ?? false),
                    secondary: CircleAvatar(
                      backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      child: Icon(isPresent ? Icons.person : Icons.person_outline, color: isPresent ? Colors.green : Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Submit Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, 
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _submitAttendance,
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Save & End Meeting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}