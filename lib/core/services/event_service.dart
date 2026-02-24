import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event_model.dart';

/// Service class for handling event operations using Firestore
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'events';

  /// Get reference to events collection
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collectionName);

  /// Create a new event in Firestore
  /// 
  /// Automatically generates document ID and sets server timestamp
  /// 
  /// Parameters:
  /// - [event]: EventModel to create
  /// 
  /// Returns: The document ID of the created event
  /// Throws: [FirebaseException] on failure
  Future<String> createEvent(EventModel event) async {
    try {
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
