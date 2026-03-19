const complaintStatusLabels = {
  'pending': 'Menunggu',
  'in_progress': 'Ditindaklanjuti',
  'resolved': 'Selesai',
  'rejected': 'Ditolak',
};

const complaintCategoryLabels = {
  'infrastruktur': 'Infrastruktur',
  'keamanan': 'Keamanan',
  'kebersihan': 'Kebersihan',
  'sosial': 'Sosial',
  'lainnya': 'Lainnya',
};

class ComplaintModel {
  final String id;
  final String communityId;
  final String residentId;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? adminNotes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? residentName;
  final String? residentUnit;

  const ComplaintModel({
    required this.id,
    required this.communityId,
    required this.residentId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.adminNotes,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.residentName,
    this.residentUnit,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return ComplaintModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      residentId: map['resident_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String? ?? 'lainnya',
      status: map['status'] as String? ?? 'pending',
      adminNotes: map['admin_notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      residentName: profile?['full_name'] as String?,
      residentUnit: profile?['unit_number'] as String?,
    );
  }

  String get categoryLabel => complaintCategoryLabels[category] ?? category;
  String get statusLabel => complaintStatusLabels[status] ?? status;
  bool get isOpen => status != 'resolved' && status != 'rejected';
}
