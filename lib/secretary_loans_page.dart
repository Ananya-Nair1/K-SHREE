import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoansPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const LoansPage({super.key, required this.userData});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  // We use a DefaultTabController in the build method, so no explicit controller needed here.

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Loans Management"),
          backgroundColor: Colors.green,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.add_card), text: "Apply"),
              Tab(icon: Icon(Icons.track_changes), text: "Track My Loans"),
              Tab(icon: Icon(Icons.group), text: "Member Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ApplyLoanTab(userData: widget.userData),
            _TrackMyLoansTab(userData: widget.userData),
            _ViewRequestsTab(userData: widget.userData),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: APPLY FOR A LOAN
// ==========================================
class _ApplyLoanTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  const _ApplyLoanTab({required this.userData});

  @override
  State<_ApplyLoanTab> createState() => _ApplyLoanTabState();
}

class _ApplyLoanTabState extends State<_ApplyLoanTab> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Linkage Loan';
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _emiController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLoan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double principal = double.parse(_principalController.text);
      final double emi = double.parse(_emiController.text);
      final String memberId = widget.userData['aadhar_number'] ?? 'UNKNOWN';

      // Insert into Supabase (Assuming 'id' is set to auto-generate UUID in Supabase)
      await Supabase.instance.client.from('loans').insert({
        'member_id': memberId,
        'loan_type': _selectedType,
        'principal_amount': principal,
        'outstanding_amount': principal, // Initially, outstanding is the full principal
        'emi_amount': emi,
        'status': 'Pending',
        'applied_date': DateTime.now().toIso8601String(),
        'remarks': _remarksController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loan Application Submitted!"), backgroundColor: Colors.green),
        );
        // Clear the form
        _principalController.clear();
        _emiController.clear();
        _remarksController.clear();
        setState(() => _selectedType = 'Linkage Loan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Apply for a New Loan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: ['Linkage Loan', 'Internal Loan', 'Other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: const InputDecoration(labelText: "Loan Type", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _principalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Principal Amount (₹)", border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? "Enter amount" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Proposed EMI Amount (₹)", border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? "Enter EMI amount" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Remarks / Purpose", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isLoading ? null : _submitLoan,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Loan Application", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: TRACK MY LOANS (Secretary's own loans)
// ==========================================
class _TrackMyLoansTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  const _TrackMyLoansTab({required this.userData});

  @override
  Widget build(BuildContext context) {
    final String myAadhar = userData['aadhar_number'] ?? '';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('loans')
          .stream(primaryKey: ['id'])
          .eq('member_id', myAadhar)
          .order('applied_date', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        
        final loans = snapshot.data ?? [];
        if (loans.isEmpty) {
          return const Center(child: Text("You haven't applied for any loans yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return Card(
              child: ListTile(
                title: Text("${loan['loan_type']} - ₹${loan['principal_amount']}"),
                subtitle: Text("Applied: ${loan['applied_date'].toString().split('T')[0]}\nStatus: ${loan['status']}"),
                trailing: _buildStatusChip(loan['status'] ?? 'Pending'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'approved') color = Colors.green;
    if (status.toLowerCase() == 'rejected') color = Colors.red;

    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }
}

// ==========================================
// TAB 3: VIEW MEMBER REQUESTS
// ==========================================
class _ViewRequestsTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  const _ViewRequestsTab({required this.userData});

  @override
  Widget build(BuildContext context) {
    final String myAadhar = userData['aadhar_number'] ?? '';

    // Fetching loans where member_id is NOT the secretary's ID (assuming these are other members)
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('loans')
          .stream(primaryKey: ['id'])
          .neq('member_id', myAadhar)
          .order('applied_date', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text("No member loan requests found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              child: ExpansionTile(
                title: Text("Member ID: ${req['member_id']}"),
                subtitle: Text("${req['loan_type']} - ₹${req['principal_amount']} (${req['status']})"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("EMI Amount: ₹${req['emi_amount']}"),
                        Text("Applied On: ${req['applied_date'].toString().split('T')[0]}"),
                        Text("Remarks: ${req['remarks'] ?? 'N/A'}"),
                        const SizedBox(height: 10),
                        // You can add Approve/Reject buttons here in the future
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}