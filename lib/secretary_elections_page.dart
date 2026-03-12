import 'package:flutter/material.dart';

class SecretaryElectionsPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SecretaryElectionsPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unit Elections"), backgroundColor: Colors.redAccent),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                // TODO: Route to Poll Creation Page
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Poll Creator...")));
              },
              child: Card(
                color: Colors.red[50],
                elevation: 0,
                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(10)),
                child: const ListTile(
                  leading: Icon(Icons.how_to_vote, color: Colors.redAccent, size: 40),
                  title: Text("Add New Poll", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text("Create a new election poll for the unit"),
                ),
              ),
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: () {
                // TODO: Route to Election Procedure Rules/View
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loading Procedures...")));
              },
              child: Card(
                color: Colors.blueGrey[50],
                elevation: 0,
                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.blueGrey), borderRadius: BorderRadius.circular(10)),
                child: const ListTile(
                  leading: Icon(Icons.gavel, color: Colors.blueGrey, size: 40),
                  title: Text("View Election Procedure", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text("Read the rules and guidelines for NHG elections"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}