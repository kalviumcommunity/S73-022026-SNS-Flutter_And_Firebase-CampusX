import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/team_model.dart';
import '../../models/team_membership_model.dart';

/// Service class for handling team operations using Firestore
class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _teamsCollectionName = 'teams';
  final String _teamMembershipsCollectionName = 'team_memberships';
  final String _usersCollectionName = 'users';
  final String _clubsCollectionName = 'clubs';

  /// Get reference to teams collection
  CollectionReference get _teamsCollection =>
      _firestore.collection(_teamsCollectionName);

  /// Get reference to team memberships collection
  CollectionReference get _teamMembershipsCollection =>
      _firestore.collection(_teamMembershipsCollectionName);

  /// Get reference to users collection
  CollectionReference get _usersCollection =>
      _firestore.collection(_usersCollectionName);

  /// Get reference to clubs collection
  CollectionReference get _clubsCollection =>
      _firestore.collection(_clubsCollectionName);

  /// Create a new team with club-scoped permission enforcement
  ///
  /// Verifies that:
  /// 1. The creator has club_admin or college_admin role
  /// 2. The clubId exists in creator's adminClubs list (for club_admin)
  ///
  /// Parameters:
  /// - [clubId]: ID of the club this team belongs to
  /// - [name]: Name of the team
  /// - [description]: Description of the team
  /// - [creatorId]: ID of the user creating the team
  ///
  /// Returns: The document ID of the created team
  /// Throws: [FirebaseException] on failure
  /// Throws: [Exception] if user lacks permission
  Future<String> createTeam({
    required String clubId,
    required String name,
    required String description,
    required String creatorId,
  }) async {
    try {
      // Fetch user data to verify permissions
      final userDoc = await _usersCollection.doc(creatorId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String?;
      final adminClubs = userData['adminClubs'] != null
          ? List<String>.from(userData['adminClubs'] as List)
          : <String>[];

      // Verify user is club_admin or college_admin
      if (userRole != 'club_admin' && userRole != 'college_admin') {
        throw Exception(
          'Permission denied: Only club admins can create teams',
        );
      }

      // Verify clubId is in user's adminClubs (college_admins can create for any club)
      if (userRole == 'club_admin' && !adminClubs.contains(clubId)) {
        throw Exception(
          'Permission denied: You are not an admin of this club',
        );
      }

      // Verify club exists
      final clubDoc = await _clubsCollection.doc(clubId).get();
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      // Create team model
      final now = Timestamp.now();
      final team = TeamModel(
        id: '', // Will be set by Firestore
        clubId: clubId,
        name: name,
        description: description,
        headId: null, // Initially no head assigned
        memberCount: 0,
        isActive: true,
        createdBy: creatorId,
        createdAt: now,
        updatedAt: now,
      );

      // Create document with auto-generated ID
      final docRef = await _teamsCollection.add(team.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to create team: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('User not found') ||
          e.toString().contains('Club not found')) {
        rethrow;
      }
      throw Exception('Failed to create team: $e');
    }
  }

  /// Add a team head to a team with club-scoped permission enforcement
  ///
  /// Verifies that:
  /// 1. The promoter has club_admin or college_admin role
  /// 2. The team's clubId exists in promoter's adminClubs list (for club_admin)
  /// 3. The user has an approved membership in the team
  ///
  /// Updates:
  /// - team.headId (sets userId as the single team head)
  /// - team_memberships document (updates role to "team_head")
  ///
  /// Parameters:
  /// - [teamId]: ID of the team
  /// - [userId]: ID of the user to promote
  /// - [promoterId]: ID of the user performing the promotion
  ///
  /// Throws: [FirebaseException] on failure
  /// Throws: [Exception] if user lacks permission or membership doesn't exist
  Future<void> addTeamHead({
    required String teamId,
    required String userId,
    required String promoterId,
  }) async {
    try {
      // Fetch team data
      final teamDoc = await _teamsCollection.doc(teamId).get();

      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data() as Map<String, dynamic>;
      final clubId = teamData['clubId'] as String;

      // Fetch promoter data to verify permissions
      final promoterDoc = await _usersCollection.doc(promoterId).get();

      if (!promoterDoc.exists) {
        throw Exception('Promoter not found');
      }

      final promoterData = promoterDoc.data() as Map<String, dynamic>;
      final promoterRole = promoterData['role'] as String?;
      final adminClubs = promoterData['adminClubs'] != null
          ? List<String>.from(promoterData['adminClubs'] as List)
          : <String>[];

      // Verify promoter is club_admin or college_admin
      if (promoterRole != 'club_admin' && promoterRole != 'college_admin') {
        throw Exception(
          'Permission denied: Only club admins can promote team heads',
        );
      }

      // Verify clubId is in promoter's adminClubs (college_admins can promote in any club)
      if (promoterRole == 'club_admin' && !adminClubs.contains(clubId)) {
        throw Exception(
          'Permission denied: You are not an admin of this club',
        );
      }

      // Check if user has approved membership in the team
      final membershipQuery = await _teamMembershipsCollection
          .where('teamId', isEqualTo: teamId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (membershipQuery.docs.isEmpty) {
        throw Exception(
          'User does not have approved membership in this team',
        );
      }

      final membershipDoc = membershipQuery.docs.first;

      // Use transaction to update both team and membership
      await _firestore.runTransaction((transaction) async {
        // Update team headId with the single head
        transaction.update(
          _teamsCollection.doc(teamId),
          {
            'headId': userId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Update membership role
        transaction.update(
          _teamMembershipsCollection.doc(membershipDoc.id),
          {
            'role': 'team_head',
            'reviewedBy': promoterId,
            'reviewedAt': FieldValue.serverTimestamp(),
          },
        );
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to add team head: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('not found') ||
          e.toString().contains('membership')) {
        rethrow;
      }
      throw Exception('Failed to add team head: $e');
    }
  }

  /// Request team membership with validation to prevent multiple memberships
  ///
  /// Before creating a new membership request, verifies that the user does not
  /// already have any pending or approved memberships in any team.
  /// This enforces the rule: one team per user.
  ///
  /// Parameters:
  /// - [teamId]: ID of the team to join
  /// - [userId]: ID of the user requesting membership
  ///
  /// Returns: The document ID of the created membership request
  /// Throws: [Exception] if user already has a pending/approved membership
  /// Throws: [FirebaseException] on failure
  Future<String> requestTeamMembership({
    required String teamId,
    required String userId,
  }) async {
    try {
      // Check if user already has any pending or approved memberships
      final existingMemberships = await _teamMembershipsCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (existingMemberships.docs.isNotEmpty) {
        throw Exception(
          'You already have a pending or approved team membership. '
          'You can only be part of one team at a time.',
        );
      }

      // Verify team exists
      final teamDoc = await _teamsCollection.doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data() as Map<String, dynamic>;
      final clubId = teamData['clubId'] as String;

      // Create membership request
      final membership = TeamMembershipModel(
        id: '', // Will be set by Firestore
        teamId: teamId,
        clubId: clubId,
        userId: userId,
        role: 'member',
        status: 'pending',
        interviewStatus: 'not_scheduled',
        requestedAt: Timestamp.now(),
      );

      final docRef = await _teamMembershipsCollection.add(membership.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to request team membership: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('already have') ||
          e.toString().contains('Team not found')) {
        rethrow;
      }
      throw Exception('Failed to request team membership: $e');
    }
  }

  /// Get all teams for a specific club as a stream
  ///
  /// Parameters:
  /// - [clubId]: ID of the club
  ///
  /// Returns: Stream of list of TeamModel objects
  Stream<List<TeamModel>> getTeamsByClub(String clubId) {
    return _teamsCollection
        .where('clubId', isEqualTo: clubId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final teams = snapshot.docs
              .map((doc) => TeamModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();
          
          // Sort teams by createdAt in memory to avoid Firestore index requirement
          teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return teams;
        });
  }

  /// Get user's approved team membership as a stream
  ///
  /// Returns the user's approved team membership if they have one,
  /// or null if they don't have an approved membership.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  ///
  /// Returns: Stream of TeamMembershipModel or null
  Stream<TeamMembershipModel?> getUserApprovedMembership(String userId) {
    return _teamMembershipsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return TeamMembershipModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    });
  }
}
