import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event_model.dart';

/// Service class for handling event operations using Firestore
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'events';
  final String _usersCollectionName = 'users';

  /// Get reference to events collection
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collectionName);

  /// Get reference to users collection
  CollectionReference get _usersCollection =>
      _firestore.collection(_usersCollectionName);

  /// Create a new event in Firestore with club-scoped permission enforcement
  /// 
  /// Verifies that:
  /// 1. The creator has club_admin role
  /// 2. The event's clubId exists in creator's adminClubs list
  /// 
  /// Prevents arbitrary clubId injection by validating user permissions.
  /// 
  /// Parameters:
  /// - [event]: EventModel to create
  /// - [creatorId]: ID of the user creating the event (must match event.createdBy)
  /// 
  /// Returns: The document ID of the created event
  /// Throws: [FirebaseException] on failure
  /// Throws: [Exception] if user lacks permission
  Future<String> createEvent(EventModel event, String creatorId) async {
    try {
      // Verify creatorId matches event.createdBy to prevent injection
      if (event.createdBy != creatorId) {
        throw Exception('Creator ID mismatch: cannot create event for another user');
      }

      // Fetch current user data to verify permissions
      final userDoc = await _usersCollection.doc(creatorId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String?;

      // Verify user has club_admin role
      if (userRole != 'club_admin') {
        throw Exception(
          'Permission denied: Only club admins can create events',
        );
      }

      // Verify user is admin of this club by checking club's adminIds array
      final clubDoc = await _firestore.collection('clubs').doc(event.clubId).get();
      
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubData = clubDoc.data() as Map<String, dynamic>;
      final adminIds = clubData['adminIds'] != null
          ? List<String>.from(clubData['adminIds'] as List)
          : <String>[];

      if (!adminIds.contains(creatorId)) {
        throw Exception(
          'Permission denied: You are not an admin of this club',
        );
      }

      // Create document with auto-generated ID
      final docRef = await _eventsCollection.add(event.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to create event: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('Creator ID mismatch') ||
          e.toString().contains('User not found')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred while creating event: $e');
    }
  }

  /// Get stream of events for a specific club
  /// 
  /// Returns real-time stream of events ordered by date (newest first)
  /// 
  /// Parameters:
  /// - [clubId]: The ID of the club to get events for
  /// 
  /// Returns: Stream of List\<EventModel\> sorted by date (descending)
  Stream<List<EventModel>> getEventsByClub(String clubId) {
    try {
      return _eventsCollection
          .where('clubId', isEqualTo: clubId)
          .snapshots()
          .map((snapshot) {
        final events = snapshot.docs.map((doc) {
          return EventModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
        
        // Sort in-memory by date (descending) to avoid composite index requirement
        events.sort((a, b) => b.date.compareTo(a.date));
        
        return events;
      });
    } catch (e) {
      throw Exception('Failed to get events for club: $e');
    }
  }

  /// Get stream of all events
  /// 
  /// Returns real-time stream of all events ordered by date (newest first)
  /// 
  /// Returns: Stream of List\<EventModel\>
  Stream<List<EventModel>> getAllEvents() {
    try {
      return _eventsCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return EventModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get all events: $e');
    }
  }

  /// Get a single event by ID
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event to retrieve
  /// 
  /// Returns: Future\<EventModel?\>
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to get event: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while getting event: $e');
    }
  }

  /// Update an existing event
  /// 
  /// Parameters:
  /// - [event]: EventModel with updated data
  /// 
  /// Throws: [FirebaseException] on failure
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.id).update(event.toMap());
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to update event: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while updating event: $e');
    }
  }

  /// Delete an event
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event to delete
  /// 
  /// Throws: [FirebaseException] on failure
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to delete event: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while deleting event: $e');
    }
  }

  /// Get stream of events created by a specific user
  /// 
  /// Parameters:
  /// - [userId]: The ID of the user who created the events
  /// 
  /// Returns: Stream of List\<EventModel\> sorted by date (descending)
  Stream<List<EventModel>> getEventsByCreator(String userId) {
    try {
      return _eventsCollection
          .where('createdBy', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final events = snapshot.docs.map((doc) {
          return EventModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
        
        // Sort in-memory by date (descending) to avoid composite index requirement
        events.sort((a, b) => b.date.compareTo(a.date));
        
        return events;
      });
    } catch (e) {
      throw Exception('Failed to get events by creator: $e');
    }
  }

  /// Get stream of upcoming events (future dates only)
  /// 
  /// Returns: Stream of List\<EventModel\>
  Stream<List<EventModel>> getUpcomingEvents() {
    try {
      final now = DateTime.now();
      return _eventsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return EventModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get upcoming events: $e');
    }
  }

  /// Get stream of past events
  /// 
  /// Returns: Stream of List\<EventModel\>
  Stream<List<EventModel>> getPastEvents() {
    try {
      final now = DateTime.now();
      return _eventsCollection
          .where('date', isLessThan: Timestamp.fromDate(now))
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return EventModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get past events: $e');
    }
  }
}
