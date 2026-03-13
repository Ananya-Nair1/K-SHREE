import 'package:flutter/material.dart';

class ApplicationSuccessPage extends StatelessWidget {
  final String schemeName;
  final String applicationDate;

  const ApplicationSuccessPage({
    Key? key,
    required this.schemeName,
    required this.applicationDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 100),
            ),
            const SizedBox(height: 30),
            const Text(
              "Application Submitted!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            Text(
              "Your application for $schemeName has been successfully received and is under review.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildRow("Scheme", schemeName),
                  const Divider(height: 24),
                  _buildRow("Applied On", applicationDate),
                  const Divider(height: 24),
                  _buildRow("Initial Status", "Pending Review"),
                ],
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("Return to Dashboard", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}