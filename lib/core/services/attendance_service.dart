import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/attendance_model.dart';

/// Service class for handling attendance operations using Firestore
class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'attendances';

  /// Get reference to attendances collection
  CollectionReference get _attendancesCollection =>
      _firestore.collection(_collectionName);

  /// Mark attendance for a user at an event
  /// 
  /// Creates or updates attendance document with composite ID (eventId_userId).
  /// Uses Firestore transaction to ensure atomic operations.
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// - [userId]: ID of the user whose attendance is being marked
  /// - [clubId]: ID of the club hosting the event
  /// - [adminId]: ID of the admin marking the attendance
  /// - [isPresent]: true for "present", false for "absent"
  /// 
  /// Throws: [FirebaseException] on failure
  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String clubId,
    required String adminId,
    required bool isPresent,
  }) async {
    try {
      // Create composite document ID to prevent duplicates
      final documentId = '${eventId}_$userId';

      await _firestore.runTransaction((transaction) async {
        final attendanceRef = _attendancesCollection.doc(documentId);

        // Check if document exists
        final doc = await transaction.get(attendanceRef);

        final status = isPresent ? 'present' : 'absent';

        final attendanceData = {
          'eventId': eventId,
          'userId': userId,
          'clubId': clubId,
          'status': status,
          'markedBy': adminId,
          'markedAt': FieldValue.serverTimestamp(),
        };

        if (doc.exists) {
          // Update existing attendance
          transaction.update(attendanceRef, attendanceData);
        } else {
          // Create new attendance
          transaction.set(attendanceRef, attendanceData);
        }
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to mark attendance: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while marking attendance: $e');
    }
  }

  /// Get attendance for a specific user at an event
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// - [userId]: ID of the user
  /// 
  /// Returns: AttendanceModel if found, null otherwise
  Future<AttendanceModel?> getAttendance(String eventId, String userId) async {
    try {
      final documentId = '${eventId}_$userId';
      final doc = await _attendancesCollection.doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return AttendanceModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to get attendance: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get stream of all attendances for a specific event
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// 
  /// Returns: Stream of List<AttendanceModel>
  Stream<List<AttendanceModel>> getAttendancesForEvent(String eventId) {
    try {
      return _attendancesCollection
          .where('eventId', isEqualTo: eventId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AttendanceModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get stream of present attendances for an event
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// 
  /// Returns: Stream of List<AttendanceModel> with status "present"
  Stream<List<AttendanceModel>> getPresentAttendances(String eventId) {
    try {
      return _attendancesCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'present')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AttendanceModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get stream of absent attendances for an event
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// 
  /// Returns: Stream of List<AttendanceModel> with status "absent"
  Stream<List<AttendanceModel>> getAbsentAttendances(String eventId) {
    try {
      return _attendancesCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'absent')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AttendanceModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get count of present attendances for an event
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// 
  /// Returns: Number of present attendances
  Future<int> getPresentCount(String eventId) async {
    try {
      final querySnapshot = await _attendancesCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'present')
          .get();

      return querySnapshot.docs.length;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to get present count: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get stream of present count for an event
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// 
  /// Returns: Stream of present count
  Stream<int> getPresentCountStream(String eventId) {
    try {
      return _attendancesCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'present')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  /// Delete attendance record
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event
  /// - [userId]: ID of the user
  /// 
  /// Throws: [FirebaseException] on failure
  Future<void> deleteAttendance(String eventId, String userId) async {
    try {
      final documentId = '${eventId}_$userId';
      await _attendancesCollection.doc(documentId).delete();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to delete attendance: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while deleting attendance: $e');
    }
  }
}
