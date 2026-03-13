
import 'package:flutter/material.dart';
import 'membership_application_page.dart';
import 'application_status_page.dart'; // Ensure this file exists in your lib folder

class MembershipPage extends StatelessWidget {
  const MembershipPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F2EE), // Matching your light green theme
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F2EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Membership",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// About Kudumbashree Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About Kudumbashree",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Kudumbashree is Kerala State Poverty Eradication Mission, "
                    "a community-based organization of women's self-help groups.",
                  ),
                  SizedBox(height: 10),
                  Text("• Empowering women through community action"),
                  Text("• Providing microfinance and livelihood opportunities"),
                  Text("• Building strong neighborhood groups (NHG)"),
                  Text("• Supporting local entrepreneurship"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// View Status Button - Navigates to ApplicationStatusPage
            _buildActionCard(
              context,
              "View Application Status",
              "Check the status of your membership application",
              Colors.blue,
              const Color(0xFFDCE6F8),
              () {
                // FIXED: Removed 'const' to prevent build error
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApplicationStatusPage()),
                );
              },
            ),

            const SizedBox(height: 20),

            /// Apply Button
            _buildActionCard(
              context,
              "Apply for Membership",
              "Start your application to join Kudumbashree",
              Colors.green,
              const Color(0xFFDFF3E4),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MembershipApplicationPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build the large action cards with subtitles
  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
