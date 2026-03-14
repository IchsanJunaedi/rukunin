class FamilyMember {
  final String? id;
  final String? residentId;
  String fullName;
  String? nik;
  String relationship;

  FamilyMember({
    this.id,
    this.residentId,
    required this.fullName,
    this.nik,
    required this.relationship,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String?,
      residentId: map['resident_id'] as String?,
      fullName: map['full_name'] as String,
      nik: map['nik'] as String?,
      relationship: map['relationship'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (residentId != null) 'resident_id': residentId,
      'full_name': fullName,
      'nik': nik?.isEmpty == true ? null : nik,
      'relationship': relationship,
    };
  }
}
