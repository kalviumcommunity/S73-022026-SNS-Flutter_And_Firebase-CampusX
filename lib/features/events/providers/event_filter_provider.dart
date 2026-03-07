import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/filter_models.dart';
import '../../../models/event_model.dart';
import '../../../models/registration_model.dart';
import '../../events/providers/event_provider.dart';
import '../../events/providers/registration_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for event filters state
final eventFiltersProvider = StateProvider<EventFilters>((ref) {
  return const EventFilters();
});

/// Provider for filtered events based on current filter state
final filteredEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final filters = ref.watch(eventFiltersProvider);
  final eventService = ref.watch(eventServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  // Determine time filter
  bool? isUpcoming;
  if (filters.timeFilter == EventTimeFilter.upcoming) {
    isUpcoming = true;
  } else if (filters.timeFilter == EventTimeFilter.past) {
    isUpcoming = false;
  }

  // Get filtered events stream
  final eventStream = eventService.getFilteredEvents(
    clubId: filters.clubId,
    startDate: filters.startDate,
    endDate: filters.endDate,
    isUpcoming: isUpcoming,
    searchQuery: filters.searchQuery.isEmpty ? null : filters.searchQuery,
  );

  // Apply registration filter if user is logged in
  if (currentUser != null &&
      filters.registrationFilter != EventRegistrationFilter.all) {
    return eventStream.asyncMap((events) async {
      final filtered = <EventModel>[];

      for (final event in events) {
        final registration = await ref
            .read(registrationServiceProvider)
            .checkIfUserRegistered(event.id, currentUser.uid);

        final matchesFilter = _matchesRegistrationFilter(
          registration,
          filters.registrationFilter,
        );

        if (matchesFilter) {
          filtered.add(event);
        }
      }

      return filtered;
    });
  }

  return eventStream;
});

/// Helper function to check if registration status matches filter
bool _matchesRegistrationFilter(
  RegistrationModel? registration,
  EventRegistrationFilter filter,
) {
  switch (filter) {
    case EventRegistrationFilter.all:
      return true;
    case EventRegistrationFilter.registered:
      return registration != null && registration.status == 'confirmed';
    case EventRegistrationFilter.notRegistered:
      return registration == null;
    case EventRegistrationFilter.waitlisted:
      return registration != null && registration.status == 'waitlisted';
  }
}

/// Provider for event search results count
final filteredEventsCountProvider = Provider<int>((ref) {
  final eventsAsync = ref.watch(filteredEventsProvider);
  return eventsAsync.maybeWhen(
    data: (events) => events.length,
    orElse: () => 0,
  );
});

/// Helper to reset all event filters
extension EventFiltersExtension on StateController<EventFilters> {
  void reset() {
    state = const EventFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTimeFilter(EventTimeFilter filter) {
    state = state.copyWith(timeFilter: filter);
  }

  void setRegistrationFilter(EventRegistrationFilter filter) {
    state = state.copyWith(registrationFilter: filter);
  }

  void setClubFilter(String? clubId) {
    if (clubId == null || clubId.isEmpty) {
      state = state.clearClubFilter();
    } else {
      state = state.copyWith(clubId: clubId);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void clearDateRange() {
    state = state.clearDateRange();
  }
}
