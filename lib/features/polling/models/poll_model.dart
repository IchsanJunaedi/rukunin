import 'poll_vote_model.dart';

class PollModel {
  final String id;
  final String communityId;
  final String createdBy;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status; // 'open' | 'closed'
  final DateTime createdAt;

  const PollModel({
    required this.id,
    required this.communityId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.createdAt,
  });

  factory PollModel.fromMap(Map<String, dynamic> map) {
    return PollModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      createdBy: map['created_by'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: DateTime.parse(map['ends_at'] as String),
      status: map['status'] as String? ?? 'open',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'community_id': communityId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'status': status,
    };
  }

  bool get isOpen => status == 'open' && DateTime.now().isBefore(endsAt);
  bool get isClosed => status == 'closed' || DateTime.now().isAfter(endsAt);

  int yesCount(List<PollVoteModel> votes) => votes.where((v) => v.vote).length;
  int noCount(List<PollVoteModel> votes) => votes.where((v) => !v.vote).length;
  int totalVotes(List<PollVoteModel> votes) => votes.length;

  double yesPercent(List<PollVoteModel> votes) {
    if (votes.isEmpty) return 0.0;
    return yesCount(votes) / votes.length;
  }

  double noPercent(List<PollVoteModel> votes) {
    if (votes.isEmpty) return 0.0;
    return noCount(votes) / votes.length;
  }
}
