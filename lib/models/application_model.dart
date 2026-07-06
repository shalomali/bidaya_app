import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String? id;
  final String opportunityId;
  final String studentId;
  final String startupId;
  final List<String> answers;
  final String status; // 'pending', 'accepted', 'rejected', 'declined', 'active', 'review_pending', 'completed'
  final DateTime createdAt;
  final String? endorsementLetter;
  final String? certificateUrl;

  ApplicationModel({
    this.id,
    required this.opportunityId,
    required this.studentId,
    required this.startupId,
    required this.answers,
    this.status = 'pending',
    required this.createdAt,
    this.endorsementLetter,
    this.certificateUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'opportunityId': opportunityId,
      'studentId': studentId,
      'startupId': startupId,
      'answers': answers,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'endorsementLetter': endorsementLetter,
      'certificateUrl': certificateUrl,
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    // Helper to safety-parse strings from potentially different types (like DocumentReference)
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString(); // Fallback to toString for references or other types
    }

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    try {
      return ApplicationModel(
        id: id,
        opportunityId: safeString(map['opportunityId']),
        studentId: safeString(map['studentId']),
        startupId: safeString(map['startupId']),
        answers: List<String>.from(map['answers'] ?? []),
        status: safeString(map['status'] ?? 'pending'),
        createdAt: parseDate(map['createdAt']),
        endorsementLetter: map['endorsementLetter'] != null ? safeString(map['endorsementLetter']) : null,
        certificateUrl: map['certificateUrl'] != null ? safeString(map['certificateUrl']) : null,
      );
    } catch (e) {
      // Diagnostic log for the user to see in their browser console/phone log
      print('CRITICAL: ApplicationModel parsing failed for document $id: $e');
      print('Raw map data: $map');
      rethrow;
    }
  }
}
