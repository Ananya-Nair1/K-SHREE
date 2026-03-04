import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({Key? key}) : super(key: key);

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  final TextEditingController _requestIdController = TextEditingController();
  Map<String, dynamic>? _applicationData;
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _statusFlow = [
    'Submitted',
    'Processing',
    'NHG Secretary Approved'
  ];

  Future<void> _checkStatus() async {
    final requestId = _requestIdController.text.trim();
    if (requestId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _applicationData = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('pending_requests')
          .select()
          .eq('pending_id', requestId)
          .maybeSingle();

      if (response != null) {
        setState(() => _applicationData = response);
      } else {
        setState(() => _errorMessage = "Invalid Request ID. Please try again.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error connecting to database.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _getCurrentStepIndex(String currentStatus) {
    if (currentStatus == 'NHG Secretary Approved') return 3;
    if (currentStatus == 'Processing' || currentStatus == 'Rejected') return 2; 
    return 1; // Default to 'Submitted'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F6),
      appBar: AppBar(
        title: const Text("Track Application"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text("Enter your Request ID to track status", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _requestIdController,
                    decoration: InputDecoration(
                      hintText: "e.g., REQ-KOT-2-4",
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: _isLoading ? null : _checkStatus,
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Track Status", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

            if (_applicationData != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Applicant: ${_applicationData!['full_name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Unit: ${_applicationData!['unit_number']} | Ward: ${_applicationData!['ward']}", style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 30),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: _statusFlow.length,
                          itemBuilder: (context, index) {
                            final stepStatus = _statusFlow[index];
                            final currentStatus = _applicationData!['status'];
                            final isRejected = currentStatus == 'Rejected';
                            
                            final currentStepIndex = _getCurrentStepIndex(currentStatus);
                            final isCompleted = index < currentStepIndex;
                            final isCurrent = index == currentStepIndex - 1;

                            // UI Logic for colors and icons
                            Color circleColor = Colors.grey[300]!;
                            IconData circleIcon = Icons.circle;

                            if (isRejected) {
                              if (index == 0) {
                                circleColor = Colors.green;
                                circleIcon = Icons.check;
                              } else if (index == 1) {
                                circleColor = Colors.red; // Paint it red!
                                circleIcon = Icons.close;
                              }
                            } else {
                              if (isCompleted) {
                                circleColor = Colors.green;
                                circleIcon = Icons.check;
                              } else if (isCurrent) {
                                circleColor = Colors.orange;
                                circleIcon = Icons.pending;
                              }
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 30, height: 30,
                                      decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                                      child: Icon(circleIcon, color: Colors.white, size: 18),
                                    ),
                                    if (index != _statusFlow.length - 1)
                                      Container(
                                        width: 3, height: 50,
                                        color: (isCompleted && !isRejected) || (index == 0 && isRejected) ? Colors.green : Colors.grey[300],
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 15),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    isRejected && index == 1 ? "Application Rejected" : stepStatus,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isCurrent || isCompleted || (isRejected && index == 1) ? FontWeight.bold : FontWeight.normal,
                                      color: isRejected && index == 1 ? Colors.red : circleColor,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}