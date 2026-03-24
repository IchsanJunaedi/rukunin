import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String communityId;
  final String userId;
  final String type; // 'payment' | 'announcement' | 'join_request' | 'join_approved' | 'join_rejected'
  final String title;
  final String? body;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IconData get icon {
    return switch (type) {
      'payment' => Icons.receipt_long_rounded,
      'announcement' => Icons.campaign_rounded,
      'join_request' => Icons.person_add_rounded,
      'join_approved' => Icons.check_circle_rounded,
      'join_rejected' => Icons.cancel_rounded,
      'letter_request' => Icons.article_rounded,
      'complaint' => Icons.report_problem_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}
