import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'mark_attendance_screen.dart';
import 'map_picker_page.dart'; // Ensure this matches your free OpenStreetMap file

// --- 1. MEETINGS HUB (Main Screen) ---
class MeetingManagementPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MeetingManagementPage({super.key, required this.userData});

  @override
  State<MeetingManagementPage> createState() => _MeetingManagementPageState();
}

class _MeetingManagementPageState extends State<MeetingManagementPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Manage Meetings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => ScheduleMeetingScreen(userData: widget.userData))
        ),
        label: const Text("Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('meetings')
            .stream(primaryKey: ['meet_id'])
            .eq('unit_name', widget.userData['unit_number'].toString())
            .order('meeting_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) return const Center(child: Text("No meetings scheduled yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final m = meetings[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => MarkAttendanceScreen(meetId: m['meet_id'].toString(), secretaryData: widget.userData)
                  )),
                  title: Text("${m['meeting_date']} at ${m['meeting_time']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Venue: ${m['venue']}\nStatus: ${m['status']}"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 2. SCHEDULE MEETING SCREEN ---
class ScheduleMeetingScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ScheduleMeetingScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otherVenueController = TextEditingController();
  final _reasonController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedVenue;
  List<Map<String, dynamic>> _savedVenues = [];
  bool _isLoading = false;
  bool _isFetchingGPS = false; // Tracks GPS loading state
  
  // Coordinates picked from map or GPS
  double? _pickedLat;
  double? _pickedLon;

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    final unit = widget.userData['unit_number'].toString();
    final data = await supabase.from('saved_venues').select().eq('unit_number', unit);
    setState(() {
      _savedVenues = List<Map<String, dynamic>>.from(data);
      _savedVenues.add({'name': 'Other', 'latitude': null, 'longitude': null});
    });
  }

  // --- NEW: Fetch Current GPS Location Method ---
  Future<void> _fetchCurrentGPS() async {
    setState(() => _isFetchingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Please enable GPS in phone settings.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Location permission denied.");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _pickedLat = pos.latitude;
        _pickedLon = pos.longitude;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Current Location Captured!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null || _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details!")));
      return;
    }

    // Enforce minimum 30-minute notice
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final minAllowed = DateTime.now().add(const Duration(minutes: 30));
    if (selectedDateTime.isBefore(minAllowed)) {
      final earliest = DateFormat('dd MMM yyyy, hh:mm a').format(minAllowed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Meetings must be scheduled at least 30 minutes in advance. Earliest possible time: $earliest"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? finalLat;
      double? finalLon;
      String finalVenueName = _selectedVenue!;

      if (_selectedVenue == 'Other') {
        finalVenueName = _otherVenueController.text.trim();
        finalLat = _pickedLat;
        finalLon = _pickedLon;

        // Auto-save this new venue to the unit's list
        if (finalLat != null) {
          await supabase.from('saved_venues').insert({
            'unit_number': widget.userData['unit_number'].toString(),
            'name': finalVenueName,
            'latitude': finalLat,
            'longitude': finalLon,
          });
        }
      } else {
        final venueData = _savedVenues.firstWhere((v) => v['name'] == _selectedVenue);
        finalLat = venueData['latitude'];
        finalLon = venueData['longitude'];
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

      await supabase.from('meetings').insert({
        'panchayat': widget.userData['panchayat']?.toString() ?? '',
        'ward': (widget.userData['ward'] ?? widget.userData['ward_number']).toString(),
        'unit_name': widget.userData['unit_number'].toString(),
        'meeting_level': 'NHG',
        'meeting_date': formattedDate,
        'meeting_time': formattedTime,
        'venue': finalVenueName,
        'latitude': finalLat,
        'longitude': finalLon,
        'reason': _reasonController.text.trim(),
        'status': 'SCHEDULED',
        'created_by': widget.userData['aadhar_number'].toString(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Meeting'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Venue Selection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedVenue,
                decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                items: _savedVenues.map((v) => DropdownMenuItem(value: v['name'] as String, child: Text(v['name']))).toList(),
                onChanged: (val) => setState(() => _selectedVenue = val),
              ),
              
              if (_selectedVenue == 'Other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherVenueController, 
                  decoration: const InputDecoration(labelText: "New Venue Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.add_business))
                ),
                const SizedBox(height: 12),
                
                // --- FIXED: Dual Location Buttons ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MapPickerPage()),
                          );
                          if (result != null) {
                            setState(() {
                              _pickedLat = result['latitude'];
                              _pickedLon = result['longitude'];
                            });
                          }
                        },
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text("Pick on Map", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isFetchingGPS ? null : _fetchCurrentGPS,
                        icon: _isFetchingGPS 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.my_location, size: 18, color: Colors.white),
                        label: const Text("Current GPS", style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                      ),
                    ),
                  ],
                ),
                
                // --- Location Status Indicator ---
                if (_pickedLat != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text("Location Locked ✅", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
              
              const SizedBox(height: 20),
              const Text("Meeting Agenda", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonController, 
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.subject))
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_selectedDate == null ? "Date" : DateFormat('dd MMM').format(_selectedDate!)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (t != null) setState(() => _selectedTime = t);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime == null ? "Time" : _selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                  onPressed: _isLoading ? null : _scheduleMeeting,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Schedule Meeting", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}