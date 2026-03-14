class AnnouncementModel {
  final String id;
  final String communityId;
  final String title;
  final String body;
  final String type; // 'info' | 'penting' | 'urgent'
  final String? createdBy;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.body,
    required this.type,
    this.createdBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String? ?? 'info',
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'community_id': communityId,
      'title': title,
      'body': body,
      'type': type,
    };
  }
}
