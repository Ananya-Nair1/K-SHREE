import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'mark_attendance_screen.dart';

class ScheduleMeetingPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ScheduleMeetingPage({super.key, required this.userData});

  @override
  State<ScheduleMeetingPage> createState() => _ScheduleMeetingPageState();
}

class _ScheduleMeetingPageState extends State<ScheduleMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final _otherVenueController = TextEditingController();
  final _reasonController = TextEditingController();
  final supabase = Supabase.instance.client;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // Venue Logic
  String? _selectedVenue;
  List<Map<String, dynamic>> _savedVenues = [];

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    try {
      final unit = widget.userData['unit_number'].toString();
      final data = await supabase
          .from('saved_venues')
          .select()
          .eq('unit_number', unit);

      setState(() {
        _savedVenues = List<Map<String, dynamic>>.from(data);
        // Add the hardcoded "Other" option at the end
        _savedVenues.add({'name': 'Other', 'latitude': null, 'longitude': null});
      });
    } catch (e) {
      debugPrint("Error fetching venues: $e");
    }
  }

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null || _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields.")));
      return;
    }

    // --- STRICT 30-MINUTE TIME GAP CHECK ---
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final now = DateTime.now();
    final minAllowed = now.add(const Duration(minutes: 30));

    if (selectedDateTime.isBefore(minAllowed)) {
      final earliest = DateFormat('dd MMM yyyy, hh:mm a').format(minAllowed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Meetings must be scheduled at least 30 minutes in advance. Earliest possible time: $earliest"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }
    // --------------------------------------------

    setState(() => _isLoading = true);

    try {
      double? finalLat;
      double? finalLon;
      String finalVenueName = _selectedVenue!;

      if (_selectedVenue == 'Other') {
        finalVenueName = _otherVenueController.text.trim();
        Position pos = await _getCurrentLocation();
        finalLat = pos.latitude;
        finalLon = pos.longitude;

        // Auto-Save new venue for future use
        await supabase.from('saved_venues').insert({
          'unit_number': widget.userData['unit_number'].toString(),
          'name': finalVenueName,
          'latitude': finalLat,
          'longitude': finalLon,
        });
      } else {
        final venueData = _savedVenues.firstWhere((v) => v['name'] == _selectedVenue);
        finalLat = venueData['latitude'];
        finalLon = venueData['longitude'];
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

      // 1. Schedule the meeting
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
        'reason': _reasonController.text,
        'status': 'SCHEDULED',
        'created_by': widget.userData['aadhar_number'].toString(),
      });

      // 2. Auto-Send Notification to unit_notifications table
      try {
        // --- NEW: Convert Ward to Integer safely ---
        int? wardInt = int.tryParse(widget.userData['ward']?.toString() ?? widget.userData['ward_number']?.toString() ?? '');

        await supabase.from('unit_notifications').insert({
          'title': '📅 New Meeting Scheduled',
          'message': 'A new NHG meeting is set for $formattedDate at ${_selectedTime!.format(context)}.\nVenue: $finalVenueName\nAgenda: ${_reasonController.text}',
          'unit_number': widget.userData['unit_number'].toString(),
          'ward': wardInt, // <--- FIXED: Now safely passing an integer instead of a string!
          'panchayat': widget.userData['panchayat']?.toString() ?? '',
          'created_at': DateTime.now().toIso8601String(), 
          'target_audience': 'All Members',              
          'is_urgent': false 
        });
      } catch (notifyError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Meeting saved, but notification failed: $notifyError"), 
            backgroundColor: Colors.red
          ));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Scheduled! Members notified."), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  } // <-- End of _scheduleMeeting function

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Location permissions are denied';
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Schedule Meeting", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _savedVenues.isEmpty 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Venue Selection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedVenue,
                decoration: InputDecoration(
                  labelText: "Select Venue",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: _savedVenues.map((v) => DropdownMenuItem(value: v['name'] as String, child: Text(v['name']))).toList(),
                onChanged: (val) => setState(() => _selectedVenue = val),
              ),

              if (_selectedVenue == 'Other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherVenueController,
                  decoration: InputDecoration(
                    labelText: "New Venue Name",
                    hintText: "e.g. Unit Hall / Member's House",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.add_location_alt),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? "Please name the new location" : null,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 4),
                  child: Text("📍 Note: Current GPS will be saved for this venue name.", style: TextStyle(fontSize: 11, color: Colors.indigo, fontStyle: FontStyle.italic)),
                ),
              ],

              const SizedBox(height: 24),
              const Text("Meeting Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController, 
                decoration: InputDecoration(labelText: "Agenda / Reason", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.subject)),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? "Required" : null,
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
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.indigo, size: 18),
                            const SizedBox(width: 8),
                            Text(_selectedDate == null ? "Date" : DateFormat('dd MMM').format(_selectedDate!), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.indigo, size: 18),
                            const SizedBox(width: 8),
                            Text(_selectedTime == null ? "Time" : _selectedTime!.format(context), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _scheduleMeeting, 
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Schedule Meeting", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}