import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- 1. MEETINGS HUB (View existing & Button to schedule new) ---
class MeetingManagementScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MeetingManagementScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meetings Hub", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Fetches meetings created by this specific secretary using their aadhar_number
        future: supabase.from('meetings').select().eq('created_by', userData['aadhar_number'].toString()).order('meeting_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final meetings = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meet = meetings[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.calendar_today, color: Colors.white, size: 20)),
                  title: Text("${meet['meeting_date']} at ${meet['meeting_time']}"),
                  subtitle: Text("Venue: ${meet['venue']}\nReason: ${meet['reason']}"),
                  trailing: Text(meet['status'].toString().toUpperCase(), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Schedule", style: TextStyle(color: Colors.white)),
        onPressed: () { 
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ScheduleMeetingScreen(userData: userData)
            )
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
  final _venueController = TextEditingController();
  final _reasonController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  String _getMeetingLevel(String designation) {
    if (designation.contains('NHG')) return 'NHG_Level';
    if (designation.contains('ADS')) return 'ADS_Level';
    if (designation.contains('CDS')) return 'CDS_Level';
    return 'NHG_Level'; 
  }

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields and select Date & Time")));
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
    
    final level = _getMeetingLevel(widget.userData['designation'] ?? '');

    try {
      await Supabase.instance.client.from('meetings').insert({
        'unit_name': widget.userData['unit_number'].toString(),
        'meeting_level': level,
        'meeting_date': formattedDate,
        'meeting_time': formattedTime,
        'venue': _venueController.text.trim(),
        'reason': _reasonController.text.trim(),
        'created_by': widget.userData['aadhar_number'].toString(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Scheduled Successfully!")));
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
    final String unitName = widget.userData['unit_number']?.toString() ?? 'Unit Name Not Found';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F6), 
      appBar: AppBar(
        title: const Text('Schedule Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4285F4), 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F8FB),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                      ),
                      child: const Text("Meeting Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(Icons.description_outlined, "Unit Name"),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
                            child: Text(unitName, style: const TextStyle(color: Colors.black54, fontSize: 16)),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(Icons.location_on_outlined, "Venue"),
                          TextFormField(
                            controller: _venueController,
                            decoration: _inputDecoration("Enter meeting venue"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(Icons.calendar_today_outlined, "Date"),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (date != null) setState(() => _selectedDate = date);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_selectedDate == null ? "dd-mm-yyyy" : "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}", style: const TextStyle(fontSize: 16)),
                                  const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(Icons.access_time, "Time"),
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (time != null) setState(() => _selectedTime = time);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_selectedTime == null ? "--:--" : _selectedTime!.format(context), style: const TextStyle(fontSize: 16)),
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text("Reason for Meeting", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _reasonController,
                            maxLines: 3,
                            decoration: _inputDecoration("Enter the purpose of this meeting"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isLoading ? null : _scheduleMeeting,
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Schedule Meeting", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Note: ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    TextSpan(text: "Once scheduled, all members of your unit will receive a notification about this meeting.", style: TextStyle(color: Color(0xFF455A64))),
                  ]
                )
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4A5568)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }
}