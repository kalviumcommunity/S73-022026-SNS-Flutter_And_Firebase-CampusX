import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/role_request_service.dart';
import '../../../models/role_request_model.dart';

/// Provider for RoleRequestService instance
final roleRequestServiceProvider = Provider<RoleRequestService>((ref) {
  return RoleRequestService();
});

/// StreamProvider for pending role requests
/// 
/// Provides real-time stream of all pending role upgrade requests
/// Automatically handles loading and error states
final pendingRoleRequestsProvider = StreamProvider<List<RoleRequestModel>>((ref) {
  final service = ref.watch(roleRequestServiceProvider);
  return service.getPendingRequests();
});

/// State class for role request operations
class RoleRequestOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const RoleRequestOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  RoleRequestOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return RoleRequestOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// StateNotifier for handling role request operations
/// 
/// Manages loading and error states for request, approve, and reject operations
class RoleRequestOperationsNotifier extends StateNotifier<RoleRequestOperationState> {
  final RoleRequestService _service;

  RoleRequestOperationsNotifier(this._service)
      : super(const RoleRequestOperationState());

  /// Request a role upgrade to club_admin
  /// 
  /// Parameters:
  /// - [userId]: The ID of the user requesting the upgrade
  /// 
  /// Returns: true on success, false on failure
  Future<bool> requestRoleUpgrade(String userId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.requestRoleUpgrade(userId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Role upgrade request submitted successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Approve a role upgrade request
  /// 
  /// Parameters:
  /// - [requestId]: The ID of the request to approve
  /// - [adminId]: The ID of the admin approving the request
  /// 
  /// Returns: true on success, false on failure
  Future<bool> approveRequest(String requestId, String adminId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.approveRequest(requestId, adminId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Request approved successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reject a role upgrade request
  /// 
  /// Parameters:
  /// - [requestId]: The ID of the request to reject
  /// - [adminId]: The ID of the admin rejecting the request
  /// 
  /// Returns: true on success, false on failure
  Future<bool> rejectRequest(String requestId, String adminId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.rejectRequest(requestId, adminId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Request rejected successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Clear success and error messages
  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }
}

/// StateNotifierProvider for role request operations
final roleRequestOperationsProvider =
    StateNotifierProvider<RoleRequestOperationsNotifier, RoleRequestOperationState>((ref) {
  final service = ref.watch(roleRequestServiceProvider);
  return RoleRequestOperationsNotifier(service);
});
