class CommunityContactModel {
  final String id;
  final String communityId;
  final String nama;
  final String jabatan;
  final String phone;
  final String? photoUrl;
  final int urutan;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityContactModel({
    required this.id,
    required this.communityId,
    required this.nama,
    required this.jabatan,
    required this.phone,
    this.photoUrl,
    required this.urutan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityContactModel.fromMap(Map<String, dynamic> map) {
    return CommunityContactModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      nama: map['nama'] as String,
      jabatan: map['jabatan'] as String,
      phone: map['phone'] as String,
      photoUrl: map['photo_url'] as String?,
      urutan: map['urutan'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'community_id': communityId,
        'nama': nama,
        'jabatan': jabatan,
        'phone': phone,
        if (photoUrl != null) 'photo_url': photoUrl,
        'urutan': urutan,
      };

  /// Dua huruf kapital dari kata pertama + kedua nama (fallback: dua huruf pertama)
  String get initials {
    final words = nama.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
  }
}
