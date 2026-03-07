import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/announcement_service.dart';
import '../../../models/announcement_model.dart';

/// Provider for AnnouncementService instance
final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService();
});

/// StreamProvider for announcements by club
final announcementsByClubProvider = StreamProvider.family<List<AnnouncementModel>, String>((ref, clubId) {
  final service = ref.watch(announcementServiceProvider);
  return service.getAnnouncementsByClub(clubId);
});

/// State for announcement operations
class AnnouncementOperationState {
  final bool isLoading;
  final String? error;

  const AnnouncementOperationState({
    this.isLoading = false,
    this.error,
  });

  AnnouncementOperationState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AnnouncementOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for announcement operations (create, update, delete)
class AnnouncementOperationsNotifier extends StateNotifier<AnnouncementOperationState> {
  final AnnouncementService _service;

  AnnouncementOperationsNotifier(this._service) : super(const AnnouncementOperationState());

  /// Create a new announcement
  Future<String?> createAnnouncement(AnnouncementModel announcement, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final announcementId = await _service.createAnnouncement(announcement, userId);
      state = state.copyWith(isLoading: false);
      return announcementId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Update an announcement
  Future<bool> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.updateAnnouncement(announcementId, updates, userId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(String announcementId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.deleteAnnouncement(announcementId, userId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Toggle pin status
  Future<bool> togglePin(String announcementId, String userId) async {
    try {
      await _service.togglePin(announcementId, userId);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Provider for announcement operations
final announcementOperationsProvider =
    StateNotifierProvider<AnnouncementOperationsNotifier, AnnouncementOperationState>((ref) {
  final service = ref.watch(announcementServiceProvider);
  return AnnouncementOperationsNotifier(service);
});
