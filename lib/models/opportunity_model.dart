import 'package:cloud_firestore/cloud_firestore.dart';

class OpportunityModel {
  final String? id;
  final String startupId;
  final String title;
  final String description;
  final String duration;
  final String hiddenDetails;
  final List<String> questions;
  final List<String> requiredSkills;
  final DateTime createdAt;
  final String status; // 'active', 'completed', etc.
  final String? workType;
  final int maxStudents;
  final int filledSlots;

  OpportunityModel({
    this.id,
    required this.startupId,
    required this.title,
    required this.description,
    required this.duration,
    required this.hiddenDetails,
    required this.questions,
    required this.requiredSkills,
    required this.createdAt,
    this.status = 'active',
    this.workType,
    this.maxStudents = 1,
    this.filledSlots = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'startupId': startupId,
      'title': title,
      'description': description,
      'duration': duration,
      'hiddenDetails': hiddenDetails,
      'questions': questions,
      'requiredSkills': requiredSkills,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'workType': workType,
      'maxStudents': maxStudents,
      'filledSlots': filledSlots,
    };
  }

  factory OpportunityModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return OpportunityModel(
      id: id,
      startupId: map['startupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      hiddenDetails: map['hiddenDetails'] ?? '',
      questions: List<String>.from(map['questions'] ?? []),
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      createdAt: parseDate(map['createdAt']),
      status: map['status'] ?? 'active',
      workType: map['workType'],
      maxStudents: map['maxStudents'] ?? 1,
      filledSlots: map['filledSlots'] ?? 0,
    );
  }
}
