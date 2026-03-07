import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/team_model.dart';
import '../../models/team_membership_model.dart';
import 'notification_service.dart';

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

      // Verify user is club_admin or college_admin
      if (userRole != 'club_admin' && userRole != 'college_admin') {
        throw Exception(
          'Permission denied: Only club admins can create teams',
        );
      }

      // Verify club exists and check admin permissions
      final clubDoc = await _clubsCollection.doc(clubId).get();
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      // Verify user is admin of this club by checking club's adminIds array (college_admins can create for any club)
      if (userRole == 'club_admin') {
        final clubData = clubDoc.data() as Map<String, dynamic>;
        final adminIds = clubData['adminIds'] != null
            ? List<String>.from(clubData['adminIds'] as List)
            : <String>[];

        if (!adminIds.contains(creatorId)) {
          throw Exception(
            'Permission denied: You are not an admin of this club',
          );
        }
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

      // Verify promoter is club_admin or college_admin
      if (promoterRole != 'club_admin' && promoterRole != 'college_admin') {
        throw Exception(
          'Permission denied: Only club admins can promote team heads',
        );
      }

      // Verify promoter is admin of this club by checking club's adminIds array (college_admins can promote in any club)
      if (promoterRole == 'club_admin') {
        final clubDoc = await _clubsCollection.doc(clubId).get();
        if (!clubDoc.exists) {
          throw Exception('Club not found');
        }

        final clubData = clubDoc.data() as Map<String, dynamic>;
        final adminIds = clubData['adminIds'] != null
            ? List<String>.from(clubData['adminIds'] as List)
            : <String>[];

        if (!adminIds.contains(promoterId)) {
          throw Exception(
            'Permission denied: You are not an admin of this club',
          );
        }
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

  /// Schedule an interview for a team membership request
  ///
  /// Parameters:
  /// - [membershipId]: ID of the membership request
  /// - [interviewDateTime]: Scheduled date and time for the interview
  ///
  /// Throws: [Exception] on failure
  Future<void> scheduleInterview({
    required String membershipId,
    required DateTime interviewDateTime,
  }) async {
    try {
      // Fetch membership data to get userId and teamId
      final membershipDoc = await _teamMembershipsCollection.doc(membershipId).get();
      
      if (!membershipDoc.exists) {
        throw Exception('Membership request not found');
      }
      
      final membershipData = membershipDoc.data() as Map<String, dynamic>;
      final userId = membershipData['userId'] as String?;
      final teamId = membershipData['teamId'] as String?;
      final clubId = membershipData['clubId'] as String?;
      
      // Update interview schedule
      await _teamMembershipsCollection.doc(membershipId).update({
        'interviewStatus': 'scheduled',
        'interviewScheduledAt': Timestamp.fromDate(interviewDateTime),
      });
      
      // Send push notification about scheduled interview
      if (userId != null && teamId != null) {
        try {
          // Fetch team name for notification
          final teamDoc = await _teamsCollection.doc(teamId).get();
          final teamName = teamDoc.exists 
              ? (teamDoc.data() as Map<String, dynamic>)['name'] as String? ?? 'the team'
              : 'the team';
          
          // Format the date and time
          final dateStr = '${interviewDateTime.day}/${interviewDateTime.month}/${interviewDateTime.year}';
          final timeStr = '${interviewDateTime.hour.toString().padLeft(2, '0')}:${interviewDateTime.minute.toString().padLeft(2, '0')}';
          
          final notificationService = NotificationService();
          await notificationService.sendNotificationToUser(
            userId: userId,
            title: 'Interview Scheduled',
            body: 'Your interview for $teamName is scheduled on $dateStr at $timeStr',
            type: NotificationType.interviewSchedule,
            data: {
              'membershipId': membershipId,
              'teamId': teamId,
              if (clubId != null) 'clubId': clubId,
              'interviewDateTime': interviewDateTime.toIso8601String(),
            },
          );
        } catch (e) {
          // Log error but don't fail interview scheduling
          print('Failed to send interview schedule notification: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to schedule interview: $e');
    }
  }

  /// Mark interview as completed with result
  ///
  /// Parameters:
  /// - [membershipId]: ID of the membership request
  /// - [result]: Interview result ('passed' or 'failed')
  /// - [notes]: Optional notes from the interviewer
  ///
  /// Throws: [Exception] on failure
  Future<void> markInterviewCompleted({
    required String membershipId,
    required String result,
    String? notes,
  }) async {
    try {
      if (result != 'passed' && result != 'failed') {
        throw Exception('Invalid interview result. Must be "passed" or "failed"');
      }

      await _teamMembershipsCollection.doc(membershipId).update({
        'interviewStatus': 'completed',
        'interviewResult': result,
        'interviewNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to mark interview as completed: $e');
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

  /// Get user's pending or approved membership
  ///
  /// Returns the user's membership if they have a pending or approved one,
  /// or null if they don't have any active membership request.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  ///
  /// Returns: Stream of TeamMembershipModel or null
  Stream<TeamMembershipModel?> getUserPendingOrApprovedMembership(String userId) {
    return _teamMembershipsCollection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'approved'])
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

  /// Get all pending membership requests for a club
  ///
  /// Parameters:
  /// - [clubId]: ID of the club
  ///
  /// Returns: Stream of list of membership requests with user details
  Stream<List<Map<String, dynamic>>> getPendingMembershipsByClub(String clubId) {
    return _teamMembershipsCollection
        .where('clubId', isEqualTo: clubId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      final memberships = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final membership = TeamMembershipModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        // Get user details
        final userDoc = await _usersCollection.doc(membership.userId).get();
        final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
        
        // Get team details
        final teamDoc = await _teamsCollection.doc(membership.teamId).get();
        final teamData = teamDoc.exists ? teamDoc.data() as Map<String, dynamic> : {};
        
        memberships.add({
          'membership': membership,
          'userName': userData['name'] ?? 'Unknown',
          'userEmail': userData['email'] ?? '',
          'teamName': teamData['name'] ?? 'Unknown Team',
        });
      }
      
      return memberships;
    });
  }

  /// Get all members of a specific team
  ///
  /// Parameters:
  /// - [teamId]: ID of the team
  ///
  /// Returns: Stream of list of team members with user details
  Stream<List<Map<String, dynamic>>> getTeamMembers(String teamId) {
    return _teamMembershipsCollection
        .where('teamId', isEqualTo: teamId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .asyncMap((snapshot) async {
      final members = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final membership = TeamMembershipModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        // Get user details
        final userDoc = await _usersCollection.doc(membership.userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          members.add({
            'membership': membership,
            'userId': membership.userId,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? '',
            'role': membership.role,
          });
        }
      }
      
      // Sort: team head first, then by name
      members.sort((a, b) {
        if (a['role'] == 'team_head' && b['role'] != 'team_head') return -1;
        if (a['role'] != 'team_head' && b['role'] == 'team_head') return 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });
      
      return members;
    });
  }

  /// Approve a team membership request
  ///
  /// Requires that the interview has been completed and the result is 'passed'
  ///
  /// Parameters:
  /// - [membershipId]: ID of the membership request
  /// - [reviewerId]: ID of the admin approving the request
  ///
  /// Throws: [FirebaseException] on failure
  Future<void> approveMembershipRequest({
    required String membershipId,
    required String reviewerId,
  }) async {
    try {
      String? userId;
      String? teamId;
      String? clubId;
      
      await _firestore.runTransaction((transaction) async {
        final membershipRef = _teamMembershipsCollection.doc(membershipId);
        final membershipDoc = await transaction.get(membershipRef);
        
        if (!membershipDoc.exists) {
          throw Exception('Membership request not found');
        }
        
        final membershipData = membershipDoc.data() as Map<String, dynamic>;
        
        // Store user and team info for notification
        userId = membershipData['userId'] as String?;
        teamId = membershipData['teamId'] as String?;
        clubId = membershipData['clubId'] as String?;
        
        // Check if interview is completed and passed
        final interviewStatus = membershipData['interviewStatus'] as String? ?? 'not_scheduled';
        final interviewResult = membershipData['interviewResult'] as String?;
        
        if (interviewStatus != 'completed' || interviewResult != 'passed') {
          throw Exception(
            'Cannot approve membership. Interview must be completed and passed first.',
          );
        }
        
        // Update membership status
        transaction.update(membershipRef, {
          'status': 'approved',
          'reviewedBy': reviewerId,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        
        // Increment team member count
        final teamRef = _teamsCollection.doc(teamId!);
        transaction.update(teamRef, {
          'memberCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Send push notification after successful approval
      if (userId != null && teamId != null) {
        try {
          // Fetch team name for notification
          final teamDoc = await _teamsCollection.doc(teamId).get();
          final teamName = teamDoc.exists 
              ? (teamDoc.data() as Map<String, dynamic>)['name'] as String? ?? 'the team'
              : 'the team';
          
          final notificationService = NotificationService();
          await notificationService.sendNotificationToUser(
            userId: userId!,
            title: 'Team Membership Approved',
            body: 'Congratulations! You have been approved to join $teamName',
            type: NotificationType.teamMembership,
            data: {
              'membershipId': membershipId,
              'teamId': teamId,
              if (clubId != null) 'clubId': clubId,
            },
          );
        } catch (e) {
          // Log error but don't fail approval
          print('Failed to send membership approval notification: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to approve membership: $e');
    }
  }

  /// Reject a team membership request
  ///
  /// Parameters:
  /// - [membershipId]: ID of the membership request
  /// - [reviewerId]: ID of the admin rejecting the request
  ///
  /// Throws: [FirebaseException] on failure
  Future<void> rejectMembershipRequest({
    required String membershipId,
    required String reviewerId,
  }) async {
    try {
      await _teamMembershipsCollection.doc(membershipId).update({
        'status': 'rejected',
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject membership: $e');
    }
  }

  /// Remove a team member
  ///
  /// Parameters:
  /// - [membershipId]: ID of the membership to remove
  ///
  /// Throws: [FirebaseException] on failure
  Future<void> removeTeamMember(String membershipId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final membershipRef = _teamMembershipsCollection.doc(membershipId);
        final membershipDoc = await transaction.get(membershipRef);
        
        if (!membershipDoc.exists) {
          throw Exception('Membership not found');
        }
        
        final membershipData = membershipDoc.data() as Map<String, dynamic>;
        final teamId = membershipData['teamId'] as String;
        final userId = membershipData['userId'] as String;
        
        // Check if this is the team head
        final teamRef = _teamsCollection.doc(teamId);
        final teamDoc = await transaction.get(teamRef);
        final teamData = teamDoc.data() as Map<String, dynamic>;
        
        // If removing the head, clear headId
        if (teamData['headId'] == userId) {
          transaction.update(teamRef, {
            'headId': null,
            'memberCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(teamRef, {
            'memberCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Delete membership
        transaction.delete(membershipRef);
      });
    } catch (e) {
      throw Exception('Failed to remove team member: $e');
    }
  }

  /// Remove team head status (demote to regular member)
  ///
  /// Parameters:
  /// - [teamId]: ID of the team
  /// - [membershipId]: ID of the membership to demote
  ///
  /// Throws: [FirebaseException] on failure
  Future<void> removeTeamHead({
    required String teamId,
    required String membershipId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update team to remove headId
        transaction.update(_teamsCollection.doc(teamId), {
          'headId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update membership role back to member
        transaction.update(_teamMembershipsCollection.doc(membershipId), {
          'role': 'member',
        });
      });
    } catch (e) {
      throw Exception('Failed to remove team head: $e');
    }
  }

  /// Get a team by ID
  ///
  /// Parameters:
  /// - [teamId]: ID of the team to fetch
  ///
  /// Returns: TeamModel or null if not found
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final doc = await _teamsCollection.doc(teamId).get();
      if (!doc.exists) {
        return null;
      }
      return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch team: $e');
    }
  }

  /// Search teams by name
  ///
  /// Note: Firestore doesn't support full-text search, so we fetch
  /// teams for the club and filter in-memory.
  ///
  /// Parameters:
  /// - [clubId]: ID of the club to search within
  /// - [query]: Search query string
  ///
  /// Returns: Stream of filtered teams
  Stream<List<TeamModel>> searchTeamsByName(String clubId, String query) {
    try {
      if (query.isEmpty) {
        return getTeamsByClub(clubId);
      }

      return getTeamsByClub(clubId).map((teams) {
        final lowerQuery = query.toLowerCase();
        return teams.where((team) {
          return team.name.toLowerCase().contains(lowerQuery) ||
              team.description.toLowerCase().contains(lowerQuery);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to search teams: $e');
    }
  }

  /// Get filtered teams
  ///
  /// Parameters:
  /// - [clubId]: Filter by club ID
  /// - [searchQuery]: Search in name and description
  ///
  /// Returns: Stream of filtered teams
  Stream<List<TeamModel>> getFilteredTeams({
    required String clubId,
    String? searchQuery,
  }) {
    try {
      Stream<List<TeamModel>> teamStream = getTeamsByClub(clubId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        teamStream = teamStream.map((teams) {
          final lowerQuery = searchQuery.toLowerCase();
          return teams.where((team) {
            return team.name.toLowerCase().contains(lowerQuery) ||
                team.description.toLowerCase().contains(lowerQuery);
          }).toList();
        });
      }

      return teamStream;
    } catch (e) {
      throw Exception('Failed to get filtered teams: $e');
    }
  }
}
