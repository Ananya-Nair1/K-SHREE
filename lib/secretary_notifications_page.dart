import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SecretaryNotificationsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SecretaryNotificationsPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<SecretaryNotificationsPage> createState() => _SecretaryNotificationsPageState();
}

class _SecretaryNotificationsPageState extends State<SecretaryNotificationsPage> {
  final supabase = Supabase.instance.client;

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _deleteNotification(String id) async {
    // Optional: Show a confirmation dialog before deleting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Announcement?"),
        content: const Text("Are you sure you want to delete this notification? Members will no longer see it."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('unit_notifications').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Announcement deleted"), backgroundColor: Colors.orange),
          );
          setState(() {}); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String unitNumber = widget.userData['unit_number']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Manage Announcements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text("New Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateNotificationPage(unitNumber: unitNumber)),
          );
          setState(() {}); // Refresh the list when returning
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Using a stream so it updates automatically
        stream: supabase
            .from('unit_notifications')
            .stream(primaryKey: ['id'])
            .eq('unit_number', unitNumber)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No announcements made yet.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Tap 'New Update' to notify your members.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // Bottom padding for FAB
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final bool isUrgent = item['is_urgent']?.toString() == 'true' || item['is_urgent'] == true;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: isUrgent ? Colors.red.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
                            child: Icon(
                              isUrgent ? Icons.priority_high : Icons.campaign,
                              color: isUrgent ? Colors.red : Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: Text("To: ${item['target_audience'] ?? 'All Members'}", style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteNotification(item['id'].toString()),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(item['message'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Sent: ${_formatDate(item['created_at'].toString())}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (isUrgent)
                            const Text("URGENT", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- CREATE NOTIFICATION PAGE ---

class CreateNotificationPage extends StatefulWidget {
  final String unitNumber;

  const CreateNotificationPage({Key? key, required this.unitNumber}) : super(key: key);

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isUrgent = false;
  String _targetAudience = 'All Members';
  bool _isLoading = false;

  final List<String> _audienceOptions = ['All Members', 'Executive Committee', 'Loan Beneficiaries'];

  Future<void> _publishNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('unit_notifications').insert({
        'unit_number': widget.unitNumber,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'is_urgent': _isUrgent,
        'target_audience': _targetAudience,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Announcement published successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Announcement", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Announcement Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 20),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title (e.g., Monthly Meeting Update)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 16),
              
              // Message Field
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Detailed Message",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60.0), // Aligns icon to top
                    child: Icon(Icons.message),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? "Please enter the message" : null,
              ),
              const SizedBox(height: 24),
              
              // Settings Section
              const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),

              // Target Audience Dropdown
              DropdownButtonFormField<String>(
                value: _targetAudience,
                decoration: InputDecoration(
                  labelText: "Target Audience",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.groups),
                ),
                items: _audienceOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) setState(() => _targetAudience = newValue);
                },
              ),
              const SizedBox(height: 16),

              // Urgent Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text("Mark as Urgent", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Highlights this message in red for members"),
                  value: _isUrgent,
                  activeColor: Colors.redAccent,
                  secondary: Icon(Icons.priority_high, color: _isUrgent ? Colors.redAccent : Colors.grey),
                  onChanged: (bool value) {
                    setState(() => _isUrgent = value);
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.send, color: Colors.white),
                  label: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Publish Announcement", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isLoading ? null : _publishNotification,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}