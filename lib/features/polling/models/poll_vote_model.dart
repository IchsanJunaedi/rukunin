class PollVoteModel {
  final String id;
  final String pollId;
  final String residentId;
  final bool vote; // true = Ya, false = Tidak
  final DateTime votedAt;
  final String? residentName; // dari join profiles(full_name)

  const PollVoteModel({
    required this.id,
    required this.pollId,
    required this.residentId,
    required this.vote,
    required this.votedAt,
    this.residentName,
  });

  factory PollVoteModel.fromMap(Map<String, dynamic> map) {
    return PollVoteModel(
      id: map['id'] as String,
      pollId: map['poll_id'] as String,
      residentId: map['resident_id'] as String,
      vote: map['vote'] as bool,
      votedAt: DateTime.parse(map['voted_at'] as String),
      residentName: (map['profiles'] as Map?)?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poll_id': pollId,
      'resident_id': residentId,
      'vote': vote,
    };
  }
}
