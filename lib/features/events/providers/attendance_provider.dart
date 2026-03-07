import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/attendance_service.dart';
import '../../../models/attendance_model.dart';

/// Provider for AttendanceService instance
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

/// Family StreamProvider for attendances by event ID
/// 
/// Provides real-time stream of all attendance records for a specific event
/// Usage: ref.watch(attendancesByEventProvider('eventId123'))
final attendancesByEventProvider =
    StreamProvider.family<List<AttendanceModel>, String>((ref, eventId) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return attendanceService.getAttendancesForEvent(eventId);
});

/// Family StreamProvider for present attendances by event ID
/// 
/// Provides real-time stream of present attendance records only
/// Usage: ref.watch(presentAttendancesProvider('eventId123'))
final presentAttendancesProvider =
    StreamProvider.family<List<AttendanceModel>, String>((ref, eventId) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return attendanceService.getPresentAttendances(eventId);
});

/// Family StreamProvider for present count by event ID
/// 
/// Provides real-time count of present attendees
/// Usage: ref.watch(presentCountProvider('eventId123'))
final presentCountProvider =
    StreamProvider.family<int, String>((ref, eventId) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return attendanceService.getPresentCountStream(eventId);
});

/// Family StreamProvider for attendances by user ID
/// 
/// Provides real-time stream of all attendance records for a specific user
/// Usage: ref.watch(attendancesByUserProvider('userId123'))
final attendancesByUserProvider =
    StreamProvider.family<List<AttendanceModel>, String>((ref, userId) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return attendanceService.getAttendancesForUser(userId);
});

/// State class for attendance operations
class AttendanceOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AttendanceOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AttendanceOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AttendanceOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// StateNotifier for managing attendance operations
class AttendanceOperationsNotifier extends StateNotifier<AttendanceOperationState> {
  final AttendanceService _attendanceService;

  AttendanceOperationsNotifier(this._attendanceService)
      : super(const AttendanceOperationState());

  /// Mark attendance for a user
  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String clubId,
    required String adminId,
    required bool isPresent,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _attendanceService.markAttendance(
        eventId: eventId,
        userId: userId,
        clubId: clubId,
        adminId: adminId,
        isPresent: isPresent,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: isPresent
            ? 'Attendance marked as present'
            : 'Attendance marked as absent',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Delete attendance record
  Future<void> deleteAttendance({
    required String eventId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _attendanceService.deleteAttendance(eventId, userId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Attendance record deleted',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }
}

/// Provider for attendance operations
final attendanceOperationsProvider =
    StateNotifierProvider<AttendanceOperationsNotifier, AttendanceOperationState>(
  (ref) {
    final attendanceService = ref.watch(attendanceServiceProvider);
    return AttendanceOperationsNotifier(attendanceService);
  },
);
