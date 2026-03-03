import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MembershipApplicationPage extends StatefulWidget {
  const MembershipApplicationPage({Key? key}) : super(key: key);

  @override
  State<MembershipApplicationPage> createState() =>
      _MembershipApplicationPageState();
}

class _MembershipApplicationPageState
    extends State<MembershipApplicationPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final districtController = TextEditingController();
  final panchayatController = TextEditingController();
  final wardController = TextEditingController();
  final unitController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final aadharController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDEAE3),
      appBar: AppBar(
        title: const Text("Membership Application"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Location Details",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 15),

                  buildTextField("District *", "Enter district", districtController),
                  buildTextField("Panchayat *", "Enter panchayat", panchayatController),
                  buildTextField("Ward *", "Enter ward", wardController),
                  buildTextField("Unit Number *", "Enter unit number", unitController),

                  const Divider(height: 30),

                  const Text("Personal Details",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 15),

                  buildTextField("Full Name *", "Enter full name", nameController),

                  const Text("Date of Birth *"),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: dobController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: "yyyy-mm-dd",
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        dobController.text =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      }
                    },
                    validator: (value) =>
                        value!.isEmpty ? "Select date of birth" : null,
                  ),

                  const SizedBox(height: 15),

                  buildTextField(
                    "Aadhar Number *",
                    "Enter 12-digit Aadhar number",
                    aadharController,
                    keyboardType: TextInputType.number,
                  ),

                  buildTextField(
                    "Phone Number *",
                    "Enter 10-digit phone number",
                    phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  const Text("Address *"),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Enter full address",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter address" : null,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            // 1. Generate the Short Code and ID
                            final panchayat = panchayatController.text.trim().toUpperCase();
                            String shortCode = panchayat.length >= 3 
                                ? panchayat.substring(0, 3) 
                                : (panchayat.isEmpty ? "XXX" : panchayat);

                            final generatedId = "REQ-$shortCode-${wardController.text.trim()}-${unitController.text.trim()}";

                            print("Attempting to insert ID: $generatedId");

                            // 2. Perform the Insert
                            // We assign the result to 'response' so the print statement works.
                            // We use .select() only if we want Supabase to return the data we just sent.
                            final response = await supabase
                                .from('pending_requests')
                                .insert({
                                  'pending_id': generatedId,
                                  'district': districtController.text.trim(),
                                  'panchayat': panchayatController.text.trim(),
                                  'ward': int.tryParse(wardController.text.trim()) ?? 0,
                                  'unit_number': int.tryParse(unitController.text.trim()) ?? 0,
                                  'full_name': nameController.text.trim(),
                                  'dob': dobController.text.trim(),
                                  'aadhar_number': aadharController.text.trim(),
                                  'phone_number': phoneController.text.trim(),
                                  'address': addressController.text.trim(),
                                })
                                .select(); 

                            // 3. This will now work because 'response' is defined above
                            print("Insert Response: $response");

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Application Submitted Successfully")),
                              );
                              // Optional: Clear form after success
                              _formKey.currentState!.reset();
                            }

                          } catch (e) {
                            print("ERROR OCCURRED: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: ${e.toString()}")),
                              );
                            }
                          }
                        }
                      },
                      child: const Text("Submit Application"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? "This field is required" : null,
          ),
        ],
      ),
    );
  }
}