import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ADSLoanRequestsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSLoanRequestsPage({super.key, required this.userData});

  @override
  State<ADSLoanRequestsPage> createState() => _ADSLoanRequestsPageState();
}

class _ADSLoanRequestsPageState extends State<ADSLoanRequestsPage> {
  final Color primaryColor = const Color(0xFF2B6CB0);
  final supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _isFetching = true;

  String? _selectedVenue;
  final List<String> _venueOptions = [
    'Community Hall',
    'Panchayat Office',
    'Kudumbashree Office',
    'Unit Member House',
    'Online / Google Meet',
  ];

  final _memberHouseController = TextEditingController();
  final _meetLinkController = TextEditingController();

  List<Map<String, dynamic>> loanRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  @override
  void dispose() {
    _memberHouseController.dispose();
    _meetLinkController.dispose();
    super.dispose();
  }

  // --- 1. FETCH LOANS ---
  Future<void> _fetchLoans() async {
    try {
      final response = await supabase
          .from('loans')
          .select('''
            id,
            member_id,
            loan_type,
            principal_amount,
            status,
            applied_date,
            remarks,
            Registered_Members (full_name, unit_number) 
          ''')
          .inFilter('status', ['Forwarded to ADS', 'ADS Meeting Scheduled', 'Forwarded to CDS', 'Rejected by ADS']) 
          .order('applied_date', ascending: false);

      setState(() {
        loanRequests = (response as List).map((row) {
          final memberInfo = row['Registered_Members'] ?? {};
          final dateObj = row['applied_date'] != null 
              ? DateTime.tryParse(row['applied_date']) ?? DateTime.now() 
              : DateTime.now();

          return {
            'db_id': row['id'], 
            'id': row['id'].toString().substring(0, 8).toUpperCase(), 
            'memberName': memberInfo['full_name'] ?? 'Unknown Member',
            'nhgName': memberInfo['unit_number']?.toString() ?? 'Unknown Unit',
            'amount': '₹${row['principal_amount']}',
            'purpose': '${row['loan_type']} ${row['remarks'] != null ? "- ${row['remarks']}" : ""}',
            'status': row['status'] ?? 'Pending',
            'dateApplied': DateFormat('dd-MMM-yyyy').format(dateObj),
          };
        }).toList();
        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading loans: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 2. APPROVE / REJECT LOAN ---
  Future<void> _updateLoanStatus(int index, String newStatus) async {
    setState(() => _isLoading = true);
    final request = loanRequests[index];

    try {
      await supabase
          .from('loans')
          .update({'status': newStatus})
          .eq('id', request['db_id']);

      setState(() {
        loanRequests[index]['status'] = newStatus;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'Forwarded to CDS' ? 'Loan Approved & Forwarded to CDS!' : 'Loan Rejected.'),
            backgroundColor: newStatus == 'Forwarded to CDS' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating loan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _generateMeetLink(StateSetter setStateDialog) {
    final mockCode = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    setStateDialog(() {
      _meetLinkController.text = "https://meet.google.com/mock-$mockCode";
    });
  }

  void _shareMeetLink() {
    if (_meetLinkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please generate a link first!")));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Share intent triggered for: ${_meetLinkController.text}")));
  }

  // --- 3. SCHEDULE MEETING ---
  Future<void> _scheduleMeetingAndNotify(
      int index, DateTime date, TimeOfDay time, String finalVenue) async {
    setState(() => _isLoading = true);
    final request = loanRequests[index];
    
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final String formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    final String displayDateTime = '${DateFormat('dd MMM yyyy').format(date)} at ${time.format(context)}';

    try {
      final existingMeeting = await supabase
          .from('meetings')
          .select('meet_id')
          .eq('meeting_date', formattedDate)
          .eq('meeting_time', formattedTime)
          .eq('venue', finalVenue);

      if (existingMeeting.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Time Conflict: A meeting is already scheduled here for the selected time."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
        setState(() => _isLoading = false);
        return; 
      }

      // Insert the new meeting
      await supabase.from('meetings').insert({
        'unit_name': widget.userData['unit_name'] ?? 'ADS Unit',
        'meeting_level': 'ADS',
        'meeting_date': formattedDate,
        'meeting_time': formattedTime,
        'venue': finalVenue,
        'reason': 'Loan Verification for ${request['memberName']} (Unit: ${request['nhgName']}) - Amount: ${request['amount']}',
        'status': 'Scheduled',
        'created_by': widget.userData['aadhar_number'].toString(), // Fixed Foreign Key
      });

      // Send the notification
      await supabase.from('unit_notifications').insert({
        'unit_number': widget.userData['unit_number'] ?? 'ALL_ADS', 
        'title': '🚨 Urgent: ADS Loan Verification Meeting',
        'message': 'An ADS meeting is scheduled on $displayDateTime at $finalVenue to verify a loan request for ${request['memberName']}. Attendance is mandatory.',
        'is_urgent': true,
      });

      // Update the status to 'ADS Meeting Scheduled'
      await supabase
          .from('loans')
          .update({'status': 'ADS Meeting Scheduled'})
          .eq('id', request['db_id']);

      setState(() {
        loanRequests[index]['status'] = 'ADS Meeting Scheduled';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting scheduled successfully! Pending final decision.'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showVerificationDialog(BuildContext context, int index) {
    final Map<String, dynamic> request = loanRequests[index];
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    _selectedVenue = null;
    _memberHouseController.clear();
    _meetLinkController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Schedule Verification Meeting', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Applicant: ${request['memberName']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Amount: ${request['amount']}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Colors.blueGrey),
                      title: Text(selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(selectedDate!)),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) setStateDialog(() => selectedDate = picked);
                      },
                    ),
                    
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Colors.blueGrey),
                      title: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context)),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) setStateDialog(() => selectedTime = picked);
                      },
                    ),

