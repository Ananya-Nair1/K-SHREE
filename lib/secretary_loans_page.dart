import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoansPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const LoansPage({super.key, required this.userData});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            "Loans Management",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.teal,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_card_rounded), text: "Apply"),
              Tab(icon: Icon(Icons.track_changes_rounded), text: "My Loans"),
              Tab(icon: Icon(Icons.people_alt_rounded), text: "Requests"),
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
      final String memberId = widget.userData['aadhar_number']?.toString() ?? 'UNKNOWN';
      final String unitNo = widget.userData['unit_number']?.toString() ?? '';

      await Supabase.instance.client.from('loans').insert({
        'member_id': memberId,
        'unit_number': unitNo, // Saved so it shows up in the Unit's Requests tab
        'loan_type': _selectedType,
        'principal_amount': principal,
        'outstanding_amount': principal,
        'emi_amount': emi,
        'status': 'Pending at NHG', 
        'applied_date': DateTime.now().toIso8601String(),
        'remarks': _remarksController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Loan Application Submitted!"), backgroundColor: Colors.green),
        );
        _principalController.clear();
        _emiController.clear();
        _remarksController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Apply for a New Loan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: ['Linkage Loan', 'Internal Loan', 'Special Scheme', 'Other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: _inputStyle("Loan Type", Icons.category),
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _principalController, keyboardType: TextInputType.number, decoration: _inputStyle("Principal Amount (₹)", Icons.currency_rupee), validator: (v) => v!.isEmpty ? "Required" : null),
            const SizedBox(height: 20),
            TextFormField(controller: _emiController, keyboardType: TextInputType.number, decoration: _inputStyle("Proposed EMI (₹)", Icons.payments), validator: (v) => v!.isEmpty ? "Required" : null),
            const SizedBox(height: 20),
            TextFormField(controller: _remarksController, maxLines: 3, decoration: _inputStyle("Purpose / Remarks", Icons.notes)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _submitLoan,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Application", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: Colors.teal),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true, fillColor: Colors.white,
  );
}

// ==========================================
// TAB 2: TRACK MY LOANS
// ==========================================
class _TrackMyLoansTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  const _TrackMyLoansTab({required this.userData});

  @override
  Widget build(BuildContext context) {
    final String myAadhar = userData['aadhar_number']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('loans').stream(primaryKey: ['id']).eq('member_id', myAadhar).order('applied_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final loans = snapshot.data ?? [];
          if (loans.isEmpty) return const Center(child: Text("No personal loans found."));

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) => _MyLoanCard(loan: loans[index]),
          );
        },
      ),
    );
  }
}

class _MyLoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  const _MyLoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(loan['loan_type'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Applied: ${loan['applied_date'].toString().split('T')[0]}\nPrincipal: ₹${loan['principal_amount']}"),
        trailing: _ModernStatusPill(status: loan['status'] ?? 'Pending'),
      ),
    );
  }
}

// ==========================================
// TAB 3: VIEW MEMBER REQUESTS
// ==========================================
class _ViewRequestsTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  const _ViewRequestsTab({required this.userData});

  @override
  State<_ViewRequestsTab> createState() => _ViewRequestsTabState();
}

class _ViewRequestsTabState extends State<_ViewRequestsTab> {
  @override
  Widget build(BuildContext context) {
    final String myAadhar = widget.userData['aadhar_number']?.toString() ?? '';
    final String myUnit = widget.userData['unit_number']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: StreamBuilder<List<Map<String, dynamic>>>(
        // FIXED: Chaining multiple filters is not allowed on streams.
        // We filter by unit_number and then use Dart to exclude self.
        stream: Supabase.instance.client
            .from('loans')
            .stream(primaryKey: ['id'])
            .eq('unit_number', myUnit)
            .order('applied_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          // Filter out the secretary's own loan applications using Dart
          final allData = snapshot.data ?? [];
          final requests = allData.where((item) => item['member_id'].toString() != myAadhar).toList();

          if (requests.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: 500, child: Center(child: Text("No member requests found."))),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _LoanRequestCard(req: requests[index]),
          );
        },
      ),
    );
  }
}

class _LoanRequestCard extends StatefulWidget {
  final Map<String, dynamic> req;
  const _LoanRequestCard({required this.req});

  @override
  State<_LoanRequestCard> createState() => _LoanRequestCardState();
}

class _LoanRequestCardState extends State<_LoanRequestCard> {
  String _name = 'Loading...';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    final res = await Supabase.instance.client.from('Registered_Members').select('full_name').eq('aadhar_number', widget.req['member_id']).maybeSingle();
    if (mounted) setState(() => _name = res?['full_name'] ?? 'Unknown');
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    await Supabase.instance.client.from('loans').update({'status': status}).eq('id', widget.req['id']);
    if (mounted) setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.req['status'].toString();
    final isActionable = status.toLowerCase().contains('pending');

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.teal.shade50, child: Text(_name.isNotEmpty ? _name[0] : "?")),
              const SizedBox(width: 12),
              Expanded(child: Text(_name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
              _ModernStatusPill(status: status),
            ],
          ),
          const Divider(height: 24),
          _row("Loan Type", widget.req['loan_type']),
          _row("Principal", "₹${widget.req['principal_amount']}", isBold: true, color: Colors.teal.shade700),
          _row("Applied", widget.req['applied_date'].toString().split('T')[0]),
          if (isActionable) ...[
            const SizedBox(height: 16),
            _isUpdating ? const Center(child: CircularProgressIndicator()) : Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _updateStatus('Rejected at NHG'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("Reject"))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus('Pending at ADS'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white), child: const Text("Forward"))),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(width: 10),
      Flexible(child: Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: 13), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
    ]),
  );
}

class _ModernStatusPill extends StatelessWidget {
  final String status;
  const _ModernStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status.toLowerCase().contains('pending') ? Colors.orange : Colors.green;
    if (status.toLowerCase().contains('rejected')) color = Colors.red;
    if (status.toLowerCase().contains('ads')) color = Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}