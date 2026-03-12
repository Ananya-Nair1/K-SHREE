import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'mark_attendance_screen.dart'; //

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
        title: const Text("Meeting Options"),
        content: Text("Meeting on ${meet['meeting_date']} at ${meet['meeting_time']}\nVenue: ${meet['venue']}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          if (!isPast && status == 'SCHEDULED')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () { Navigator.pop(ctx); _cancelMeeting(meet['meet_id']); },
              child: const Text("Cancel Meeting", style: TextStyle(color: Colors.white)),
            ),
          if (isPast && status != 'CANCELED')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (context) => MarkAttendanceScreen(meetId: meet['meet_id'], secretaryData: widget.userData)));
              },
              child: const Text("Mark Attendance", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _cancelMeeting(String meetId) async {
    try {
      await supabase.from('meetings').update({'status': 'CANCELED'}).eq('meet_id', meetId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Canceled")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meetings Hub"), backgroundColor: const Color(0xFF4285F4)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleMeetingPage(userData: widget.userData))),
        label: const Text("Schedule"),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('meetings').stream(primaryKey: ['meet_id']).eq('created_by', widget.userData['aadhar_number'].toString()).order('meeting_date', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final meetings = snapshot.data!;
          return ListView.builder(
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final m = meetings[index];
              return Card(
                child: ListTile(
                  title: Text("${m['meeting_date']} at ${m['meeting_time']}"),
                  subtitle: Text("Venue: ${m['venue']}"),
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
  bool _isLoading = false;

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) return;

    final now = DateTime.now();
    final scheduledDT = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);

    // Condition 1: Must be 30 mins different from current time
    if (scheduledDT.isBefore(now.add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting must be scheduled at least 30 minutes from now.")));
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

    try {
      // Condition 2: Check for duplicate meeting at same date/time
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Scheduled!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Meeting")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _venueController, decoration: const InputDecoration(labelText: "Venue")),
              ListTile(
                title: Text(_selectedDate == null ? "Select Date" : DateFormat('dd-MM-yyyy').format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              ListTile(
                title: Text(_selectedTime == null ? "Select Time" : _selectedTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() => _selectedTime = time);
                },
              ),
              TextFormField(controller: _reasonController, decoration: const InputDecoration(labelText: "Reason"), maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _isLoading ? null : _scheduleMeeting, child: _isLoading ? const CircularProgressIndicator() : const Text("Schedule")),
            ],
          ),
        ),
      ),
    );
  }
}