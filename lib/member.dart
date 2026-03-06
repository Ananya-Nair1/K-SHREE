class Member {
  final String? userId;
  final String? fullName;
  final String? password;
  final String? photoUrl;
  final String? role;

  Member({
    this.userId,
    this.fullName,
    this.password,
    this.photoUrl,
    this.role,
  });

  // This factory constructor takes the raw data from your Supabase database 
  // and converts it into a neat Flutter object.
  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      // UPDATED: Now it correctly grabs the Aadhar number from Registered_Members!
      // (It also gracefully falls back to 'user_id' just in case you use the other table)
      userId: map['aadhar_number']?.toString() ?? map['user_id']?.toString(),
      
      fullName: map['full_name']?.toString(),
      password: map['password']?.toString(),
      photoUrl: map['photo_url']?.toString(), 
      role: map['role']?.toString() ?? map['designation']?.toString() ?? 'Member', // Checks both role and designation
    );
  }

  // (Optional) Useful if you ever need to update the user's details back to Supabase
  Map<String, dynamic> toMap() {
    return {
      'aadhar_number': userId, // Updated to save back as aadhar_number
      'full_name': fullName,
      'password': password,
      'photo_url': photoUrl,
      'designation': role,
    };
  }
}