import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CDSCalendarPage extends StatefulWidget {
  final String panchayat;
  const CDSCalendarPage({super.key, required this.panchayat});

  @override
  State<CDSCalendarPage> createState() => _CDSCalendarPageState();
}

class _CDSCalendarPageState extends State<CDSCalendarPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await supabase.from('panchayat_events').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'event_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'panchayat': widget.panchayat,
        'created_by': 'CDS_Chairperson',
      });

      if (mounted) {
        Navigator.pop(context);
        _titleController.clear();
        _descController.clear();
        setState(() {}); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event added to Panchayat Calendar!"), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      debugPrint("Error adding event: $e");
    }
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Schedule Panchayat Event", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Event Title"), validator: (v) => v!.isEmpty ? "Required" : null),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Details/Location"), maxLines: 2),
              const SizedBox(height: 15),
              ListTile(
                title: Text("Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}"),
                trailing: const Icon(Icons.calendar_month, color: Colors.teal),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(15)),
                  onPressed: _addEvent,
                  child: const Text("Post to Calendar", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Panchayat Calendar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddEventSheet,
        child: const Icon(Icons.add_task, color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('panchayat_events')
            .select()
            .eq('panchayat', widget.panchayat)
            .gte('event_date', DateFormat('yyyy-MM-dd').format(DateTime.now())) // Only future events
            .order('event_date', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final events = snapshot.data ?? [];
          if (events.isEmpty) return const Center(child: Text("No upcoming events scheduled."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final DateTime date = DateTime.parse(event['event_date']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('dd').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                        Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10, color: Colors.teal)),
                      ],
                    ),
                  ),
                  title: Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(event['description'] ?? ""),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}