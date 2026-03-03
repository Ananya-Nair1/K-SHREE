import 'package:flutter/material.dart';
import 'membership_application_page.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F2EE),
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

            /// View Status Button
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () {
                  print("View Status Clicked");
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "View Application Status\nCheck the status of your membership application",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Apply Button
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF3E4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () {
                        Navigator.push(
                                  context,
                                MaterialPageRoute(
                                  builder: (context) => const MembershipApplicationPage(),
                                ),
                              );
                            },
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Apply for Membership\nStart your application to join Kudumbashree",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                       ),
                    ],
                  ),
                ),
              );
           }
}