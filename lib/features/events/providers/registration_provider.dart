import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/registration_service.dart';
import '../../../core/services/event_service.dart';
import '../../../models/registration_model.dart';
import '../../../models/event_model.dart';

/// Provider for RegistrationService instance
final registrationServiceProvider = Provider<RegistrationService>((ref) {
  return RegistrationService();
});

/// Provider for user's registration status for a specific event
final userRegistrationProvider = FutureProvider.autoDispose
    .family<RegistrationModel?, (String eventId, String userId)>(
  (ref, params) async {
    final eventId = params.$1;
    final userId = params.$2;
    final service = ref.watch(registrationServiceProvider);
    
    return await service.checkIfUserRegistered(eventId, userId);
  },
);

/// Provider for registration count (registered users only)
final registrationCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, eventId) {
  final service = ref.watch(registrationServiceProvider);
  return service.getRegistrationCountStream(eventId);
});

/// Provider for waitlist count
final waitlistCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, eventId) {
  final service = ref.watch(registrationServiceProvider);
  return service.getWaitlistCountStream(eventId);
});

/// Provider for registered users list (admin view)
/// 
/// Returns real-time stream of all registered users for an event.
/// Useful for admin dashboards to view confirmed attendees.
final registeredUsersProvider = StreamProvider.autoDispose
    .family<List<RegistrationModel>, String>((ref, eventId) {
  final service = ref.watch(registrationServiceProvider);
  return service.getRegisteredUsers(eventId);
});

/// Provider for waitlisted users list (admin view)
/// 
/// Returns real-time stream of all waitlisted users for an event.
/// Useful for admin dashboards to manage waitlist.
final waitlistedUsersProvider = StreamProvider.autoDispose
    .family<List<RegistrationModel>, String>((ref, eventId) {
  final service = ref.watch(registrationServiceProvider);
  return service.getWaitlistedUsers(eventId);
});

/// Provider for user's registrations
/// 
/// Returns stream of all registrations for a user
final userRegistrationsProvider = StreamProvider.autoDispose
    .family<List<RegistrationModel>, String>((ref, userId) {
  final service = ref.watch(registrationServiceProvider);
  return service.getRegistrationsForUser(userId);
});

/// Provider for user's registered events with event data
/// 
/// Returns stream of events that the user is registered for (registered or waitlisted)
/// Combines registration data with actual event information
final userRegisteredEventsProvider = StreamProvider.autoDispose
    .family<List<EventModel>, String>((ref, userId) async* {
  final registrationService = ref.watch(registrationServiceProvider);
  final eventService = EventService();
  
  await for (final registrations in registrationService.getRegistrationsForUser(userId)) {
    // Fetch event data for each registration
    final events = <EventModel>[];
    
    for (final registration in registrations) {
      try {
        final event = await eventService.getEventById(registration.eventId);
        if (event != null) {
          events.add(event);
        }
      } catch (e) {
        // Skip events that can't be fetched (might be deleted)
        continue;
      }
    }
    
    yield events;
  }
});

/// State class for managing registration operations
class RegistrationOperationsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const RegistrationOperationsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  RegistrationOperationsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return RegistrationOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for handling registration operations
class RegistrationOperationsNotifier
    extends StateNotifier<RegistrationOperationsState> {
  final RegistrationService _service;
  final Ref _ref;

  RegistrationOperationsNotifier(this._service, this._ref)
      : super(const RegistrationOperationsState());

  /// Register user for an event
  Future<bool> registerForEvent(
    String eventId,
    String clubId,
    String userId,
  ) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final registrationId =
          await _service.registerForEvent(eventId, clubId, userId);

      // Check the registration status to determine success message
      final registration =
          await _service.checkIfUserRegistered(eventId, userId);

      final message = registration?.status == 'registered'
          ? 'Successfully registered for event!'
          : 'Event is full. You have been added to the waitlist.';

      state = state.copyWith(
        isLoading: false,
        successMessage: message,
      );

      // Invalidate providers to refresh data
      _ref.invalidate(userRegistrationProvider);
      _ref.invalidate(registrationCountProvider);
      _ref.invalidate(waitlistCountProvider);
      _ref.invalidate(registeredUsersProvider);
      _ref.invalidate(waitlistedUsersProvider);

      return registrationId.isNotEmpty;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Cancel user's registration
  Future<bool> cancelRegistration(String eventId, String userId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.cancelRegistration(eventId, userId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Registration cancelled successfully',
      );

      // Invalidate providers to refresh data
      _ref.invalidate(userRegistrationProvider);
      _ref.invalidate(registrationCountProvider);
      _ref.invalidate(waitlistCountProvider);
      _ref.invalidate(registeredUsersProvider);
      _ref.invalidate(waitlistedUsersProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Provider for registration operations
final registrationOperationsProvider = StateNotifierProvider<
    RegistrationOperationsNotifier, RegistrationOperationsState>((ref) {
  final service = ref.watch(registrationServiceProvider);
  return RegistrationOperationsNotifier(service, ref);
});
