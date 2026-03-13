import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class MemberMeetingsPage extends StatefulWidget {
  final String unitNumber;
  final String memberId;

  const MemberMeetingsPage({
    Key? key,
    required this.unitNumber,
    required this.memberId,
  }) : super(key: key);

  @override
  State<MemberMeetingsPage> createState() => _MemberMeetingsPageState();
}

class _MemberMeetingsPageState extends State<MemberMeetingsPage> {
  final supabase = Supabase.instance.client;
  bool _isMarkingAttendance = false;
  bool _isLoading = true;
  double _attendancePercentage = 0.0;
  List<dynamic> _meetings = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetches meetings and calculates stats
  Future<void> _fetchData() async {
    try {
      // 1. Get the member's exact profile for strict filtering
      final memberProfile = await supabase
          .from('Registered_Members')
          .select('panchayat, ward, unit_number')
          .eq('aadhar_number', widget.memberId)
          .maybeSingle();

      if (memberProfile == null) return;

      // 2. Fetch all meetings matching Panchayat & Ward
      final meetingsResponse = await supabase
          .from('meetings')
          .select()
          .eq('panchayat', memberProfile['panchayat'].toString())
          .eq('ward', memberProfile['ward'].toString())
          .order('meeting_date', ascending: false);

      // 3. Fetch member's attendance records
      final attendanceResponse = await supabase
          .from('attendance')
          .select('meet_id, status')
          .eq('aadhar_number', widget.memberId);

      final Map<String, String> attendanceMap = {
        for (var item in attendanceResponse) item['meet_id'].toString(): item['status'].toString()
      };

      // 4. Filter for NHG level and this Unit
      List<dynamic> filteredMeetings = [];
      int presentCount = 0;
      int heldMeetingsCount = 0;
      final String memberUnit = memberProfile['unit_number'].toString();

      for (var meeting in meetingsResponse) {
        bool isDirectUnit = meeting['unit_name']?.toString() == memberUnit;
        bool isNhgMeeting = meeting['meeting_level']?.toString().toUpperCase().contains('NHG') ?? false;

        if (isDirectUnit && isNhgMeeting) {
          String status = attendanceMap[meeting['meet_id'].toString()] ?? 'Absent';
          
          if (meeting['status'] == 'HELD') {
            heldMeetingsCount++;
            if (status == 'Present') presentCount++;
          }

          filteredMeetings.add({
            ...meeting,
            'member_status': status,
          });
        }
      }

      setState(() {
        _meetings = filteredMeetings;
        _attendancePercentage = heldMeetingsCount == 0 ? 0.0 : (presentCount / heldMeetingsCount) * 100;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(Map<String, dynamic> meeting) async {
    setState(() => _isMarkingAttendance = true);
    try {
      if (meeting['latitude'] == null) throw Exception("Secretary hasn't set location yet.");

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, 
        double.parse(meeting['latitude'].toString()), 
        double.parse(meeting['longitude'].toString())
      );

      if (distance > 15) throw Exception("Move within 15m of venue. You are ${distance.toInt()}m away.");

      await supabase.from('attendance').insert({
        'meet_id': meeting['meet_id'],
        'aadhar_number': widget.memberId,
        'status': 'Present',
        'method': 'App GPS',
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Attendance Marked!"), backgroundColor: Colors.green));
      _fetchData(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      setState(() => _isMarkingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Meetings & Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
                children: [
                  _buildStatsCard(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Meeting Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                  ),
                  Expanded(
                    child: _meetings.isEmpty
                        ? const Center(child: Text("No meetings found for your unit."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _meetings.length,
                            itemBuilder: (context, index) => _buildMeetingCard(_meetings[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your Attendance", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Text("${_attendancePercentage.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          CircularProgressIndicator(
            value: _attendancePercentage / 100,
            backgroundColor: Colors.white24,
            color: Colors.white,
            strokeWidth: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final String status = meeting['status'] ?? 'SCHEDULED';
    final String memberStatus = meeting['member_status'];
    final bool isPresent = memberStatus == 'Present';
    final bool canMark = status == 'SCHEDULED' && meeting['latitude'] != null && !isPresent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                child: Icon(isPresent ? Icons.check : Icons.groups, color: isPresent ? Colors.green : Colors.teal),
              ),
              title: Text(meeting['reason'] ?? 'NHG Meeting', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Venue: ${meeting['venue']}"),
              trailing: Text(
                isPresent ? "PRESENT" : (status == 'HELD' ? "ABSENT" : "UPCOMING"),
                style: TextStyle(
                  color: isPresent ? Colors.green : (status == 'HELD' ? Colors.red : Colors.orange),
                  fontWeight: FontWeight.bold, fontSize: 10
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(meeting['meeting_date'], style: const TextStyle(fontSize: 12)),
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(meeting['meeting_time'], style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (canMark) ...[
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isMarkingAttendance ? null : () => _markAttendance(meeting),
                icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
                label: const Text("Mark Attendance", style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}