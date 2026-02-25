import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/event_service.dart';
import '../../../models/event_model.dart';

/// Provider for EventService instance
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

/// StreamProvider for all events
/// 
/// Provides real-time stream of all events in the system
/// Automatically handles loading and error states
final allEventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getAllEvents();
});

/// Family StreamProvider for events by club ID
/// 
/// Provides real-time stream of events for a specific club
/// Usage: ref.watch(eventsByClubProvider('clubId123'))
final eventsByClubProvider =
    StreamProvider.family<List<EventModel>, String>((ref, clubId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByClub(clubId);
});

/// Family StreamProvider for events by creator ID
/// 
/// Provides real-time stream of events created by a specific user
/// Usage: ref.watch(eventsByCreatorProvider('userId123'))
final eventsByCreatorProvider =
    StreamProvider.family<List<EventModel>, String>((ref, creatorId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByCreator(creatorId);
});

/// StreamProvider for upcoming events
/// 
/// Provides real-time stream of events that haven't happened yet
final upcomingEventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getUpcomingEvents();
});

/// StreamProvider for past events
/// 
/// Provides real-time stream of events that have already occurred
final pastEventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getPastEvents();
});

/// State class for event operations
class EventOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const EventOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  EventOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return EventOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// StateNotifier for handling event create, update, and delete operations
/// 
/// Manages loading and error states for mutations
/// Does not manage event list state (handled by StreamProviders)
class EventOperationsNotifier extends StateNotifier<EventOperationState> {
  final EventService _eventService;

  EventOperationsNotifier(this._eventService)
      : super(const EventOperationState());

  /// Create a new event
  /// 
  /// Parameters:
  /// - [event]: EventModel to create
  /// 
  /// Returns: Created event ID on success, null on failure
  Future<String?> createEvent(EventModel event, String creatorId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final eventId = await _eventService.createEvent(event, creatorId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event created successfully',
      );
      return eventId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update an existing event
  /// 
  /// Parameters:
  /// - [event]: EventModel with updated data
  Future<bool> updateEvent(EventModel event) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _eventService.updateEvent(event);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event updated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete an event
  /// 
  /// Parameters:
  /// - [eventId]: ID of event to delete
  Future<bool> deleteEvent(String eventId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _eventService.deleteEvent(eventId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event deleted successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear any error or success messages
  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }
}

/// Provider for EventOperationsNotifier
/// 
/// Use this for create, update, and delete operations
/// Example:
/// ```dart
/// final eventId = await ref.read(eventOperationsProvider.notifier)
///     .createEvent(newEvent);
/// ```
final eventOperationsProvider =
    StateNotifierProvider<EventOperationsNotifier, EventOperationState>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return EventOperationsNotifier(eventService);
});

/// FutureProvider for getting a single event by ID
/// 
/// Usage: ref.watch(eventByIdProvider('eventId123'))
final eventByIdProvider =
    FutureProvider.family<EventModel?, String>((ref, eventId) async {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventById(eventId);
});
