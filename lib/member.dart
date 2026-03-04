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
      userId: map['user_id']?.toString(),
      fullName: map['full_name']?.toString(),
      password: map['password']?.toString(),
      photoUrl: map['photo_url']?.toString(), // Fetches the image link!
      role: map['role']?.toString() ?? 'Member', // Defaults to 'Member' if blank
    );
  }

  // (Optional) Useful if you ever need to update the user's details back to Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'password': password,
      'photo_url': photoUrl,
      'role': role,
    };
  }
}