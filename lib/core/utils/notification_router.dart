import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/notification_model.dart';
import '../theme.dart';

class NotificationRouter {
  static void navigate(BuildContext context, NotificationModel notification) {
    final type = notification.type;
    final relatedId = notification.relatedId;
    final subId = notification.subId;
    final role = notification.role;

    if (relatedId == null || relatedId.isEmpty) {
      debugPrint('NotificationRouter: Missing relatedId');
      return;
    }

    if (role == 'startup') {
      if (type == 'task_completed') {
        context.pushNamed('startupCompleteTask', pathParameters: {'id': relatedId});
      } else {
        context.pushNamed(
          'startupReviewApplicants',
          pathParameters: {'id': relatedId},
          queryParameters: subId != null ? {'appId': subId} : {},
        );
      }
      return;
    }

    // Default to student side if role is 'student' or null
    if (type == 'task_completed') {
      context.pushNamed('studentOpportunityDetails', pathParameters: {'id': relatedId});
    } else {
      context.pushNamed('studentOpportunityDetails', pathParameters: {'id': relatedId});
    }
  }

  /// Specialized handler for main.dart which uses GoRouter directly without context
  static void navigateWithRouter(GoRouter router, Map<String, dynamic> data) {
    final String type = data['type'] ?? '';
    final String relatedId = data['relatedId'] ?? '';
    final String? subId = data['subId']?.toString();
    final String? role = data['role']?.toString();

    if (relatedId.isEmpty) return;

    if (role == 'startup') {
      if (type == 'task_completed') {
        router.push('/startup/complete/$relatedId');
      } else {
        router.push('/startup/review/$relatedId${(subId != null && subId.isNotEmpty) ? '?appId=$subId' : ''}');
      }
      return;
    }

    // Default to student side
    router.push('/student/opportunity/$relatedId');
  }
}
