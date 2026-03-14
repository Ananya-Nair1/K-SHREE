import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'map_picker_page.dart'; 

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

  Future<void> _fetchData() async {
    try {
      final memberProfile = await supabase
          .from('Registered_Members')
          .select('panchayat, ward, unit_number')
          .eq('aadhar_number', widget.memberId)
          .maybeSingle();

      if (memberProfile == null) return;

      final meetingsResponse = await supabase
          .from('meetings')
          .select()
          .eq('panchayat', memberProfile['panchayat'].toString())
          .eq('ward', memberProfile['ward'].toString())
          .order('meeting_date', ascending: false);

      final attendanceResponse = await supabase
          .from('attendance')
          .select('meet_id, status')
          .eq('aadhar_number', widget.memberId);

      final Map<String, String> attendanceMap = {
        for (var item in attendanceResponse) item['meet_id'].toString(): item['status'].toString()
      };

      List<dynamic> filteredMeetings = [];
      int presentCount = 0;
      int heldMeetingsCount = 0;
      final String memberUnit = memberProfile['unit_number'].toString();

      for (var meeting in meetingsResponse) {
        bool isDirectUnit = meeting['unit_name']?.toString() == memberUnit;
        bool isNhgMeeting = meeting['meeting_level']?.toString().toUpperCase().contains('NHG') ?? false;

        if (isDirectUnit && isNhgMeeting) {
          String status = attendanceMap[meeting['meet_id'].toString()] ?? 'Held';
          
          if (meeting['status'] == 'HELD' || meeting['status'] == 'COMPLETED') {
            heldMeetingsCount++;
            if (status == 'Present') presentCount++;
          }
          filteredMeetings.add({...meeting, 'member_status': status});
        }
      }

      setState(() {
        _meetings = filteredMeetings;
        _attendancePercentage = heldMeetingsCount == 0 ? 0.0 : (presentCount / heldMeetingsCount) * 100;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(Map<String, dynamic> meeting) async {
    setState(() => _isMarkingAttendance = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Please enable GPS/Location in your phone settings.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Location permission denied.");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied. Please enable them in App Settings.");
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      double distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, 
        double.parse(meeting['latitude'].toString()), 
        double.parse(meeting['longitude'].toString())
      );

      if (distance > 20) { 
        throw Exception("You are ${distance.toInt()}m away. Move closer to the venue.");
      }

      await supabase.from('attendance').upsert({
        'meet_id': meeting['meet_id'],
        'aadhar_number': widget.memberId,
        'status': 'Present',
        // FIXED: Removed 'method': 'App GPS' because it doesn't exist in the DB!
      });

      // Update meeting status so Secretary can add a report
      try {
        await supabase
            .from('meetings')
            .update({'status': 'HELD'})
            .eq('meet_id', meeting['meet_id']);
      } catch (e) {
        debugPrint('Failed to update meeting status: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Attendance Marked!"), backgroundColor: Colors.green));
        _fetchData(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isMarkingAttendance = false);
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
          SizedBox(
            height: 60, width: 60,
            child: CircularProgressIndicator(
              value: _attendancePercentage / 100,
              backgroundColor: Colors.white24,
              color: Colors.white,
              strokeWidth: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final String memberStatus = meeting['member_status'] ?? 'Absent';
    final bool isPresent = memberStatus == 'Present';
    final bool hasLocation = meeting['latitude'] != null;

    // --- STRICT TIME LOCK LOGIC ---
    DateTime meetingDateTime;
    try {
      meetingDateTime = DateTime.parse("${meeting['meeting_date']} ${meeting['meeting_time']}");
    } catch (e) {
      meetingDateTime = DateTime.now(); 
    }

    final DateTime now = DateTime.now();
    
    // Exact time match required. No early marking.
    final bool isTooEarly = now.isBefore(meetingDateTime);
    // Attendance window closes 4 hours after start
    final bool isTooLate = now.isAfter(meetingDateTime.add(const Duration(hours: 4)));
    final bool isTimeValid = !isTooEarly && !isTooLate;

    // Show button as long as they aren't present and a location exists.
    final bool showAttendanceButton = !isPresent && hasLocation;

    // --- DYNAMIC UI LABELS ---
    String displayStatus;
    Color statusColor;

    if (isPresent) {
      displayStatus = "PRESENT";
      statusColor = Colors.green;
    } else if (isTooLate) {
      displayStatus = "ABSENT";
      statusColor = Colors.red;
    } else if (isTooEarly) {
      displayStatus = "UPCOMING";
      statusColor = Colors.orange;
    } else {
      displayStatus = "ONGOING";
      statusColor = Colors.blue;
    }

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
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(isPresent ? Icons.check : Icons.groups, color: statusColor),
              ),
              title: Text(meeting['reason'] ?? 'NHG Meeting', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Venue: ${meeting['venue']}"),
              trailing: Text(
                displayStatus,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
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
            const SizedBox(height: 15),
            Row(
              children: [
                if (hasLocation)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ViewMeetingMapPage(
                            latitude: double.parse(meeting['latitude'].toString()),
                            longitude: double.parse(meeting['longitude'].toString()),
                            venueName: meeting['venue'] ?? 'Meeting Venue',
                          )
                        ));
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text("Map"), 
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blueGrey),
                    ),
                  ),
                if (showAttendanceButton) ...[
                  if (hasLocation) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTimeValid ? Colors.teal : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _isMarkingAttendance ? null : () {
                        if (isTooEarly) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("You can only mark attendance after the exact meeting start time."),
                            backgroundColor: Colors.orange,
                          ));
                        } else if (isTooLate) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("The attendance window for this meeting has closed."),
                            backgroundColor: Colors.red,
                          ));
                        } else {
                          _markAttendance(meeting);
                        }
                      },
                      icon: _isMarkingAttendance 
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(isTimeValid ? Icons.location_on : Icons.lock_clock, color: Colors.white, size: 18),
                      label: Text(
                        isTooEarly ? "Not Started" : (isTooLate ? "Ended" : "Mark Attendance"), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// READ-ONLY MAP VIEWER FOR MEMBERS
// ==========================================
class ViewMeetingMapPage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String venueName;

  const ViewMeetingMapPage({
    super.key, 
    required this.latitude, 
    required this.longitude, 
    required this.venueName
  });

  @override
  Widget build(BuildContext context) {
    final locationPoint = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(venueName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: locationPoint,
          initialZoom: 17.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.kshree.app', 
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: locationPoint,
                width: 60,
                height: 60,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on, 
                  color: Colors.red, 
                  size: 50,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}