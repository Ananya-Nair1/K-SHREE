import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ADSMemberMeetingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSMemberMeetingsPage({super.key, required this.userData});

  @override
  State<ADSMemberMeetingsPage> createState() => _MemberMeetingsPageState();
}

class _MemberMeetingsPageState extends State<ADSMemberMeetingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  final _memberHouseController = TextEditingController();
  final _meetLinkController = TextEditingController();
  
  String _adsMeetingTarget = 'ADS Members'; 
  
  String? _selectedVenue;
  final List<String> _venueOptions = [
    'Community Hall',
    'Panchayat Office',
    'Kudumbashree Office',
    'Unit Member House', 
    'Online / Google Meet',
  ];

  List<String> _selectedUnits = []; 
  
  final List<String> _nhgOptions = [
    'Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5', 'Unit 6'
  ];
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  bool get _isAds {
    final String designation = widget.userData['designation']?.toString().toUpperCase() ?? '';
    return designation.contains('ADS');
  }

  String _getMeetingLevel() {
    if (_isAds) return 'ADS_Level';
    return 'NHG_Level'; 
  }

  Future<void> _showMultiSelectDialog() async {
    List<String> tempSelected = List.from(_selectedUnits);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isAllSelected = tempSelected.length == _nhgOptions.length;

            return AlertDialog(
              title: const Text("Select Target NHGs", style: TextStyle(color: Color(0xFF2B6CB0), fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.only(top: 10),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      activeColor: const Color(0xFF2B6CB0),
                      title: const Text("Select All", style: TextStyle(fontWeight: FontWeight.bold)),
                      value: isAllSelected,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            tempSelected = List.from(_nhgOptions);
                          } else {
                            tempSelected.clear();
                          }
                        });
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _nhgOptions.length,
                        itemBuilder: (context, index) {
                          final unit = _nhgOptions[index];
                          return CheckboxListTile(
                            activeColor: const Color(0xFF4285F4),
                            title: Text(unit, style: const TextStyle(color: Color(0xFF4A5568))),
                            value: tempSelected.contains(unit),
                            onChanged: (bool? checked) {
                              setStateDialog(() {
                                if (checked == true) {
                                  tempSelected.add(unit);
                                } else {
                                  tempSelected.remove(unit);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4)),
                  onPressed: () {
                    setState(() {
                      _selectedUnits = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _generateMeetLink() {
    final mockCode = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    setState(() {
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

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields and select Date & Time")));
      return;
    }

    if (_isAds && _adsMeetingTarget == 'NHG Secretaries' && _selectedUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one NHG Unit")));
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
    final level = _getMeetingLevel();
    
    // Get creator ID for hiding self-notifications
    final String creatorId = (widget.userData['aadhar_number'] ?? widget.userData['member_id'])?.toString() ?? 'UNKNOWN';

    String finalVenue = _selectedVenue ?? '';
    if (_selectedVenue == 'Unit Member House') {
      finalVenue = 'Unit Member House - ${_memberHouseController.text.trim()}';
    } else if (_selectedVenue == 'Online / Google Meet') {
      finalVenue = 'Online - ${_meetLinkController.text.trim()}';
    }

    try {
      final existingMeeting = await Supabase.instance.client
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
            )
          );
        }
        setState(() => _isLoading = false);
        return; 
      }

      String finalReason = _reasonController.text.trim();
      if (_isAds && _adsMeetingTarget == 'NHG Secretaries') {
        finalReason = "$finalReason (Invited Units: ${_selectedUnits.join(', ')})";
      } else if (_isAds && _adsMeetingTarget == 'ADS Members') {
        finalReason = "$finalReason (ADS Internal Meeting)";
      }

      final Map<String, dynamic> meetingData = {
        'unit_name': widget.userData['unit_number'].toString(),
        'meeting_level': level,
        'meeting_date': formattedDate,
        'meeting_time': formattedTime,
        'venue': finalVenue, 
        'reason': finalReason, 
        'created_by': creatorId,
        'status': 'upcoming'
      };

      await Supabase.instance.client.from('meetings').insert(meetingData);

      // --- NOTIFICATION LOGIC ---
      try {
        List<Map<String, dynamic>> notificationsToInsert = [];

        final String creatorName = widget.userData['full_name'] ?? 'Authorized Official';
        final String creatorRole = widget.userData['designation'] ?? 'Kudumbashree';
        final String signature = "\n\nCalled by: $creatorName ($creatorRole)";

        if (_isAds) {
          if (_adsMeetingTarget == 'ADS Members') {
            notificationsToInsert.add({
              'unit_number': 'ALL_ADS', // Targeted correctly for the Notice Board filter
              'title': 'New ADS Meeting Scheduled',
              'message': 'A meeting has been scheduled on $formattedDate at ${_selectedTime!.format(context)}. Venue: $finalVenue.$signature',
              'is_urgent': false,
              'target_audience': 'ADS Members', 
              'created_by': creatorId, // <-- Added created_by
            });
          } else if (_adsMeetingTarget == 'NHG Secretaries') {
            List<String> cleanUnitNumbers = _selectedUnits.map((unit) {
              return unit.replaceAll(RegExp(r'[^0-9]'), ''); 
            }).toList();

            for (var unitNum in cleanUnitNumbers) {
              notificationsToInsert.add({
                'unit_number': unitNum,
                'title': 'ADS Meeting Invitation',
                'message': 'Your unit secretary is invited to a meeting on $formattedDate at ${_selectedTime!.format(context)}. Venue: $finalVenue.$signature',
                'is_urgent': false,
                'target_audience': 'Secretaries', 
                'created_by': creatorId, // <-- Added created_by
              });
            }
          }
        } else {
          notificationsToInsert.add({
            'unit_number': widget.userData['unit_number'].toString(),
            'title': 'New Unit Meeting Scheduled',
            'message': 'A meeting has been scheduled on $formattedDate at ${_selectedTime!.format(context)}. Venue: $finalVenue.$signature',
            'is_urgent': false,
            'target_audience': 'All Members', 
            'created_by': creatorId, // <-- Added created_by
          });
        }

        if (notificationsToInsert.isNotEmpty) {
          await Supabase.instance.client.from('unit_notifications').insert(notificationsToInsert);
        }
      } catch (notifyError) {
        print("Notification Error: $notifyError"); 
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Meeting Scheduled Successfully!"),
          backgroundColor: Colors.green,
        ));
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
    final primaryColor = _isAds ? const Color(0xFF4285F4) : Colors.teal;
    final bgColor = _isAds ? const Color(0xFFF0F9F4) : const Color(0xFFF4F7F6);

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        title: const Text('Schedule Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor, 
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
                          if (_isAds) ...[
                            _buildLabel(Icons.people_alt_outlined, "Meeting With"),
                            DropdownButtonFormField<String>(
                              value: _adsMeetingTarget,
                              decoration: _inputDecoration("Select meeting target"),
                              dropdownColor: Colors.white,
                              items: ['ADS Members', 'NHG Secretaries'].map((String target) {
                                return DropdownMenuItem<String>(
                                  value: target,
                                  child: Text(target, style: const TextStyle(color: Color(0xFF2C3E50))),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _adsMeetingTarget = newValue!;
                                  if (_adsMeetingTarget == 'ADS Members') {
                                    _selectedUnits.clear();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            if (_adsMeetingTarget == 'NHG Secretaries') ...[
                              _buildLabel(Icons.groups_outlined, "Target NHGs"),
                              InkWell(
                                onTap: _showMultiSelectDialog,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA), 
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedUnits.isEmpty 
                                            ? "Select NHG Units" 
                                            : _selectedUnits.length == _nhgOptions.length 
                                              ? "All Units Selected" 
                                              : _selectedUnits.join(', '),
                                          style: TextStyle(
                                            fontSize: 16, 
                                            color: _selectedUnits.isEmpty ? Colors.black38 : const Color(0xFF2C3E50),
                                            overflow: TextOverflow.ellipsis
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],

                          _buildLabel(Icons.location_on_outlined, "Venue"),
                          DropdownButtonFormField<String>(
                            value: _selectedVenue,
                            decoration: _inputDecoration("Select meeting venue"),
                            dropdownColor: Colors.white,
                            items: _venueOptions.map((String venue) {
                              return DropdownMenuItem<String>(
                                value: venue,
                                child: Text(venue, style: const TextStyle(color: Color(0xFF2C3E50))),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedVenue = newValue;
                                _memberHouseController.clear();
                                _meetLinkController.clear();
                              });
                            },
                            validator: (v) => v == null ? "Please select a venue" : null,
                          ),
                          const SizedBox(height: 20),

                          if (_selectedVenue == 'Unit Member House') ...[
                            _buildLabel(Icons.person_outline, "Member's Name"),
                            TextFormField(
                              controller: _memberHouseController,
                              decoration: _inputDecoration("Enter the house owner's name"),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 20),
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
                                      onPressed: _generateMeetLink,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.teal),
                                      tooltip: "Share Link",
                                      onPressed: _shareMeetLink,
                                    ),
                                  ],
                                )
                              ),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 20),
                          ],

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
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
                color: _isAds ? const Color(0xFFD6E4FF) : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isAds ? const Color(0xFFA3BFFA) : Colors.teal.withOpacity(0.3)),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Note: ", style: TextStyle(fontWeight: FontWeight.bold, color: _isAds ? const Color(0xFF2B6CB0) : Colors.teal)),
                    TextSpan(
                      text: _isAds 
                        ? (_adsMeetingTarget == 'NHG Secretaries' 
                            ? "Invited NHG Secretaries will receive a notification about this meeting."
                            : "All ADS Members will receive a notification about this meeting.")
                        : "All members of your unit will receive a notification about this meeting.", 
                      style: const TextStyle(color: Color(0xFF4A5568))
                    ),
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