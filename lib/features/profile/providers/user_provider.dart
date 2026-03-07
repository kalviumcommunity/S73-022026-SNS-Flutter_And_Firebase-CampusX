import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/user_service.dart';
import '../../../models/user_model.dart';

/// Provider for UserService instance
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Provider for user stream by ID
final userStreamProvider = StreamProvider.autoDispose.family<UserModel?, String>((ref, userId) {
  final service = ref.watch(userServiceProvider);
  return service.getUserStream(userId);
});

/// Provider for user future by ID
final userFutureProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, userId) {
  final service = ref.watch(userServiceProvider);
  return service.getUserById(userId);
});

/// State for profile operations
enum ProfileOperationStatus {
  idle,
  loading,
  success,
  error,
}

class ProfileOperationState {
  final ProfileOperationStatus status;
  final String? errorMessage;
  final String? successMessage;

  const ProfileOperationState({
    this.status = ProfileOperationStatus.idle,
    this.errorMessage,
    this.successMessage,
  });

  ProfileOperationState copyWith({
    ProfileOperationStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProfileOperationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Notifier for profile operations
class ProfileOperationsNotifier extends StateNotifier<ProfileOperationState> {
  final UserService _userService;

  ProfileOperationsNotifier(this._userService) : super(const ProfileOperationState());

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? phone,
  }) async {
    state = state.copyWith(status: ProfileOperationStatus.loading);

    try {
      await _userService.updateProfile(
        userId: userId,
        name: name,
        bio: bio,
        phone: phone,
      );

      state = state.copyWith(
        status: ProfileOperationStatus.success,
        successMessage: 'Profile updated successfully',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileOperationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    state = state.copyWith(status: ProfileOperationStatus.loading);

    try {
      final url = await _userService.uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
      );

      state = state.copyWith(
        status: ProfileOperationStatus.success,
        successMessage: 'Photo uploaded successfully',
      );

      return url;
    } catch (e) {
      state = state.copyWith(
        status: ProfileOperationStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    state = state.copyWith(status: ProfileOperationStatus.loading);

    try {
      await _userService.deleteProfilePhoto(userId);

      state = state.copyWith(
        status: ProfileOperationStatus.success,
        successMessage: 'Photo removed successfully',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileOperationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    required String userId,
    bool? showEmail,
    bool? showPhone,
  }) async {
    state = state.copyWith(status: ProfileOperationStatus.loading);

    try {
      await _userService.updatePrivacySettings(
        userId: userId,
        showEmail: showEmail,
        showPhone: showPhone,
      );

      state = state.copyWith(
        status: ProfileOperationStatus.success,
        successMessage: 'Privacy settings updated',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileOperationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(status: ProfileOperationStatus.loading);

    try {
      await _userService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(
        status: ProfileOperationStatus.success,
        successMessage: 'Password changed successfully',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileOperationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const ProfileOperationState();
  }
}

/// Provider for profile operations
final profileOperationsProvider = StateNotifierProvider<ProfileOperationsNotifier, ProfileOperationState>((ref) {
  final service = ref.watch(userServiceProvider);
  return ProfileOperationsNotifier(service);
});
