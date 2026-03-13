import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:latlong2/latlong.dart';

import 'mark_attendance_screen.dart'; 
import 'map_picker_page.dart'; 

class MeetingManagementPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MeetingManagementPage({super.key, required this.userData});

  @override
  State<MeetingManagementPage> createState() => _MeetingManagementPageState();
}

class _MeetingManagementPageState extends State<MeetingManagementPage> {
  final supabase = Supabase.instance.client;

  DateTime _getMeetingDateTime(String dateStr, String timeStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      final timeParts = timeStr.split(':');
      return DateTime(date.year, date.month, date.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
    } catch (e) {
      return DateTime.now();
    }
  }

  void _showMeetingOptions(Map<String, dynamic> meet) {
    final meetDateTime = _getMeetingDateTime(meet['meeting_date'], meet['meeting_time']);
    final isPast = DateTime.now().isAfter(meetDateTime);
    final status = meet['status']?.toString().toUpperCase() ?? 'SCHEDULED';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Meeting Options", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        content: Text("Meeting on ${meet['meeting_date']} at ${meet['meeting_time']}\n\nVenue: ${meet['venue']}", style: const TextStyle(fontSize: 15)),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          if (!isPast && status == 'SCHEDULED') ...[
            // Button to update GPS when the Secretary arrives at the venue (if they skipped it before)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.my_location, color: Colors.white),
                onPressed: () { 
                  Navigator.pop(ctx); 
                  _updateVenueGPS(meet['meet_id']); 
                },
                label: const Text("I'm at the Venue: Set GPS", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () { Navigator.pop(ctx); _cancelMeeting(meet['meet_id']); },
                child: const Text("Cancel Meeting", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
          if (isPast && status != 'CANCELED')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MarkAttendanceScreen(meetId: meet['meet_id'], secretaryData: widget.userData)));
                },
                child: const Text("Manual Attendance Override", style: TextStyle(color: Colors.white)),
              ),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Future<void> _updateVenueGPS(String meetId) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching exact location...")));
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Permissions denied.");
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      await supabase.from('meetings').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }).eq('meet_id', meetId);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Venue GPS Location Locked! Members can now mark attendance."), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _cancelMeeting(String meetId) async {
    try {
      await supabase.from('meetings').update({'status': 'CANCELED'}).eq('meet_id', meetId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Canceled"), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Meetings Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleMeetingPage(userData: widget.userData))),
        label: const Text("Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('meetings').stream(primaryKey: ['meet_id']).eq('created_by', widget.userData['aadhar_number'].toString()).order('meeting_date', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          final meetings = snapshot.data!;
          
          if (meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No meetings scheduled yet.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final m = meetings[index];
              final isCanceled = m['status'] == 'CANCELED';
              final needsGps = m['latitude'] == null && !isCanceled; 
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: isCanceled ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.groups, color: isCanceled ? Colors.red : Colors.teal),
                  ),
                  title: Text("${m['meeting_date']} at ${m['meeting_time']}", style: TextStyle(fontWeight: FontWeight.bold, decoration: isCanceled ? TextDecoration.lineThrough : null)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Venue: ${m['venue']}", style: TextStyle(color: Colors.grey.shade700)),
                        if (needsGps) 
                          const Text("⚠️ GPS Not Set. Tap to set when at venue.", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.more_vert, color: Colors.grey),
                  onTap: () => _showMeetingOptions(m),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ScheduleMeetingPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ScheduleMeetingPage({super.key, required this.userData});

  @override
  State<ScheduleMeetingPage> createState() => _ScheduleMeetingPageState();
}

class _ScheduleMeetingPageState extends State<ScheduleMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  // Location Variables
  double? _finalLatitude;
  double? _finalLongitude;
  Position? _currentPositionCache; 
  bool _isLoading = false;
  String _locationStatus = "Location not set. Please pick an option below.";

  @override
  void initState() {
    super.initState();
    _fetchBackgroundGPS(); 
  }

  Future<void> _fetchBackgroundGPS() async {
    try {
      if (await Geolocator.isLocationServiceEnabled() && 
          await Geolocator.checkPermission() == LocationPermission.whileInUse) {
        _currentPositionCache = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      }
    } catch (e) {
      debugPrint("Background GPS failed: $e");
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locationStatus = "Fetching GPS...");
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Permissions denied.");
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPositionCache = position;
        _finalLatitude = position.latitude;
        _finalLongitude = position.longitude;
        _locationStatus = "📍 Set to Current Location";
      });
    } catch (e) {
      setState(() => _locationStatus = "Error: $e");
    }
  }

  Future<void> _pickOnMap() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(currentPosition: _currentPositionCache),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _finalLatitude = pickedLocation.latitude;
        _finalLongitude = pickedLocation.longitude;
        _locationStatus = "🗺️ Set via Map Pin";
      });
    }
  }

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields and select Date/Time.")));
       return;
    }

    if (_finalLatitude == null || _finalLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set the Venue Location.")));
      return;
    }

    final now = DateTime.now();
    final scheduledDT = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);

    if (scheduledDT.isBefore(now.add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting must be scheduled at least 30 mins from now.")));
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

    try {
      final existing = await Supabase.instance.client
          .from('meetings')
          .select()
          .eq('meeting_date', formattedDate)
          .eq('meeting_time', formattedTime)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A meeting is already scheduled for this date and time.")));
        setState(() => _isLoading = false);
        return;
      }

      await Supabase.instance.client.from('meetings').insert({
        'unit_name': widget.userData['unit_number'].toString(),
        'meeting_level': 'NHG',
        'meeting_date': formattedDate,
        'meeting_time': formattedTime,
        'venue': _venueController.text,
        'reason': _reasonController.text,
        'status': 'SCHEDULED',
        'created_by': widget.userData['aadhar_number'].toString(),
        'latitude': _finalLatitude,   
        'longitude': _finalLongitude, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Meeting Scheduled Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Schedule Meeting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Meeting Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _venueController, 
                decoration: InputDecoration(
                  labelText: "Venue Name/Address",
                  prefixIcon: const Icon(Icons.location_city, color: Colors.teal),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) => value!.isEmpty ? "Venue is required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController, 
                decoration: InputDecoration(
                  labelText: "Agenda / Reason",
                  prefixIcon: const Icon(Icons.topic, color: Colors.teal),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? "Agenda is required" : null,
              ),
              const SizedBox(height: 24),

              const Text("Date & Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_selectedDate == null ? "Select Date" : DateFormat('dd-MM-yyyy').format(_selectedDate!), style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black87, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_selectedTime == null ? "Select Time" : _selectedTime!.format(context), style: TextStyle(color: _selectedTime == null ? Colors.grey : Colors.black87, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              const Text("Venue Coordinates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 8),

              // Location Status Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _finalLatitude != null ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _finalLatitude != null ? Colors.green.shade200 : Colors.orange.shade200),
                ),
                child: Text(
                  _locationStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _finalLatitude != null ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              // Location Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text("Use Current GPS", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickOnMap,
                      icon: const Icon(Icons.map, size: 18, color: Colors.white),
                      label: const Text("Pick on Map", style: TextStyle(color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading || _finalLatitude == null ? null : _scheduleMeeting, 
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Schedule Meeting", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}