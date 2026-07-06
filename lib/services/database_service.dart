import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/student_profile_model.dart';
import '../models/startup_profile_model.dart';
import '../models/opportunity_model.dart';
import '../models/application_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _studentProfilesCollection = FirebaseFirestore.instance.collection('student_profiles');
  final CollectionReference _startupProfilesCollection = FirebaseFirestore.instance.collection('startup_profiles');
  final CollectionReference _opportunitiesCollection = FirebaseFirestore.instance.collection('opportunities');
  final CollectionReference _applicationsCollection = FirebaseFirestore.instance.collection('applications');
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference _aiResultsCollection = FirebaseFirestore.instance.collection('ai_matching_results');

  // Users methods
  Future<void> updateUserData(UserModel user) async {
    try {
      return await _usersCollection
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("DatabaseService getUserData Error: $e");
    }
    return null;
  }

  // Student Profile methods
  Future<void> updateStudentProfile(StudentProfileModel profile) async {
    try {
      return await _studentProfilesCollection
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error in updateStudentProfile: $e');
      rethrow;
    }
  }

  Future<StudentProfileModel?> getStudentProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _studentProfilesCollection
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return StudentProfileModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("DatabaseService getStudentProfile Error: $e");
    }
    return null;
  }

  Stream<StudentProfileModel?> getStudentProfileStream(String uid) {
    return _studentProfilesCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return StudentProfileModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Startup Profile methods
  Future<void> updateStartupProfile(StartupProfileModel profile) async {
    try {
      return await _startupProfilesCollection
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error in updateStartupProfile: $e');
      rethrow;
    }
  }

  Future<StartupProfileModel?> getStartupProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _startupProfilesCollection
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return StartupProfileModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("DatabaseService getStartupProfile Error: $e");
    }
    return null;
  }

  Future<void> toggleBookmark(String studentId, String opportunityId) async {
    try {
      final doc = await _studentProfilesCollection.doc(studentId).get();
      if (doc.exists) {
        final profile = StudentProfileModel.fromMap(doc.data() as Map<String, dynamic>);
        final bookmarks = List<String>.from(profile.bookmarks);
        
        if (bookmarks.contains(opportunityId)) {
          bookmarks.remove(opportunityId);
        } else {
          bookmarks.add(opportunityId);
        }
        
        await _studentProfilesCollection.doc(studentId).update({'bookmarks': bookmarks});
      }
    } catch (e) {
      debugPrint("DatabaseService toggleBookmark Error: $e");
      rethrow;
    }
  }

  // Opportunity methods
  Future<void> createOpportunity(OpportunityModel opportunity) async {
    return await _opportunitiesCollection.doc().set(opportunity.toMap());
  }

  Future<OpportunityModel?> getOpportunity(String opportunityId) async {
    try {
      final doc = await _opportunitiesCollection
          .doc(opportunityId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return OpportunityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint("DatabaseService getOpportunity Error: $e");
    }
    return null;
  }

  Stream<OpportunityModel?> getOpportunityStream(String opportunityId) {
    return _opportunitiesCollection.doc(opportunityId).snapshots().map((doc) {
      if (doc.exists) {
        return OpportunityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Stream<List<OpportunityModel>> getOpportunities() {
    return _opportunitiesCollection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OpportunityModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OpportunityModel>> getStartupOpportunities(String startupId) {
    return _opportunitiesCollection
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OpportunityModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateOpportunityStatus(String opportunityId, String status) async {
    return await _opportunitiesCollection.doc(opportunityId).update({'status': status});
  }

  Future<void> updateOpportunity(OpportunityModel opportunity) async {
    if (opportunity.id == null) throw 'Opportunity ID is required for update';
    return await _opportunitiesCollection.doc(opportunity.id).update(opportunity.toMap());
  }

  Future<void> deleteOpportunity(String opportunityId) async {
    // Delete opportunity
    await _opportunitiesCollection.doc(opportunityId).delete();
    
    // Also delete associated applications
    final applications = await _applicationsCollection.where('opportunityId', isEqualTo: opportunityId).get();
    for (var doc in applications.docs) {
      await doc.reference.delete();
    }
  }

  /// Recalculates filledSlots based on actual 'active' or 'completed' applications.
  /// This helps self-heal data inconsistencies.
  Future<void> syncOpportunityCapacity(String opportunityId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('opportunityId', isEqualTo: opportunityId)
          .get();
          
      final actualFilled = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? '';
        return status == 'active' || status == 'completed' || status == 'review_pending';
      }).length;

      final oppDoc = await _opportunitiesCollection.doc(opportunityId).get();
      if (oppDoc.exists) {
        final currentFilled = (oppDoc.data() as Map<String, dynamic>)['filledSlots'] ?? 0;
        if (currentFilled != actualFilled) {
          debugPrint('Syncing capacity for $opportunityId: $currentFilled -> $actualFilled');
          await _opportunitiesCollection.doc(opportunityId).update({'filledSlots': actualFilled});
        }
      }
    } catch (e) {
      debugPrint('Error syncing opportunity capacity: $e');
    }
  }


  // Application methods
  Future<void> applyToOpportunity(ApplicationModel application) async {
    // Prevent duplicate applications
    final existing = await _applicationsCollection
        .where('opportunityId', isEqualTo: application.opportunityId)
        .where('studentId', isEqualTo: application.studentId)
        .get();
        
    if (existing.docs.isNotEmpty) {
      throw 'You have already applied for this opportunity.';
    }

    final docRef = await _applicationsCollection.add(application.toMap());
    debugPrint('DatabaseService: Created application ${docRef.id}');
    
    // Fetch opportunity title for notification
    String oppTitle = 'New Opportunity';
    try {
      final oppDoc = await _opportunitiesCollection.doc(application.opportunityId).get();
      if (oppDoc.exists) {
        oppTitle = (oppDoc.data() as Map<String, dynamic>)['title'] ?? 'New Opportunity';
      }
    } catch (e) {
      debugPrint('Error fetching opp title for notification: $e');
    }

    // Notify Startup
    await createNotification(NotificationModel(
      userId: application.startupId,
      title: 'New Application',
      message: 'You have a new applicant for $oppTitle',
      createdAt: DateTime.now(),
      type: 'new_applicant',
      relatedId: application.opportunityId,
      subId: docRef.id,
      role: 'startup',
    ));
    
    return;
  }

  Stream<List<ApplicationModel>> getOpportunityApplications(String opportunityId) {
    return _applicationsCollection
        .where('opportunityId', isEqualTo: opportunityId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ApplicationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<ApplicationModel>> getApplicationsByOpportunityAndStudent(String opportunityId, String studentId) async {
    final snapshot = await _applicationsCollection
        .where('opportunityId', isEqualTo: opportunityId)
        .where('studentId', isEqualTo: studentId)
        .get();
    
    return snapshot.docs.map((doc) => 
      ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
    ).toList();
  }

  Stream<List<ApplicationModel>> getStartupApplications(String startupId) {
    return _applicationsCollection
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ApplicationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<ApplicationModel?> getApplication(String applicationId) async {
    final doc = await _applicationsCollection.doc(applicationId).get();
    if (doc.exists) {
      return ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<List<ApplicationModel>> getStudentApplications(String studentId) {
    return _applicationsCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ApplicationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ApplicationModel>> getStudentCompletedApplications(String studentId) {
    return _applicationsCollection
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ApplicationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    final doc = await _applicationsCollection.doc(applicationId).get();
    if (!doc.exists) return;
    
    final app = ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    final previousStatus = app.status;

    await _applicationsCollection.doc(applicationId).update({'status': status});
    
    // Handle capacity logic if student is accepted ('active')
    if (status == 'active' && previousStatus != 'active') {
      final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
      if (oppDoc.exists) {
        final oppData = oppDoc.data() as Map<String, dynamic>;
        int filled = oppData['filledSlots'] ?? 0;
        int max = oppData['maxStudents'] ?? 1;
        
        filled += 1;
        
        final updates = <String, dynamic>{'filledSlots': filled};
        if (filled >= max) {
          updates['status'] = 'closed';
        }
        
        await _opportunitiesCollection.doc(app.opportunityId).update(updates);
      }
    } else if (previousStatus == 'active' && (status == 'declined' || status == 'rejected')) {
      // Re-open slot if student declines or is removed
      final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
      if (oppDoc.exists) {
        final oppData = oppDoc.data() as Map<String, dynamic>;
        int filled = oppData['filledSlots'] ?? 0;
        
        if (filled > 0) {
          filled -= 1;
          final updates = <String, dynamic>{'filledSlots': filled};
          if (oppData['status'] == 'closed' && filled < (oppData['maxStudents'] ?? 1)) {
            updates['status'] = 'active';
          }
          await _opportunitiesCollection.doc(app.opportunityId).update(updates);
        }
      }
    }
    
    // Notify Student
    final appDoc = await _applicationsCollection.doc(applicationId).get();
    if (appDoc.exists) {
      final app = ApplicationModel.fromMap(appDoc.data() as Map<String, dynamic>, appDoc.id);
      
      // Fetch opportunity title
      String oppTitle = 'Opportunity';
      try {
        final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
        if (oppDoc.exists) {
          oppTitle = (oppDoc.data() as Map<String, dynamic>)['title'] ?? 'Opportunity';
        }
      } catch (e) {}

      await createNotification(NotificationModel(
        userId: app.studentId,
        title: 'Update: $oppTitle',
        message: 'Your application for "$oppTitle" is now $status.',
        createdAt: DateTime.now(),
        type: 'status_update',
        relatedId: app.opportunityId,
        subId: app.id,
        role: 'student',
      ));
    }
  }

  Future<void> finalizeApplication(String applicationId, String endorsement) async {
    final statusDoc = await _applicationsCollection.doc(applicationId).get();
    if (statusDoc.exists && (statusDoc.data() as Map<String, dynamic>)['status'] == 'completed') {
      return;
    }

    await _applicationsCollection.doc(applicationId).update({
      'status': 'completed',
      'endorsementLetter': endorsement,
    });
    
      // Check if ALL expected students are also completed
      final appDoc = await _applicationsCollection.doc(applicationId).get();
      if (appDoc.exists) {
        final oppId = (appDoc.data() as Map<String, dynamic>)['opportunityId'];
        if (oppId != null) {
          final oppDoc = await _opportunitiesCollection.doc(oppId).get();
          if (oppDoc.exists) {
            final oppData = oppDoc.data() as Map<String, dynamic>;
            final maxStudents = oppData['maxStudents'] ?? 1;

            final completedAppsSnapshot = await _applicationsCollection
                .where('opportunityId', isEqualTo: oppId)
                .where('status', isEqualTo: 'completed')
                .get();
            
            if (completedAppsSnapshot.docs.length >= maxStudents) {
              await _opportunitiesCollection.doc(oppId).update({'status': 'completed'});
            }
          }
        }
      }
    
    // Notify Student
    final doc = await _applicationsCollection.doc(applicationId).get();
    if (doc.exists) {
      final app = ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Fetch opportunity title
      String oppTitle = 'Opportunity';
      try {
        final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
        if (oppDoc.exists) {
          oppTitle = (oppDoc.data() as Map<String, dynamic>)['title'] ?? 'Opportunity';
        }
      } catch (e) {}

      await createNotification(NotificationModel(
        userId: app.studentId,
        title: 'Task Completed: $oppTitle',
        message: 'Congratulations! Your task "$oppTitle" has been marked as completed. You can now view your certificate.',
        createdAt: DateTime.now(),
        type: 'task_completed',
        relatedId: app.opportunityId,
        subId: app.id,
        role: 'student',
      ));
    }
  }

  Future<void> declineApplication(String applicationId) async {
    debugPrint('DatabaseService: Declining application $applicationId');
    try {
      final docRef = _applicationsCollection.doc(applicationId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw 'Application document not found.';
      }

      await updateApplicationStatus(applicationId, 'declined');
      
      await docRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final app = ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      String oppTitle = 'Opportunity';
      try {
        final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
        if (oppDoc.exists) {
          oppTitle = (oppDoc.data() as Map<String, dynamic>)['title'] ?? 'Opportunity';
        }
      } catch (e) {
        debugPrint('Error fetching opp title for decline notification: $e');
      }

      await createNotification(NotificationModel(
        userId: app.startupId,
        title: 'Student Declined Offer',
        message: 'The student has declined your offer for "$oppTitle".',
        createdAt: DateTime.now(),
        type: 'status_update',
        relatedId: app.opportunityId,
        role: 'startup',
      ));
      debugPrint('DatabaseService: Successfully declined application $applicationId and notified startup');
    } catch (e) {
      debugPrint('DatabaseService: Error in declineApplication: $e');
      rethrow;
    }
  }

  Future<void> markTaskAsCompletedByStudent(String applicationId) async {
    await _applicationsCollection.doc(applicationId).update({'status': 'review_pending'});
    
    // Notify Startup
    final doc = await _applicationsCollection.doc(applicationId).get();
    if (doc.exists) {
      final app = ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      String oppTitle = 'Opportunity';
      try {
        final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
        if (oppDoc.exists) {
          oppTitle = (oppDoc.data() as Map<String, dynamic>)['title'] ?? 'Opportunity';
        }
      } catch (e) {}

      await createNotification(NotificationModel(
        userId: app.startupId,
        title: 'Task Completion Verification',
        message: 'Has the student completed "$oppTitle"? Please verify to issue their certificate.',
        createdAt: DateTime.now(),
        type: 'task_completed',
        relatedId: app.opportunityId,
        subId: app.id,
        role: 'startup',
      ));
    }
  }

  Future<void> acceptAgreement(String applicationId) async {
    final appRef = _applicationsCollection.doc(applicationId);
    
    try {
      // Use a transaction to ensure atomic capacity check
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final appDoc = await transaction.get(appRef);
        if (!appDoc.exists) throw 'Application not found';
        
        final appData = appDoc.data() as Map<String, dynamic>;
        final oppId = appData['opportunityId'];
        final previousStatus = appData['status'];
        
        if (previousStatus == 'active') return; // Already accepted

        final oppRef = _opportunitiesCollection.doc(oppId);
        final oppDoc = await transaction.get(oppRef);
        if (!oppDoc.exists) throw 'Opportunity not found';
        
        final oppData = oppDoc.data() as Map<String, dynamic>;
        final filled = oppData['filledSlots'] ?? 0;
        final max = oppData['maxStudents'] ?? 1;
        
        if (filled >= max) {
          throw 'TASK_FULL';
        }
        
        // Update application
        transaction.update(appRef, {'status': 'active'});
        
        // Update opportunity capacity
        final newFilled = filled + 1;
        final updates = <String, dynamic>{'filledSlots': newFilled};
        if (newFilled >= max) {
          updates['status'] = 'closed';
        }
        transaction.update(oppRef, updates);
      });
    } catch (e) {
      if (e.toString().contains('TASK_FULL')) throw 'TASK_FULL';
      rethrow;
    }

    // Notify Startup and share email (Keep this outside transaction to avoid side effects repeating on retries)
    final doc = await _applicationsCollection.doc(applicationId).get();
    if (doc.exists) {
      final app = ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Fetch opportunity title
      String oppTitle = 'Opportunity';
      try {
        final oppDoc = await _opportunitiesCollection.doc(app.opportunityId).get();
        if (oppDoc.exists) {
          oppTitle = (oppDoc.data() as Map<String, dynamic>)['title'] ?? 'Opportunity';
        }
      } catch (e) {}

      // Fetch student email
      String studentEmail = 'No email found';
      try {
        final studentDoc = await _studentProfilesCollection.doc(app.studentId).get();
        if (studentDoc.exists) {
          studentEmail = (studentDoc.data() as Map<String, dynamic>)['email'] ?? '';
        }
        
        // Fallback to users collection if profile email is empty
        if (studentEmail.isEmpty) {
          final userDoc = await _usersCollection.doc(app.studentId).get();
          if (userDoc.exists) {
            studentEmail = (userDoc.data() as Map<String, dynamic>)['email'] ?? 'No email found';
          }
        }
      } catch (e) {
        debugPrint('Error fetching student email: $e');
      }

      await createNotification(NotificationModel(
        userId: app.startupId,
        title: 'Agreement Accepted!',
        message: 'The student has accepted the agreement for "$oppTitle". You can now reach them at: $studentEmail',
        createdAt: DateTime.now(),
        type: 'status_update',
        relatedId: app.opportunityId,
        subId: app.id,
        role: 'startup',
      ));
    }
  }

  // Notification methods
  Future<void> createNotification(NotificationModel notification) async {
    await _notificationsCollection.add(notification.toMap());
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final querySnapshot = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    return await batch.commit();
  }

  // Account Cleanup
  Future<void> deleteUserData(String uid, String role) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Delete notifications
    final notifs = await _notificationsCollection.where('userId', isEqualTo: uid).get();
    for (var doc in notifs.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete Profile
    if (role == 'student') {
      batch.delete(_studentProfilesCollection.doc(uid));
      // Delete applications sent by student
      final apps = await _applicationsCollection.where('studentId', isEqualTo: uid).get();
      for (var doc in apps.docs) {
        batch.delete(doc.reference);
      }
      // Delete AI results for student
      final aiResults = await _aiResultsCollection.where('studentId', isEqualTo: uid).get();
      for (var doc in aiResults.docs) {
        batch.delete(doc.reference);
      }
    } else if (role == 'startup') {
      batch.delete(_startupProfilesCollection.doc(uid));
      // Delete opportunities and their applications
      final opps = await _opportunitiesCollection.where('startupId', isEqualTo: uid).get();
      for (var oppDoc in opps.docs) {
        final apps = await _applicationsCollection.where('opportunityId', isEqualTo: oppDoc.id).get();
        for (var appDoc in apps.docs) {
          batch.delete(appDoc.reference);
        }
        batch.delete(oppDoc.reference);
        // Delete AI results for this opportunity
        final aiRes = await _aiResultsCollection.where('opportunityId', isEqualTo: oppDoc.id).get();
        for (var doc in aiRes.docs) {
          batch.delete(doc.reference);
        }
      }
    }

    // 3. Delete User Document
    batch.delete(_usersCollection.doc(uid));

    return await batch.commit();
  }
}
