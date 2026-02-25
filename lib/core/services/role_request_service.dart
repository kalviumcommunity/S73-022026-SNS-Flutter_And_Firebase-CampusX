import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/role_request_model.dart';

/// Service class for managing role upgrade requests in Firestore
class RoleRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'role_requests';
  final String _usersCollectionName = 'users';

  /// Get reference to role_requests collection
  CollectionReference get _requestsCollection =>
      _firestore.collection(_collectionName);

  /// Get reference to users collection
  CollectionReference get _usersCollection =>
      _firestore.collection(_usersCollectionName);

  /// Request a role upgrade to club_admin
  /// 
  /// Prevents duplicate pending requests for the same user.
  /// Sets requestedRole to "club_admin", currentRole to "student", 
  /// status to "pending", and requestedAt to server timestamp.
  /// 
  /// Parameters:
  /// - [userId]: The ID of the user requesting the upgrade
  /// 
  /// Throws: [FirebaseException] on failure
  /// Throws: [Exception] if a pending request already exists
  Future<void> requestRoleUpgrade(String userId) async {
    try {
      // Check for existing pending requests
      final existingRequests = await _requestsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception('A pending role upgrade request already exists for this user');
      }

      // Create new role request
      await _requestsCollection.add({
        'userId': userId,
        'requestedRole': 'club_admin',
        'currentRole': 'student',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to request role upgrade: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('pending role upgrade request already exists')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred while requesting role upgrade: $e');
    }
  }

  /// Get stream of all pending role upgrade requests
  /// 
  /// Returns: Stream of List<RoleRequestModel> with status == "pending"
  Stream<List<RoleRequestModel>> getPendingRequests() {
    try {
      return _requestsCollection
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
        final requests = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return RoleRequestModel.fromMap(data);
        }).toList();
        
        // Sort by requestedAt in memory to avoid Firestore index requirement
        requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        
        return requests;
      });
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  /// Approve a role upgrade request with club-scoped admin support
  /// 
  /// Uses Firestore transaction to atomically:
  /// 1. Update the request status to "approved"
  /// 2. Set reviewedBy and reviewedAt fields
  /// 3. Update the user's role to "club_admin"
  /// 4. Handle club-scoped admin assignment based on requestType:
  ///    - "existing_club": Add user to existing club's adminIds and user's adminClubs
  ///    - "new_club": Create new club and assign user as admin
  /// 
  /// Parameters:
  /// - [requestId]: The ID of the request to approve
  /// - [adminId]: The ID of the admin approving the request (college_admin)
  /// 
  /// Throws: [FirebaseException] on failure
  Future<void> approveRequest(String requestId, String adminId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get the request document
        final requestRef = _requestsCollection.doc(requestId);
        final requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('Request not found');
        }

        final requestData = requestSnapshot.data() as Map<String, dynamic>;
        final userId = requestData['userId'] as String;
        final requestType = requestData['requestType'] as String?;
        final targetClubId = requestData['targetClubId'] as String?;
        final newClubName = requestData['newClubName'] as String?;
        final newClubDescription = requestData['newClubDescription'] as String?;

        // Verify user exists
        final userRef = _usersCollection.doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception('User not found');
        }

        // Handle club-scoped admin assignment based on requestType
        if (requestType == 'existing_club') {
          // Existing club request
          if (targetClubId == null || targetClubId.isEmpty) {
            throw Exception('Target club ID is required for existing_club requests');
          }

          // Verify club exists
          final clubRef = _firestore.collection('clubs').doc(targetClubId);
          final clubSnapshot = await transaction.get(clubRef);

          if (!clubSnapshot.exists) {
            throw Exception('Club not found');
          }

          // Update user: role and adminClubs
          transaction.update(userRef, {
            'role': 'club_admin',
            'adminClubs': FieldValue.arrayUnion([targetClubId]),
          });

          // Update club: adminIds
          transaction.update(clubRef, {
            'adminIds': FieldValue.arrayUnion([userId]),
          });

        } else if (requestType == 'new_club') {
          // New club request
          if (newClubName == null || newClubName.isEmpty) {
            throw Exception('Club name is required for new_club requests');
          }

          // Create new club document
          final clubRef = _firestore.collection('clubs').doc();
          final newClubId = clubRef.id;

          transaction.set(clubRef, {
            'name': newClubName,
            'description': newClubDescription ?? '',
            'createdBy': userId,
            'adminIds': [userId],
            'memberCount': 1,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Update user: role and adminClubs
          transaction.update(userRef, {
            'role': 'club_admin',
            'adminClubs': FieldValue.arrayUnion([newClubId]),
          });

        } else {
          // Legacy request without requestType - maintain backward compatibility
          // Just upgrade to club_admin without club association
          transaction.update(userRef, {
            'role': 'club_admin',
          });
        }

        // Update the role_request with audit fields (common for all types)
        transaction.update(requestRef, {
          'status': 'approved',
          'reviewedBy': adminId,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to approve request: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while approving request: $e');
    }
  }

  /// Reject a role upgrade request
  /// 
  /// Updates the request status to "rejected" and sets reviewedBy and reviewedAt fields.
  /// 
  /// Parameters:
  /// - [requestId]: The ID of the request to reject
  /// - [adminId]: The ID of the admin rejecting the request
  /// 
  /// Throws: [FirebaseException] on failure
  Future<void> rejectRequest(String requestId, String adminId) async {
    try {
      await _requestsCollection.doc(requestId).update({
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to reject request: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred while rejecting request: $e');
    }
  }
}
