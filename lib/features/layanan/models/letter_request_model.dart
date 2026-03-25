const letterRequestStatusLabels = {
  'pending': 'Menunggu Verifikasi',
  'verified': 'Surat Siap',
  'completed': 'Selesai',
  'rejected': 'Ditolak',
};

const letterRequestTypeLabels = {
  'ktp_kk': 'Pengantar KTP & KK',
  'domisili': 'Keterangan Domisili',
  'sktm': 'Keterangan Tidak Mampu',
  'skck': 'Pengantar SKCK',
  'kematian': 'Keterangan Kematian',
  'nikah': 'Pengantar Nikah',
  'sku': 'Keterangan Usaha',
  'custom': 'Lainnya',
};

class LetterRequestModel {
  final String id;
  final String communityId;
  final String residentId;
  final String letterType;
  final String? purpose;
  final String? notes;
  final String status;
  final String? adminNotes;
  final String? letterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? residentName;
  final String? residentUnit;
  final Map<String, dynamic>? formData;
  final String? applicantName;

  const LetterRequestModel({
    required this.id,
    required this.communityId,
    required this.residentId,
    required this.letterType,
    this.purpose,
    this.notes,
    required this.status,
    this.adminNotes,
    this.letterId,
    required this.createdAt,
    required this.updatedAt,
    this.residentName,
    this.residentUnit,
    this.formData,
    this.applicantName,
  });

  factory LetterRequestModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return LetterRequestModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      residentId: map['resident_id'] as String,
      letterType: map['letter_type'] as String,
      purpose: map['purpose'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'pending',
      adminNotes: map['admin_notes'] as String?,
      letterId: map['letter_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      residentName: profile?['full_name'] as String?,
      residentUnit: profile?['unit_number'] as String?,
      formData: map['form_data'] as Map<String, dynamic>?,
      applicantName: map['applicant_name'] as String?,
    );
  }

  String get typeLabel => letterRequestTypeLabels[letterType] ?? letterType;
  String get statusLabel => letterRequestStatusLabels[status] ?? status;
  bool get isActive => status != 'completed' && status != 'rejected';

  double get progressPercent => switch (status) {
    'pending'   => 0.25,
    'verified'  => 0.9,
    'completed' => 1.0,
    _           => 0.0,
  };
}
