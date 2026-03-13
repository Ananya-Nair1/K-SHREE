import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberTrainingsPage extends StatefulWidget {
  const MemberTrainingsPage({Key? key}) : super(key: key);

  @override
  State<MemberTrainingsPage> createState() => _MemberTrainingsPageState();
}

class _MemberTrainingsPageState extends State<MemberTrainingsPage> {
  final supabase = Supabase.instance.client;

  // Mock list of YouTube Training Videos
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

  Future<void> _launchYouTube(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open video.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Skill Trainings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal, // Applied Teal Theme
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
                    height: 180, // Increased height to fit text below the image
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

            // --- LIVE SESSIONS FROM SUPABASE ---
            FutureBuilder(
              future: supabase.from('trainings').select().order('training_date', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Colors.teal)));
                }
                
                if (snapshot.hasError) {
                  return _buildEmptyState("Training modules are being updated. Check back later!");
                }

                final trainings = snapshot.data as List<dynamic>? ?? [];

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

  // --- UPDATED VIDEO CARD UI ---
  Widget _buildVideoCard(Map<String, String> video) {
    return GestureDetector(
      onTap: () => _launchYouTube(video['url']!),
      child: Container(
        width: 200, // Made wider for better text readability
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Half: Thumbnail with Play Button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(video['thumbnail']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            // Bottom Half: Clear Text on White Background
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                video['title']!,
                style: const TextStyle(
                  color: Colors.blueGrey, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    String formattedDate = training['training_date'] ?? 'TBA';
    try {
      if (training['training_date'] != null) {
        final date = DateTime.parse(training['training_date']);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      }
    } catch (_) {}

    final bool isUpcoming = training['status']?.toString().toUpperCase() != 'COMPLETED';

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
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50, // Applied Teal Theme
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.model_training, color: Colors.teal.shade700, size: 28), // Applied Teal Theme
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        training['title'] ?? 'Skill Development Workshop', 
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
              training['description'] ?? 'Join this session to improve your skills and livelihood opportunities within the Kudumbashree network.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.teal), // Applied Teal Theme
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
                  backgroundColor: isUpcoming ? Colors.teal : Colors.grey.shade400, // Applied Teal Theme
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isUpcoming ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Registration request sent!"), backgroundColor: Colors.green)
                  );
                } : null,
                child: Text(
                  isUpcoming ? "Register for Training" : "Completed", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}