import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/club_model.dart';

class ClubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _clubsCollection => _firestore.collection('clubs');

  /// Get a club by its ID
  Future<ClubModel?> getClubById(String clubId) async {
    try {
      final doc = await _clubsCollection.doc(clubId).get();
      if (!doc.exists) {
        return null;
      }
      return ClubModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch club: $e');
    }
  }

  /// Get all active clubs as a stream
  Stream<List<ClubModel>> getActiveClubs() {
    try {
      return _clubsCollection
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final clubs = snapshot.docs
            .map((doc) => ClubModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        // Sort clubs by name in memory to avoid Firestore index requirement
        clubs.sort((a, b) => a.name.compareTo(b.name));
        return clubs;
      });
    } catch (e) {
      throw Exception('Failed to fetch active clubs: $e');
    }
  }

  /// Get clubs where user is an admin
  Stream<List<ClubModel>> getClubsByAdmin(String adminId) {
    try {
      return _clubsCollection
          .where('adminIds', arrayContains: adminId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final clubs = snapshot.docs
            .map((doc) => ClubModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        // Sort clubs by name in memory to avoid Firestore index requirement
        clubs.sort((a, b) => a.name.compareTo(b.name));
        return clubs;
      });
    } catch (e) {
      throw Exception('Failed to fetch admin clubs: $e');
    }
  }

  /// Update club member count
  Future<void> updateMemberCount(String clubId, int count) async {
    try {
      await _clubsCollection.doc(clubId).update({
        'memberCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update member count: $e');
    }
  }

  /// Activate or deactivate a club
  Future<void> setClubActiveStatus(String clubId, bool isActive) async {
    try {
      await _clubsCollection.doc(clubId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update club status: $e');
    }
  }
}
