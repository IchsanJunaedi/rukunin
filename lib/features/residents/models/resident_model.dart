class ResidentModel {
  final String id;
  final String? communityId;
  final String fullName;
  final String? unitNumber;
  final String? phone;
  final String? nik;
  final String? email;
  final String status;
  final String? photoUrl;
  final int? rtNumber;
  final String? block;
  final int motorcycleCount;
  final int carCount;
  final DateTime createdAt;

  const ResidentModel({
    required this.id,
    this.communityId,
    required this.fullName,
    this.unitNumber,
    this.phone,
    this.nik,
    this.email,
    required this.status,
    this.photoUrl,
    this.rtNumber,
    this.block,
    this.motorcycleCount = 0,
    this.carCount = 0,
    required this.createdAt,
  });

  factory ResidentModel.fromMap(Map<String, dynamic> map) {
    return ResidentModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String?,
      fullName: map['full_name'] as String,
      unitNumber: map['unit_number'] as String?,
      phone: map['phone'] as String?,
      nik: map['nik'] as String?,
      email: map['email'] as String?,
      status: map['status'] as String? ?? 'active',
      photoUrl: map['photo_url'] as String?,
      rtNumber: map['rt_number'] as int?,
      block: map['block'] as String?,
      motorcycleCount: map['motorcycle_count'] as int? ?? 0,
      carCount: map['car_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get isActive => status == 'active';

  /// Contoh: "Blok A / No. 5 / RT 2"
  String get alamatLengkap {
    final parts = <String>[];
    if (block != null && block!.isNotEmpty) parts.add('Blok $block');
    if (unitNumber != null && unitNumber!.isNotEmpty) parts.add('No. $unitNumber');
    if (rtNumber != null) parts.add('RT $rtNumber');
    return parts.isNotEmpty ? parts.join(' · ') : '-';
  }
}