                    const SizedBox(height: 10),
                    
                    _buildLabel(Icons.location_on_outlined, "Venue"),
                    DropdownButtonFormField<String>(
                      value: _selectedVenue,
                      decoration: _inputDecoration("Select meeting venue"),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: _venueOptions.map((String venue) {
                        return DropdownMenuItem<String>(
                          value: venue,
                          child: Text(venue, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          _selectedVenue = newValue;
                          _memberHouseController.clear();
                          _meetLinkController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    if (_selectedVenue == 'Unit Member House') ...[
                      _buildLabel(Icons.person_outline, "Member's Name"),
                      TextFormField(
                        controller: _memberHouseController,
                        decoration: _inputDecoration("Enter the house owner's name"),
                      ),
                      const SizedBox(height: 15),
                    ],

                    if (_selectedVenue == 'Online / Google Meet') ...[
                      _buildLabel(Icons.link, "Meeting Link"),
                      TextFormField(
                        controller: _meetLinkController,
                        decoration: _inputDecoration("Enter or generate link").copyWith(
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.autorenew, color: Color(0xFF4285F4)),
                                tooltip: "Generate Link",
                                onPressed: () => _generateMeetLink(setStateDialog),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.teal),
                                tooltip: "Share Link",
                                onPressed: _shareMeetLink,
                              ),
                            ],
                          )
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (selectedDate == null || selectedTime == null || _selectedVenue == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select Date, Time, and Venue.'))
                      );
                      return;
                    }

                    String finalVenue = _selectedVenue!;
                    if (_selectedVenue == 'Unit Member House') {
                      if (_memberHouseController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the house owner\'s name.')));
                        return;
                      }
                      finalVenue = 'Unit Member House - ${_memberHouseController.text.trim()}';
                    } else if (_selectedVenue == 'Online / Google Meet') {
                      if (_meetLinkController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter or generate a meeting link.')));
                        return;
                      }
                      finalVenue = 'Online - ${_meetLinkController.text.trim()}';
                    }

                    Navigator.pop(dialogContext); // Close Dialog
                    _scheduleMeetingAndNotify(index, selectedDate!, selectedTime!, finalVenue);
                  },
                  child: const Text('Schedule Meeting', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- 4. DYNAMIC ACTION BUTTONS ---
  Widget _buildActionArea(Map<String, dynamic> request, int index) {
    final String status = request['status'];

    if (status == 'Forwarded to ADS') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.event_available),
          label: const Text('Schedule Meeting'),
          onPressed: () => _showVerificationDialog(context, index),
        ),
      );
    } else if (status == 'ADS Meeting Scheduled') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              onPressed: () => _updateLoanStatus(index, 'Rejected by ADS'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              onPressed: () => _updateLoanStatus(index, 'Forwarded to CDS'),
            ),
          ),
        ],
      );
    } else {
      final isApproved = status == 'Forwarded to CDS';
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isApproved ? Colors.green[50] : Colors.red[50],
            foregroundColor: isApproved ? Colors.green[700] : Colors.red[700],
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(isApproved ? Icons.check_circle : Icons.cancel),
          label: Text(isApproved ? 'Approved (Forwarded to CDS)' : 'Rejected'),
          onPressed: null, // Disabled
        ),
      );
    }
  }

  Widget _buildLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4A5568)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('NHG Loan Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetching 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : loanRequests.isEmpty
          ? const Center(child: Text("No pending loan requests.", style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: loanRequests.length,
                  itemBuilder: (context, index) {
                    final request = loanRequests[index];

                    Color statusColor = Colors.orange;
                    if (request['status'] == 'Forwarded to CDS') statusColor = Colors.green;
                    if (request['status'] == 'Rejected by ADS') statusColor = Colors.red;
                    if (request['status'] == 'ADS Meeting Scheduled') statusColor = Colors.teal;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: ${request['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request['status'],
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  child: Icon(Icons.person, color: primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(request['memberName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text('Unit No: ${request['nhgName']}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(request['amount'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                                    Text(request['dateApplied'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Purpose: ${request['purpose']}', style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 16),
                            
                            _buildActionArea(request, index),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(child: CircularProgressIndicator(color: primaryColor)),
                  )
              ],
            ),
    );
  }
}