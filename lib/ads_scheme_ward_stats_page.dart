import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ADSSchemeWardStatsPage extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> userData;

  const ADSSchemeWardStatsPage({super.key, required this.scheme, required this.userData});

  @override
  State<ADSSchemeWardStatsPage> createState() => _ADSSchemeWardStatsPageState();
}

class _ADSSchemeWardStatsPageState extends State<ADSSchemeWardStatsPage> {
  final supabase = Supabase.instance.client;
  final Color adsBlue = const Color(0xFF2B6CB0);

  bool _isLoading = true;
  
  int _totalApps = 0;
  int _pendingAds = 0;
  int _pendingCds = 0;
  int _approved = 0;
  int _rejected = 0;

  @override
  void initState() {
    super.initState();
    _fetchWardStatistics();
  }

  Future<void> _fetchWardStatistics() async {
    try {
      final String adsWard = (widget.userData['ward'] ?? widget.userData['ward_number']).toString();

      // Fetch all applications for this scheme, strictly filtered to this Ward
      final response = await supabase.from('scheme_applications').select('''
        status,
        Registered_Members!inner (ward, unit_number)
      ''')
      .eq('scheme_id', widget.scheme['id'])
      .eq('Registered_Members.ward', adsWard);

      final apps = List<Map<String, dynamic>>.from(response);

      int pAds = 0, pCds = 0, apprv = 0, rej = 0;

      for (var app in apps) {
        final status = app['status']?.toString().toLowerCase() ?? '';
        if (status.contains('pending at ads') || status.contains('pending review')) {
          pAds++;
        } else if (status.contains('cds')) {
          pCds++;
        } else if (status.contains('approved')) {
          apprv++;
        } else if (status.contains('reject')) {
          rej++;
        } else {
          pAds++; // Default fallback
        }
      }

      if (mounted) {
        setState(() {
          _totalApps = apps.length;
          _pendingAds = pAds;
          _pendingCds = pCds;
          _approved = apprv;
          _rejected = rej;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Ward Statistics", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: adsBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.scheme['category'] ?? 'General', style: TextStyle(color: adsBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(widget.scheme['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text("Application Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 16),

                // Total Applications Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [adsBlue, adsBlue.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text("Total Ward Applications", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text("$_totalApps", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Visual Distribution Bar
                if (_totalApps > 0) ...[
                  const Text("Status Distribution", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 12,
                      width: double.infinity,
                      child: Row(
                        children: [
                          if (_approved > 0) Expanded(flex: _approved, child: Container(color: Colors.green)),
                          if (_pendingCds > 0) Expanded(flex: _pendingCds, child: Container(color: Colors.blue)),
                          if (_pendingAds > 0) Expanded(flex: _pendingAds, child: Container(color: Colors.orange)),
                          if (_rejected > 0) Expanded(flex: _rejected, child: Container(color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Grid of Stats
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard("Approved", _approved, Icons.check_circle, Colors.green),
                    _buildStatCard("Fwd to CDS", _pendingCds, Icons.forward_to_inbox, Colors.blue),
                    _buildStatCard("Pending Review", _pendingAds, Icons.pending_actions, Colors.orange),
                    _buildStatCard("Rejected", _rejected, Icons.cancel, Colors.red),
                  ],
                )
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("$count", style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}