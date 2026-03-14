import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ADSTrainingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ADSTrainingsPage({super.key, required this.userData});

  @override
  State<ADSTrainingsPage> createState() => _ADSTrainingsPageState();
}

class _ADSTrainingsPageState extends State<ADSTrainingsPage> {
  final supabase = Supabase.instance.client;
  Set<int> _registeredTrainingIds = {};
  bool _isLoadingRegistrations = true;

  @override
  void initState() {
    super.initState();
    _fetchMyRegistrations();
  }

  // Fetch the trainings this specific user has already registered for
  Future<void> _fetchMyRegistrations() async {
    try {
      final response = await supabase
          .from('training_registrations')
          .select('training_id')
          .eq('member_aadhar', widget.userData['aadhar_number']);
      
      if (mounted) {
        setState(() {
          _registeredTrainingIds = response.map<int>((r) => r['training_id'] as int).toSet();
          _isLoadingRegistrations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRegistrations = false);
    }
  }

  // Register for a training
  Future<void> _registerForTraining(int trainingId) async {
    try {
      await supabase.from('training_registrations').insert({
        'training_id': trainingId,
        'member_aadhar': widget.userData['aadhar_number'],
      });

      if (mounted) {
        setState(() {
          _registeredTrainingIds.add(trainingId); // Update UI immediately
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Successfully registered for training!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not register: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Extract YouTube ID for thumbnail
  String getYoutubeThumbnail(String url) {
    final RegExp regExp = RegExp(r'(?<=watch\?v=|/videos/|embed\/|youtu.be\/|\/v\/|\/e\/|watch\?v%3D|watch\?feature=player_embedded&v=|%2Fvideos%2F|embed%\u200C\u200B2F|youtu.be%2F|\/v%2F)[^#\&\?\n]*');
    final match = regExp.firstMatch(url);
    if (match != null && match.group(0) != null) {
      return 'https://img.youtube.com/vi/${match.group(0)}/0.jpg';
    }
    return 'https://via.placeholder.com/200x120?text=Video';
  }

  Future<void> _launchYouTube(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open video.')));
    }
  }

  // --- ADD TRAINING BOTTOM SHEET ---
  void _showAddTrainingDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final linkController = TextEditingController();
    
    String trainingType = 'Live'; 
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    // Dropdown choices and default selected value for Category
    String selectedCategory = 'General Training';
    final List<String> categories = [
      'General Training',
      'Finance & Savings',
      'Agriculture & Farming',
      'Micro-Enterprise',
      'Health & Wellness',
      'Leadership & Management'
    ];

    // Dropdown choices and default selected value for Venue
    String selectedVenue = 'Panchayat Office';
    final List<String> venues = [
      'Panchayat Office',
      'Kudumbashree Office',
      'Community Hall',
      'CDS Main Hall',
      'Online',
      'Other'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add New Training", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 15),
                  
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Live', label: Text('Live Session'), icon: Icon(Icons.event)),
                      ButtonSegment(value: 'Video', label: Text('Video Resource'), icon: Icon(Icons.video_library)),
                    ],
                    selected: {trainingType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setSheetState(() => trainingType = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 20),

                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Program Title", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  if (trainingType == 'Video') ...[
                    TextField(controller: linkController, decoration: const InputDecoration(labelText: "YouTube Link", border: OutlineInputBorder())),
                  ] else ...[
                    TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    
                    // Venue Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Venue", border: OutlineInputBorder()),
                      value: selectedVenue,
                      items: venues.map((venue) {
                        return DropdownMenuItem(value: venue, child: Text(venue));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedVenue = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (date != null) setSheetState(() => selectedDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder()),
                              child: Text(selectedDate == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (time != null) setSheetState(() => selectedTime = time);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "Time", border: OutlineInputBorder()),
                              child: Text(selectedTime == null ? "Select Time" : selectedTime!.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        if (titleController.text.isEmpty) return;
                        
                        try {
                          await supabase.from('trainings').insert({
                            'program_name': titleController.text,
                            'training_type': trainingType,
                            'category': selectedCategory,
                            'description': trainingType == 'Live' ? descController.text : null,
                            'video_link': trainingType == 'Video' ? linkController.text : null,
                            'venue': trainingType == 'Live' ? selectedVenue : 'YouTube', // Send 'YouTube' instead of null
                            'training_date': selectedDate?.toIso8601String(),
                            'training_time': selectedTime?.format(context),
                            'ward': (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '',
                            'panchayat': widget.userData['panchayat']?.toString() ?? '',
                            'district': widget.userData['district']?.toString() ?? '',
                            'creator_aadhar': widget.userData['aadhar_number'],
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Training Published!"), backgroundColor: Colors.teal));
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                        }
                      },
                      child: const Text("Publish Training", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userWard = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '';
    final String userPanchayat = widget.userData['panchayat']?.toString() ?? '';
    final String userDistrict = widget.userData['district']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Skill Trainings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingRegistrations 
        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
        : StreamBuilder<List<Map<String, dynamic>>>(
        // Fetch trainings matching this ADS's ward, panchayat, and district
        stream: supabase.from('trainings')
            .select()
            .eq('ward', userWard)
            .ilike('panchayat', userPanchayat)
            .ilike('district', userDistrict)
            .order('created_at', ascending: false)
            .asStream()
            .map((data) => List<Map<String, dynamic>>.from(data)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          
          final allTrainings = snapshot.data ?? [];
          final videos = allTrainings.where((t) => t['training_type'] == 'Video').toList();
          final liveSessions = allTrainings.where((t) => t['training_type'] == 'Live' || t['training_type'] == null).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- VIDEO SECTION ---
                if (videos.isNotEmpty) Container(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text("Video Resources", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180, 
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final video = videos[index];
                            final mappedVideo = {
                              'title': video['program_name']?.toString() ?? 'Video',
                              'url': video['video_link']?.toString() ?? '',
                              'thumbnail': getYoutubeThumbnail(video['video_link']?.toString() ?? ''),
                            };
                            return _buildVideoCard(mappedVideo);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Upcoming Live Sessions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),

                // --- LIVE SESSIONS SECTION ---
                if (liveSessions.isEmpty) 
                   _buildEmptyState("No live training sessions scheduled right now.")
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: liveSessions.length,
                    itemBuilder: (context, index) {
                      return _buildTrainingCard(liveSessions[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
      // --- FAB TO ADD NEW TRAINING ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddTrainingDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildVideoCard(Map<String, String> video) {
    return GestureDetector(
      onTap: () => _launchYouTube(video['url']!),
      child: Container(
        width: 200, 
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(image: NetworkImage(video['thumbnail']!), fit: BoxFit.cover),
                ),
                child: Center(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                video['title']!,
                style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final int trainingId = training['id'];
    final bool isRegistered = _registeredTrainingIds.contains(trainingId);

    String formattedDate = 'TBA';
    try {
      if (training['training_date'] != null) {
        final date = DateTime.parse(training['training_date']);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      }
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.model_training, color: Colors.teal.shade700, size: 28), 
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        training['program_name'] ?? 'Skill Development Workshop', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        training['category'] ?? 'General Training', 
                        style: const TextStyle(color: Colors.grey, fontSize: 13)
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              training['description'] ?? 'Join this session to improve your skills.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.teal), 
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(training['training_time'] ?? '10:00 AM', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(training['venue'] ?? 'CDS Main Hall', style: const TextStyle(color: Colors.blueGrey))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRegistered ? Colors.grey.shade400 : Colors.teal, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isRegistered ? null : () => _registerForTraining(trainingId),
                child: Text(
                  isRegistered ? "✅ Registered" : "Register for Training", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ),
          ],
        ),
      ),
    );
  }
}