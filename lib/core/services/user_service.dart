import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/notification_preferences.dart';

/// Service class for user operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'users';

  /// Get reference to users collection
  CollectionReference get _usersCollection =>
      _firestore.collection(_collectionName);

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to get user: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get stream of user data
  Stream<UserModel?> getUserStream(String userId) {
    try {
      return _usersCollection.doc(userId).snapshots().map((doc) {
        if (!doc.exists) {
          return null;
        }
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      });
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// Update user profile information
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      
      if (updates.isEmpty) return;
      
      await _usersCollection.doc(userId).update(updates);
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to update profile: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Upload profile photo and update user document
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Create a reference to the storage location
      final storageRef = _storage.ref().child('profile_photos/$userId.jpg');
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update user document with new photo URL
      await _usersCollection.doc(userId).update({
        'profilePhotoUrl': downloadUrl,
      });
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to upload photo: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      // Delete from storage
      final storageRef = _storage.ref().child('profile_photos/$userId.jpg');
      await storageRef.delete();
      
      // Update user document
      await _usersCollection.doc(userId).update({
        'profilePhotoUrl': null,
      });
    } on FirebaseException catch (e) {
      // Ignore if file doesn't exist
      if (e.code != 'object-not-found') {
        throw FirebaseException(
          plugin: e.plugin,
          code: e.code,
          message: 'Failed to delete photo: ${e.message}',
        );
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    required String userId,
    bool? showEmail,
    bool? showPhone,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (showEmail != null) updates['showEmail'] = showEmail;
      if (showPhone != null) updates['showPhone'] = showPhone;
      
      if (updates.isEmpty) return;
      
      await _usersCollection.doc(userId).update(updates);
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to update privacy settings: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      }
      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get all users (admin only)
  Stream<List<UserModel>> getAllUsers() {
    try {
      return _usersCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Search users by name or email
  ///
  /// Note: Firestore doesn't support full-text search, so we fetch
  /// all users and filter in-memory. For production with many users,
  /// consider using Algolia or ElasticSearch.
  ///
  /// Parameters:
  /// - [query]: Search query string
  ///
  /// Returns: Stream of filtered users
  Stream<List<UserModel>> searchUsers(String query) {
    try {
      if (query.isEmpty) {
        return getAllUsers();
      }

      return getAllUsers().map((users) {
        final lowerQuery = query.toLowerCase();
        return users.where((user) {
          return user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get filtered users with advanced filtering
  ///
  /// Parameters:
  /// - [searchQuery]: Search in name and email
  /// - [role]: Filter by user role
  /// - [clubId]: Filter by club membership/admin
  ///
  /// Returns: Stream of filtered users
  Stream<List<UserModel>> getFilteredUsers({
    String? searchQuery,
    String? role,
    String? clubId,
  }) {
    try {
      Stream<List<UserModel>> userStream = getAllUsers();

      return userStream.map((users) {
        var filtered = users;

        // Filter by role
        if (role != null && role.isNotEmpty) {
          filtered = filtered.where((user) => user.role == role).toList();
        }

        // Filter by club
        if (clubId != null && clubId.isNotEmpty) {
          filtered = filtered.where((user) {
            return user.joinedClubs.contains(clubId) ||
                user.adminClubs.contains(clubId);
          }).toList();
        }

        // Filter by search query
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final lowerQuery = searchQuery.toLowerCase();
          filtered = filtered.where((user) {
            return user.name.toLowerCase().contains(lowerQuery) ||
                user.email.toLowerCase().contains(lowerQuery);
          }).toList();
        }

        // Sort by name
        filtered.sort((a, b) => a.name.compareTo(b.name));

        return filtered;
      });
    } catch (e) {
      throw Exception('Failed to get filtered users: $e');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required String userId,
    required NotificationPreferences preferences,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'notificationPreferences': preferences.toMap(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to update notification preferences: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Update FCM token for user
  Future<void> updateFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to update FCM token: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
