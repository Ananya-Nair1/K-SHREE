import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ads_schedule_meeting_page.dart'; // The form page we created earlier
import 'ads_meeting_details_page.dart'; // The details/attendance page

class ADSMemberMeetingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSMemberMeetingsPage({super.key, required this.userData});

  @override
  State<ADSMemberMeetingsPage> createState() => _ADSMemberMeetingsPageState();
}

class _ADSMemberMeetingsPageState extends State<ADSMemberMeetingsPage> {
  final supabase = Supabase.instance.client;
  final Color adsBlue = const Color(0xFF2B6CB0); // Official ADS Theme Color
  
  bool _isLoadingUnits = true;
  List<String> _wardUnits = [];

  @override
  void initState() {
    super.initState();
    _fetchWardUnits();
  }

  // Fetch all unique unit numbers that belong to the Chairperson's ward
  Future<void> _fetchWardUnits() async {
    try {
      final String adsWard = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();
      final String adsPanchayat = widget.userData['panchayat']?.toString() ?? '';

      final response = await supabase
          .from('Registered_Members')
          .select('unit_number')
          .eq('ward', adsWard)
          .ilike('panchayat', adsPanchayat);

      final Set<String> units = {};
      for (var row in response) {
        if (row['unit_number'] != null) {
          units.add(row['unit_number'].toString());
        }
      }
      
      if (mounted) {
        setState(() {
          _wardUnits = units.toList();
          _isLoadingUnits = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching ward units: $e");
      if (mounted) {
        setState(() => _isLoadingUnits = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Manage Meetings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: adsBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingUnits
          ? Center(child: CircularProgressIndicator(color: adsBlue))
          : StreamBuilder<List<Map<String, dynamic>>>(
              // Fetch meetings in real-time, ordered by newest first
              stream: supabase
                  .from('meetings')
                  .stream(primaryKey: ['meet_id'])
                  .order('meeting_date', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: adsBlue));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No meetings scheduled in the database.", style: TextStyle(color: Colors.grey)));
                }

                // Filter: Show if it's an ADS-level meeting OR if it belongs to a unit in this ward
                final wardMeetings = snapshot.data!.where((meet) {
                  final String unit = meet['unit_name']?.toString() ?? '';
                  final String level = meet['meeting_level']?.toString() ?? '';
                  
                  return level == 'ADS_Level' || _wardUnits.contains(unit);
                }).toList();

                if (wardMeetings.isEmpty) {
                  return const Center(
                    child: Text("No meetings have been held or scheduled in your ward yet.", 
                      style: TextStyle(color: Colors.grey, fontSize: 15))
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wardMeetings.length,
                  itemBuilder: (context, index) {
                    final meet = wardMeetings[index];
                    return _buildMeetingCard(meet);
                  },
                );
              },
            ),
      
      // The Floating Action Button to schedule a new meeting
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: adsBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ADSScheduleMeetingPage(userData: widget.userData),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Card UI for individual meetings
  Widget _buildMeetingCard(Map<String, dynamic> meet) {
    final status = meet['status']?.toString().toUpperCase() ?? 'UPCOMING';
    final isAdsMeeting = meet['meeting_level'] == 'ADS_Level';
    final unitName = isAdsMeeting ? "ADS Level" : "Unit ${meet['unit_name']}";
    
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: adsBlue.withOpacity(0.1), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: adsBlue.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Open details & attendance page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ADSMeetingDetailsPage(meetingData: meet),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdsMeeting ? Colors.deepPurple.shade50 : adsBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            unitName,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: isAdsMeeting ? Colors.deepPurple : adsBlue
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: status == 'HELD' ? Colors.green : Colors.orange
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${meet['meeting_date']} at ${meet['meeting_time']}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meet['venue'] ?? 'No Venue',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: adsBlue),
            ],
          ),
        ),
      ),
    );
  }
}