import 'package:flutter/material.dart';

class MemberBylawsPage extends StatelessWidget {
  const MemberBylawsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NHG Bylaws"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text("1. Membership Rules", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          SizedBox(height: 10),
          Text("Membership is restricted to one woman per family residing in the NHG area."),
          Divider(),
          Text("2. Thrift Deposits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          SizedBox(height: 10),
          Text("Weekly thrift contributions are mandatory for all active members."),
        ],
      ),
    );
  }
}