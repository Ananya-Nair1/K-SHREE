import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberTrainingsPage extends StatelessWidget {
  const MemberTrainingsPage({Key? key}) : super(key: key);

  // Sample data: Replace these URLs with your actual YouTube video links
  final List<Map<String, String>> trainings = const [
    {
      "title": "Basic Tailoring & Garment Making",
      "category": "Livelihood",
      "description": "Learn the fundamentals of stitching and garment making to start your own micro-enterprise.",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // Replace with real link
      "icon": "✂️"
    },
    {
      "title": "Mushroom Farming Guide",
      "category": "Agriculture",
      "description": "A step-by-step guide to profitable mushroom cultivation at home.",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // Replace with real link
      "icon": "🍄"
    },
    {
      "title": "Financial Literacy & Savings",
      "category": "Education",
      "description": "Understand how to manage unit savings, micro-finance, and personal budgeting.",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // Replace with real link
      "icon": "📊"
    },
    {
      "title": "Handicrafts & Paper Bag Making",
      "category": "Eco-Friendly",
      "description": "Learn to make eco-friendly paper bags and basic handicrafts for local markets.",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // Replace with real link
      "icon": "🛍️"
    }
  ];

  Future<void> _launchYouTubeVideo(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the video link.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Skill Trainings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final training = trainings[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(training["icon"]!, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              training["category"]!.toUpperCase(),
                              style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              training["title"]!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    training["description"]!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600, // YouTube Red color
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: const Text("Watch on YouTube", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _launchYouTubeVideo(context, training["url"]!),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}