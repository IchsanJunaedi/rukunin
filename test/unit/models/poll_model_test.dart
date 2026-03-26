import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/polling/models/poll_model.dart';
import 'package:rukunin/features/polling/models/poll_vote_model.dart';

void main() {
  final now = DateTime.now();

  final sampleMap = {
    'id': 'poll-1',
    'community_id': 'comm-1',
    'created_by': 'user-1',
    'title': 'Naikkan iuran?',
    'description': 'Untuk perbaikan jalan',
    'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'ends_at': now.add(const Duration(days: 6)).toIso8601String(),
    'status': 'open',
    'created_at': now.toIso8601String(),
  };

  group('PollModel.fromMap', () {
    test('parses all fields correctly', () {
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.id, 'poll-1');
      expect(poll.title, 'Naikkan iuran?');
      expect(poll.description, 'Untuk perbaikan jalan');
      expect(poll.status, 'open');
      expect(poll.communityId, 'comm-1');
      expect(poll.createdBy, 'user-1');
    });

    test('description nullable', () {
      final m = Map<String, dynamic>.from(sampleMap)..remove('description');
      final poll = PollModel.fromMap(m);
      expect(poll.description, isNull);
    });

    test('status defaults to open when null', () {
      final m = Map<String, dynamic>.from(sampleMap)..['status'] = null;
      final poll = PollModel.fromMap(m);
      expect(poll.status, 'open');
    });
  });

  group('PollModel computed getters', () {
    test('isOpen true when status=open and not expired', () {
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.isOpen, isTrue);
    });

    test('isClosed true when status=closed', () {
      final m = Map<String, dynamic>.from(sampleMap)..['status'] = 'closed';
      final poll = PollModel.fromMap(m);
      expect(poll.isClosed, isTrue);
    });

    test('isClosed true when ends_at in the past', () {
      final m = Map<String, dynamic>.from(sampleMap)
        ..['ends_at'] = now.subtract(const Duration(hours: 1)).toIso8601String();
      final poll = PollModel.fromMap(m);
      expect(poll.isClosed, isTrue);
    });
  });

  group('PollModel vote counts', () {
    test('yesCount, noCount, totalVotes correct', () {
      final votes = [
        PollVoteModel(
          id: '1',
          pollId: 'poll-1',
          residentId: 'r1',
          vote: true,
          votedAt: now,
        ),
        PollVoteModel(
          id: '2',
          pollId: 'poll-1',
          residentId: 'r2',
          vote: true,
          votedAt: now,
        ),
        PollVoteModel(
          id: '3',
          pollId: 'poll-1',
          residentId: 'r3',
          vote: false,
          votedAt: now,
        ),
      ];
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.yesCount(votes), 2);
      expect(poll.noCount(votes), 1);
      expect(poll.totalVotes(votes), 3);
    });

    test('yesPercent returns 0 when no votes', () {
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.yesPercent([]), 0.0);
    });

    test('yesPercent correct with votes', () {
      final votes = [
        PollVoteModel(
          id: '1',
          pollId: 'poll-1',
          residentId: 'r1',
          vote: true,
          votedAt: now,
        ),
        PollVoteModel(
          id: '2',
          pollId: 'poll-1',
          residentId: 'r2',
          vote: false,
          votedAt: now,
        ),
      ];
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.yesPercent(votes), 0.5);
    });

    test('noPercent returns 0 when no votes', () {
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.noPercent([]), 0.0);
    });

    test('noPercent correct with votes', () {
      final votes = [
        PollVoteModel(
          id: '1',
          pollId: 'poll-1',
          residentId: 'r1',
          vote: true,
          votedAt: now,
        ),
        PollVoteModel(
          id: '2',
          pollId: 'poll-1',
          residentId: 'r2',
          vote: false,
          votedAt: now,
        ),
      ];
      final poll = PollModel.fromMap(sampleMap);
      expect(poll.noPercent(votes), 0.5);
    });
  });

  group('PollModel.toMap', () {
    test('toMap includes all required fields', () {
      final poll = PollModel.fromMap(sampleMap);
      final map = poll.toMap();
      expect(map['community_id'], 'comm-1');
      expect(map['created_by'], 'user-1');
      expect(map['title'], 'Naikkan iuran?');
      expect(map['description'], 'Untuk perbaikan jalan');
      expect(map['status'], 'open');
      expect(map.containsKey('starts_at'), isTrue);
      expect(map.containsKey('ends_at'), isTrue);
    });

    test('toMap handles null description', () {
      final m = Map<String, dynamic>.from(sampleMap)..remove('description');
      final poll = PollModel.fromMap(m);
      final map = poll.toMap();
      expect(map['description'], isNull);
    });
  });

  group('PollVoteModel.fromMap', () {
    test('parses all fields correctly', () {
      final voteMap = {
        'id': 'vote-1',
        'poll_id': 'poll-1',
        'resident_id': 'res-1',
        'vote': true,
        'voted_at': now.toIso8601String(),
        'profiles': {'full_name': 'Budi Santoso'},
      };
      final vote = PollVoteModel.fromMap(voteMap);
      expect(vote.id, 'vote-1');
      expect(vote.pollId, 'poll-1');
      expect(vote.residentId, 'res-1');
      expect(vote.vote, isTrue);
      expect(vote.residentName, 'Budi Santoso');
    });

    test('residentName nullable when no profiles', () {
      final voteMap = {
        'id': 'vote-1',
        'poll_id': 'poll-1',
        'resident_id': 'res-1',
        'vote': false,
        'voted_at': now.toIso8601String(),
      };
      final vote = PollVoteModel.fromMap(voteMap);
      expect(vote.residentName, isNull);
    });
  });

  group('PollVoteModel.toMap', () {
    test('toMap includes required fields', () {
      final vote = PollVoteModel(
        id: 'vote-1',
        pollId: 'poll-1',
        residentId: 'res-1',
        vote: true,
        votedAt: now,
      );
      final map = vote.toMap();
      expect(map['poll_id'], 'poll-1');
      expect(map['resident_id'], 'res-1');
      expect(map['vote'], isTrue);
    });
  });
}
