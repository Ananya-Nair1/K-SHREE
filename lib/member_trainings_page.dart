import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberTrainingsPage extends StatefulWidget {
  final Map<String, dynamic> userData; // Pass this from your Dashboard

  const MemberTrainingsPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<MemberTrainingsPage> createState() => _MemberTrainingsPageState();
}

class _MemberTrainingsPageState extends State<MemberTrainingsPage> {
  final supabase = Supabase.instance.client;
  Set<int> _registeredTrainingIds = {};
  bool _isLoadingRegistrations = true;

  // Mock list of YouTube Training Videos (UI preserved as requested)
  final List<Map<String, String>> youtubeVideos = [
    {
      "title": "Kudumbashree Micro Enterprise Training",
      "thumbnail": "https://img.youtube.com/vi/q_7zZ5Kz5K0/0.jpg",
      "url": "https://www.youtube.com/watch?v=q_7zZ5Kz5K0"
    },
    {
      "title": "Leadership & NHG Management",
      "thumbnail": "https://img.youtube.com/vi/aZ3xW1s9Pqw/0.jpg",
      "url": "https://www.youtube.com/watch?v=aZ3xW1s9Pqw"
    },
    {
      "title": "Financial Literacy for Women",
      "thumbnail": "https://img.youtube.com/vi/yL1Z2rT2e5o/0.jpg",
      "url": "https://www.youtube.com/watch?v=yL1Z2rT2e5o"
    },
    {
      "title": "Organic Farming Techniques",
      "thumbnail": "https://img.youtube.com/vi/9F_y7jL8eMw/0.jpg",
      "url": "https://www.youtube.com/watch?v=9F_y7jL8eMw"
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyRegistrations();
  }

  // Fetch the trainings this specific member has already registered for
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

  // Handle Training Registration
  Future<void> _registerForTraining(int trainingId) async {
    try {
      await supabase.from('training_registrations').insert({
        'training_id': trainingId,
        'member_aadhar': widget.userData['aadhar_number'],
      });

      if (mounted) {
        setState(() => _registeredTrainingIds.add(trainingId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Registered successfully!"), backgroundColor: Colors.green),
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

  Future<void> _launchYouTube(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open video.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userWard = (widget.userData['ward'] ?? widget.userData['ward_number'])?.toString() ?? '';
    final String userUnit = widget.userData['unit_number']?.toString() ?? '';
    final String userPanchayat = widget.userData['panchayat']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Skill Trainings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- VIDEO SECTION ---
            Container(
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
                      itemCount: youtubeVideos.length,
                      itemBuilder: (context, index) {
                        final video = youtubeVideos[index];
                        return _buildVideoCard(video);
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

            // --- DYNAMIC LIVE SESSIONS ---
            if (_isLoadingRegistrations)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.teal)))
            else
              StreamBuilder<List<Map<String, dynamic>>>(
                // FILTER: Current Ward + Current Panchayat + (This Unit OR Null Unit for ADS level)
                stream: supabase.from('trainings')
                    .select('*, Registered_Members(full_name, designation)')
                    .eq('ward', userWard)
                    .ilike('panchayat', userPanchayat)
                    .or('unit_number.eq.$userUnit,unit_number.is.null') 
                    .order('training_date', ascending: true)
                    .asStream()
                    .map((data) => List<Map<String, dynamic>>.from(data)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.teal)));
                  }
                  
                  final trainings = snapshot.data ?? [];

                  if (trainings.isEmpty) {
                    return _buildEmptyState("No live training sessions scheduled right now.");
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: trainings.length,
                    itemBuilder: (context, index) {
                      return _buildTrainingCard(trainings[index]);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

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
    
    // Logic to see who scheduled it
    final bool isWardLevel = training['unit_number'] == null;
    String schedulerName = isWardLevel ? 'ADS Chairperson' : 'Unit Secretary';
    if (training['Registered_Members'] != null) {
      schedulerName = training['Registered_Members']['full_name'] ?? schedulerName;
    }

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
                        training['program_name'] ?? 'Skill Workshop', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isWardLevel ? Colors.orange.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isWardLevel ? 'Ward' : 'Unit',
                              style: TextStyle(color: isWardLevel ? Colors.orange.shade800 : Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(training['category'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(training['description'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
            const Divider(height: 24),
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
                const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(training['venue'] ?? 'CDS Hall', style: const TextStyle(color: Colors.blueGrey, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_pin, size: 14, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(child: Text("Scheduled by: $schedulerName", style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w500))),
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
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}