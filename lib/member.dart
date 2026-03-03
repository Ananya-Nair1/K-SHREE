class Member {
  final String id;
  final String fullName;
  final String userId;
  final String nhgUnit;
  final String ward;
  final String panchayat;
  final int attendance;

  Member({
    required this.id,
    required this.fullName,
    required this.userId,
    required this.nhgUnit,
    required this.ward,
    required this.panchayat,
    this.attendance = 0,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name'] ?? 'No Name',
      userId: map['user_id'] ?? '',
      nhgUnit: map['nhg_unit'] ?? 'Not Assigned',
      ward: map['ward']?.toString() ?? 'N/A',
      panchayat: map['panchayat'] ?? 'N/A',
      attendance: map['attendance'] ?? 0,
    );
  }
}