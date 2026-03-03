import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({super.key});

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  final _idController = TextEditingController();
  Map<String, dynamic>? _requestData;
  bool _isLoading = false;

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('pending_requests')
          .select()
          .eq('pending_id', _idController.text.trim())
          .maybeSingle();

      setState(() => _requestData = response);
      if (response == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No application found with this ID")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Calculates if the application is older than 7 days
  bool _shouldShowSupport() {
    if (_requestData == null) return false;
    final createdAt = DateTime.parse(_requestData!['created_at']);
    final difference = DateTime.now().difference(createdAt).inDays;
    return difference >= 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F2EE),
      appBar: AppBar(
        title: const Text("Application Status"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "Enter Request ID",
                hintText: "REQ-XXX-...",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkStatus,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Check Status", style: TextStyle(color: Colors.white)),
              ),
            ),
            if (_requestData != null) ...[
              const SizedBox(height: 30),
              _buildProgressTracker(_requestData!['status'] ?? 'Submitted'),
              const SizedBox(height: 20),
              _buildDetailsCard(),
              
              /// Conditional Support Button
              if (_shouldShowSupport()) ...[
                const SizedBox(height: 20),
                _buildSupportButton(),
              ],
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        children: [
          const Text(
            "Application delayed? Contact support for assistance.",
            style: TextStyle(fontSize: 12, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // Add support logic here (e.g., launch WhatsApp or Email)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Connecting to support...")),
              );
            },
            icon: const Icon(Icons.help_outline, color: Colors.orange),
            label: const Text("Contact Support", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String status) {
    final steps = ["Submitted", "ADS Verified", "CDS Approved"];
    int currentStep = steps.indexOf(status);
    if (currentStep == -1) currentStep = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Approval Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              children: [
                Icon(
                  i <= currentStep ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: i <= currentStep ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontWeight: i == currentStep ? FontWeight.bold : FontWeight.normal,
                    color: i <= currentStep ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 11),
                height: 20,
                width: 2,
                color: i < currentStep ? Colors.green : Colors.grey[300],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow("Name", _requestData!['full_name']),
            _buildInfoRow("Request ID", _requestData!['pending_id']),
            _buildInfoRow("Date", _requestData!['created_at'].toString().substring(0, 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}