import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? type; // 'application', 'status_update', 'task_completed'
  final String? relatedId; // opportunityId or applicationId
  final String? subId; // second ID for deep linking (e.g. applicationId)
  final String? role; // 'student' or 'startup' for unambiguous routing

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.relatedId,
    this.subId,
    this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type,
      'relatedId': relatedId,
      'subId': subId,
      'role': role,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] ?? false,
      type: map['type'],
      relatedId: map['relatedId'],
      subId: map['subId'],
      role: map['role'],
    );
  }
}
