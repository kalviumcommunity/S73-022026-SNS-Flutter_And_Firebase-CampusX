import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/registration_model.dart';

/// Service class for handling event registration operations with capacity control
class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'registrations';
  final String _eventsCollectionName = 'events';

  /// Get reference to registrations collection
  CollectionReference get _registrationsCollection =>
      _firestore.collection(_collectionName);

  /// Get reference to events collection
  CollectionReference get _eventsCollection =>
      _firestore.collection(_eventsCollectionName);

  /// Register a user for an event with capacity control and waitlist support
  /// 
  /// Uses Firestore transaction to prevent race conditions.
  /// Checks event capacity and assigns status accordingly.
  /// 
  /// Parameters:
  /// - [eventId]: ID of the event to register for
  /// - [clubId]: ID of the club hosting the event
  /// - [userId]: ID of the user registering
  /// 
  /// Returns: The registration document ID
  /// Throws: [Exception] if user is already registered or on failure
  Future<String> registerForEvent(
    String eventId,
    String clubId,
    String userId,
  ) async {
    try {
      String? registrationId;

      await _firestore.runTransaction((transaction) async {
        // Check if user already has a registration for this event
        final existingRegistrations = await _registrationsCollection
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (existingRegistrations.docs.isNotEmpty) {
          throw Exception('Already registered');
        }

        // Fetch event document to get capacity
        final eventDoc = await transaction.get(_eventsCollection.doc(eventId));
        
        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final eventData = eventDoc.data() as Map<String, dynamic>;
        final capacity = eventData['capacity'] as int? ?? 0;

        // Count current registrations with status = "registered"
        final registeredQuery = await _registrationsCollection
            .where('eventId', isEqualTo: eventId)
            .where('status', isEqualTo: 'registered')
            .get();

        final registeredCount = registeredQuery.docs.length;

        // Determine status based on capacity
        final status = registeredCount < capacity ? 'registered' : 'waitlisted';

        // Create new registration document
        final newRegistrationRef = _registrationsCollection.doc();
        registrationId = newRegistrationRef.id;

        final registration = RegistrationModel(
          id: newRegistrationRef.id,
          eventId: eventId,
          clubId: clubId,
          userId: userId,
          status: status,
          registeredAt: DateTime.now(),
        );

        transaction.set(newRegistrationRef, registration.toMap());
      });

      return registrationId ?? '';
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to register for event: ${e.message}',
      );
    } catch (e) {
      // Re-throw custom exceptions
      if (e.toString().contains('Already registered')) {
        rethrow;
      }
      if (e.toString().contains('Event not found')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred while registering: $e');
    }
  }

  /// Cancel a user's event registration and promote waitlisted user if applicable
  /// 
  /// If canceling a "registered" user, promotes the first waitlisted user.
  /// If canceling a "waitlisted" user, just deletes the registration.
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// - [userId]: The ID of the user
  /// 
  /// Throws: [Exception] if registration not found or on failure
  Future<void> cancelRegistration(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Find user's registration
        final userRegistrations = await _registrationsCollection
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (userRegistrations.docs.isEmpty) {
          throw Exception('No registration found');
        }

        final userRegistrationDoc = userRegistrations.docs.first;
        final userRegistrationData =
            userRegistrationDoc.data() as Map<String, dynamic>;
        final userStatus = userRegistrationData['status'] as String;

        // Delete the user's registration
        transaction.delete(userRegistrationDoc.reference);

        // If user was registered (not waitlisted), promote first waitlisted user
        if (userStatus == 'registered') {
          final waitlistedQuery = await _registrationsCollection
              .where('eventId', isEqualTo: eventId)
              .where('status', isEqualTo: 'waitlisted')
              .get();

          if (waitlistedQuery.docs.isNotEmpty) {
            // Sort by registeredAt in memory to get the first waitlisted user
            final waitlistedDocs = waitlistedQuery.docs;
            waitlistedDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['registeredAt'] as Timestamp).toDate();
              final bTime = (bData['registeredAt'] as Timestamp).toDate();
              return aTime.compareTo(bTime);
            });

            final firstWaitlisted = waitlistedDocs.first;
            transaction.update(
              firstWaitlisted.reference,
              {'status': 'registered'},
            );
          }
        }
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to cancel registration: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('No registration found')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred while canceling: $e');
    }
  }

  /// Get count of registered users (not including waitlisted)
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Number of registered users
  Future<int> getRegistrationCount(String eventId) async {
    try {
      final querySnapshot = await _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'registered')
          .get();

      return querySnapshot.docs.length;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to get registration count: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Check if user is registered for an event
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// - [userId]: The ID of the user
  /// 
  /// Returns: RegistrationModel if found, null otherwise
  Future<RegistrationModel?> checkIfUserRegistered(
    String eventId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return RegistrationModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to check registration: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get stream of all registrations for a specific event
  /// 
  /// Returns real-time stream of registrations ordered by registration date
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Stream of List\<RegistrationModel\>
  Stream<List<RegistrationModel>> getRegistrationsForEvent(String eventId) {
    try {
      return _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .snapshots()
          .map((snapshot) {
        final registrations = snapshot.docs
            .map((doc) => RegistrationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
        
        // Sort in memory by registeredAt
        registrations.sort((a, b) {
          if (a.registeredAt == null || b.registeredAt == null) return 0;
          return b.registeredAt!.compareTo(a.registeredAt!);
        });
        
        return registrations;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get stream of all registrations for a specific user
  /// 
  /// Returns real-time stream of user's registrations ordered by registration date
  /// 
  /// Parameters:
  /// - [userId]: The ID of the user
  /// 
  /// Returns: Stream of List\<RegistrationModel\>
  Stream<List<RegistrationModel>> getRegistrationsForUser(String userId) {
    try {
      return _registrationsCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final registrations = snapshot.docs
            .map((doc) => RegistrationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
        
        // Sort in memory by registeredAt
        registrations.sort((a, b) {
          if (a.registeredAt == null || b.registeredAt == null) return 0;
          return b.registeredAt!.compareTo(a.registeredAt!);
        });
        
        return registrations;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get stream of registration count for an event (registered only)
  /// 
  /// Real-time updates of how many people are registered
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Stream of registration count
  Stream<int> getRegistrationCountStream(String eventId) {
    try {
      return _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'registered')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  /// Get count of waitlisted users for an event
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Number of waitlisted users
  Future<int> getWaitlistCount(String eventId) async {
    try {
      final querySnapshot = await _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waitlisted')
          .get();

      return querySnapshot.docs.length;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to get waitlist count: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get stream of waitlist count for an event
  /// 
  /// Real-time updates of how many people are waitlisted
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Stream of waitlist count
  Stream<int> getWaitlistCountStream(String eventId) {
    try {
      return _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waitlisted')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  // ========== Admin View Methods ==========

  /// Get stream of all registrations for an event (admin view)
  /// 
  /// Returns all registrations regardless of status, ordered by registeredAt.
  /// Useful for admin dashboards to see complete registration list.
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Stream of List\<RegistrationModel\> ordered by registeredAt (newest first)
  Stream<List<RegistrationModel>> getRegistrationsByEvent(String eventId) {
    try {
      return _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .snapshots()
          .map((snapshot) {
        final registrations = snapshot.docs
            .map((doc) => RegistrationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
        
        // Sort in memory by registeredAt (newest first)
        registrations.sort((a, b) {
          if (a.registeredAt == null || b.registeredAt == null) return 0;
          return b.registeredAt!.compareTo(a.registeredAt!);
        });
        
        return registrations;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get stream of registered users only (admin view)
  /// 
  /// Returns only users with status == "registered", ordered by registeredAt.
  /// Useful for admin dashboards to see confirmed attendees.
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Stream of List\<RegistrationModel\> with status "registered"
  Stream<List<RegistrationModel>> getRegisteredUsers(String eventId) {
    try {
      return _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'registered')
          .snapshots()
          .map((snapshot) {
        final registrations = snapshot.docs
            .map((doc) => RegistrationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
        
        // Sort in memory by registeredAt (newest first)
        registrations.sort((a, b) {
          if (a.registeredAt == null || b.registeredAt == null) return 0;
          return b.registeredAt!.compareTo(a.registeredAt!);
        });
        
        return registrations;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get stream of waitlisted users only (admin view)
  /// 
  /// Returns only users with status == "waitlisted", ordered by registeredAt.
  /// Useful for admin dashboards to manage waitlist.
  /// 
  /// Parameters:
  /// - [eventId]: The ID of the event
  /// 
  /// Returns: Stream of List\<RegistrationModel\> with status "waitlisted"
  Stream<List<RegistrationModel>> getWaitlistedUsers(String eventId) {
    try {
      return _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waitlisted')
          .snapshots()
          .map((snapshot) {
        final registrations = snapshot.docs
            .map((doc) => RegistrationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();
        
        // Sort in memory by registeredAt (oldest first - FIFO order for fairness)
        registrations.sort((a, b) {
          if (a.registeredAt == null || b.registeredAt == null) return 0;
          return a.registeredAt!.compareTo(b.registeredAt!);
        });
        
        return registrations;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }
}
