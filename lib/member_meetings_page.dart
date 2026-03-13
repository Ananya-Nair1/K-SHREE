import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; 

class MemberMeetingsPage extends StatefulWidget {
  final String unitNumber; 
  final String memberId; // Tracks who is attending

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

  // --- Geo-Fenced Attendance Logic ---
  Future<void> _markAttendance(Map<String, dynamic> meeting) async {
    setState(() => _isMarkingAttendance = true);

    try {
      // 1. Check if latitude and longitude exist for this meeting
      if (meeting['latitude'] == null || meeting['longitude'] == null) {
        throw Exception("Meeting location not set by Secretary yet.");
      }

      final targetLat = double.parse(meeting['latitude'].toString());
      final targetLon = double.parse(meeting['longitude'].toString());

      // 2. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // 3. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 4. Calculate Distance in Meters
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLon,
      );

      // 5. Enforce the 5-meter rule
      if (distanceInMeters > 5) {
        throw Exception("You are ${distanceInMeters.toStringAsFixed(1)} meters away. You must be within 5 meters of the venue.");
      }

      // 6. Check if already marked
      final existing = await supabase
          .from('attendance')
          .select()
          .eq('meet_id', meeting['meet_id']) 
          .eq('aadhar_number', widget.memberId) 
          .maybeSingle();

      if (existing != null) {
        throw Exception("You have already marked attendance for this meeting.");
      }

      // 7. Save to Database 
      await supabase.from('attendance').insert({
        'meet_id': meeting['meet_id'], 
        'aadhar_number': widget.memberId,
        'status': 'Present',
        'created_at': DateTime.now().toIso8601String(), 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Attendance marked successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
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
        title: const Text('Upcoming Meetings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: supabase
            .from('meetings')
            .select()
            .eq('unit_name', widget.unitNumber) 
            .order('meeting_date', ascending: true), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final meetings = snapshot.data as List<dynamic>? ?? [];

          if (meetings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No upcoming meetings scheduled.", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _buildMeetingCard(meeting);
            },
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final isScheduled = meeting['status'] == 'SCHEDULED';
    final hasGps = meeting['latitude'] != null && meeting['longitude'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting['meeting_level'] ?? 'NHG Meeting', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 4),
                      Text(meeting['reason'] ?? 'No specific agenda provided', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                if (meeting['status'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isScheduled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      meeting['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: isScheduled ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Text(meeting['meeting_date'] ?? 'TBA', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(meeting['meeting_time'] ?? 'TBA', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(meeting['venue'] ?? 'Location TBA', style: const TextStyle(color: Colors.blueGrey))),
              ],
            ),
            
            // --- Attendance Button Section ---
            const SizedBox(height: 16),
            if (isScheduled && hasGps) 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  icon: _isMarkingAttendance 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.how_to_reg, color: Colors.white),
                  label: Text(_isMarkingAttendance ? "Checking Location..." : "Mark Attendance", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _isMarkingAttendance ? null : () => _markAttendance(meeting),
                ),
              )
            else if (isScheduled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: const Text("📍 Location pending. Attendance will open when the venue is set.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}