import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ADSManageElectionPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ADSManageElectionPage({super.key, required this.userData});

  @override
  State<ADSManageElectionPage> createState() => _ADSManageElectionPageState();
}

class _ADSManageElectionPageState extends State<ADSManageElectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _positionController = TextEditingController();
  
  bool _isLoading = false;
  final supabase = Supabase.instance.client;
  final Color adsBlue = const Color(0xFF2B6CB0);

  // Starts the Ward Election
  Future<void> _startWardElection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String adsWard = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();
      final String adsPanchayat = widget.userData['panchayat']?.toString() ?? '';

      // Insert or Update the single row for this ward's election
      await supabase.from('ward_election_status').upsert({
        'ward_number': adsWard,
        'panchayat': adsPanchayat,
        'position_name': _positionController.text.trim(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ward Election STARTED Successfully!"), backgroundColor: Colors.green)
        );
        _positionController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Stops the Ward Election
  Future<void> _stopWardElection() async {
    setState(() => _isLoading = true);

    try {
      final String adsWard = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();
      final String adsPanchayat = widget.userData['panchayat']?.toString() ?? '';
      
      // Look up any currently active elections for this ward to stop them
      final activeElections = await supabase
          .from('ward_election_status')
          .select('position_name')
          .eq('ward_number', adsWard)
          .eq('panchayat', adsPanchayat)
          .eq('is_active', true);

      if (activeElections.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No active elections to stop.")));
        setState(() => _isLoading = false);
        return;
      }

      // Deactivate them
      for (var election in activeElections) {
        await supabase.from('ward_election_status').upsert({
          'ward_number': adsWard,
          'panchayat': adsPanchayat,
          'position_name': election['position_name'],
          'is_active': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ward Election STOPPED."), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Manage Ward Election", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: adsBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Start New Ward Election", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        hintText: "Position Name (e.g., ADS Secretary)",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _isLoading ? null : _startWardElection,
                        icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.play_circle_fill, color: Colors.white),
                        label: const Text("Start Election", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
              child: Column(
                children: [
                  const Text("Stop Current Election", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: _isLoading ? null : _stopWardElection,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text("Close Voting Polls", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}