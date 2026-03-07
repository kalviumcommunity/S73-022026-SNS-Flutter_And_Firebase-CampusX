import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/announcement_model.dart';
import 'notification_service.dart';

/// Service for managing announcements in Firestore
class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _announcementsCollection;
  late final CollectionReference _clubsCollection;
  late final CollectionReference _usersCollection;

  AnnouncementService() {
    _announcementsCollection = _firestore.collection('announcements');
    _clubsCollection = _firestore.collection('clubs');
    _usersCollection = _firestore.collection('users');
  }

  /// Create a new announcement with permission checks
  Future<String> createAnnouncement(AnnouncementModel announcement, String creatorId) async {
    try {
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
          'Permission denied: Only club admins can post announcements',
        );
      }

      // Verify user is admin of this club by checking club's adminIds array
      final clubDoc = await _clubsCollection.doc(announcement.clubId).get();
      
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
      final docRef = await _announcementsCollection.add(announcement.toMap());
      
      // Send push notification to club members
      try {
        final notificationService = NotificationService();
        await notificationService.sendNotificationToTopic(
          topic: 'club_${announcement.clubId}',
          title: 'New Announcement',
          body: announcement.title,
          type: NotificationType.announcement,
          data: {
            'announcementId': docRef.id,
            'clubId': announcement.clubId,
          },
        );
      } catch (e) {
        // Log error but don't fail announcement creation
        print('Failed to send announcement notification: $e');
      }
      
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to create announcement: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('User not found') ||
          e.toString().contains('Club not found')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred while creating announcement: $e');
    }
  }

  /// Get all announcements for a specific club
  Stream<List<AnnouncementModel>> getAnnouncementsByClub(String clubId) {
    try {
      return _announcementsCollection
          .where('clubId', isEqualTo: clubId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final announcements = snapshot.docs.map((doc) {
          return AnnouncementModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
        
        // Sort: pinned first, then by date (descending)
        announcements.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        
        return announcements;
      });
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  /// Get a single announcement by ID
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    try {
      final doc = await _announcementsCollection.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return AnnouncementModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to fetch announcement: $e');
    }
  }

  /// Update an announcement (admin only)
  Future<void> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    try {
      // Get announcement to verify ownership
      final announcementDoc = await _announcementsCollection.doc(announcementId).get();
      
      if (!announcementDoc.exists) {
        throw Exception('Announcement not found');
      }

      final announcementData = announcementDoc.data() as Map<String, dynamic>;
      final clubId = announcementData['clubId'] as String;

      // Verify user is admin of the club
      final clubDoc = await _clubsCollection.doc(clubId).get();
      
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubData = clubDoc.data() as Map<String, dynamic>;
      final adminIds = clubData['adminIds'] != null
          ? List<String>.from(clubData['adminIds'] as List)
          : <String>[];

      if (!adminIds.contains(userId)) {
        throw Exception('Permission denied: You are not an admin of this club');
      }

      // Add updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _announcementsCollection.doc(announcementId).update(updates);
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  /// Delete an announcement (soft delete by setting isActive to false)
  Future<void> deleteAnnouncement(String announcementId, String userId) async {
    try {
      await updateAnnouncement(
        announcementId,
        {'isActive': false},
        userId,
      );
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  /// Toggle pin status of an announcement
  Future<void> togglePin(String announcementId, String userId) async {
    try {
      final announcement = await getAnnouncementById(announcementId);
      
      if (announcement == null) {
        throw Exception('Announcement not found');
      }

      await updateAnnouncement(
        announcementId,
        {'isPinned': !announcement.isPinned},
        userId,
      );
    } catch (e) {
      throw Exception('Failed to toggle pin: $e');
    }
  }

  /// Get filtered announcements with advanced filtering
  ///
  /// Parameters:
  /// - [clubId]: Filter by club ID
  /// - [teamId]: Filter by team ID
  /// - [startDate]: Filter announcements on or after this date
  /// - [endDate]: Filter announcements on or before this date
  /// - [searchQuery]: Search in title and content
  ///
  /// Returns: Stream of filtered announcements
  Stream<List<AnnouncementModel>> getFilteredAnnouncements({
    required String clubId,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    try {
      Stream<List<AnnouncementModel>> announcementStream =
          getAnnouncementsByClub(clubId);

      return announcementStream.map((announcements) {
        var filtered = announcements;

        // Filter by team
        if (teamId != null && teamId.isNotEmpty) {
          filtered = filtered.where((announcement) {
            return announcement.teamId == teamId;
          }).toList();
        }

        // Filter by date range
        if (startDate != null) {
          filtered = filtered.where((announcement) {
            return announcement.createdAt.isAfter(startDate) ||
                announcement.createdAt.isAtSameMomentAs(startDate);
          }).toList();
        }

        if (endDate != null) {
          final endOfDay = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          filtered = filtered.where((announcement) {
            return announcement.createdAt.isBefore(endOfDay) ||
                announcement.createdAt.isAtSameMomentAs(endOfDay);
          }).toList();
        }

        // Filter by search query
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final lowerQuery = searchQuery.toLowerCase();
          filtered = filtered.where((announcement) {
            return announcement.title.toLowerCase().contains(lowerQuery) ||
                announcement.content.toLowerCase().contains(lowerQuery);
          }).toList();
        }

        return filtered;
      });
    } catch (e) {
      throw Exception('Failed to get filtered announcements: $e');
    }
  }

  /// Search announcements by query
  ///
  /// Parameters:
  /// - [clubId]: Club ID to search within
  /// - [query]: Search query string
  ///
  /// Returns: Stream of matching announcements
  Stream<List<AnnouncementModel>> searchAnnouncements(
    String clubId,
    String query,
  ) {
    try {
      if (query.isEmpty) {
        return getAnnouncementsByClub(clubId);
      }

      return getAnnouncementsByClub(clubId).map((announcements) {
        final lowerQuery = query.toLowerCase();
        return announcements.where((announcement) {
          return announcement.title.toLowerCase().contains(lowerQuery) ||
              announcement.content.toLowerCase().contains(lowerQuery);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to search announcements: $e');
    }
  }
}
