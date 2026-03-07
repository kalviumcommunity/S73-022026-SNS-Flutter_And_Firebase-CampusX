import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/announcement_service.dart';
import '../../../core/models/filter_models.dart';
import '../../../models/announcement_model.dart';

/// Provider for announcement filter state by club
final announcementFiltersProvider = StateProvider.family<AnnouncementFilters, String>((ref, clubId) {
  return AnnouncementFilters();
});

/// Provider for filtered announcements
final filteredAnnouncementsProvider = StreamProvider.family<List<AnnouncementModel>, String>((ref, clubId) {
  final announcementService = ref.watch(announcementServiceProvider);
  final filters = ref.watch(announcementFiltersProvider(clubId));

  DateTime? startDate;
  DateTime? endDate;

  // Apply date filter presets
  final now = DateTime.now();
  switch (filters.dateFilter) {
    case AnnouncementDateFilter.today:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case AnnouncementDateFilter.thisWeek:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
      break;
    case AnnouncementDateFilter.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case AnnouncementDateFilter.all:
      startDate = null;
      endDate = null;
      break;
  }

  return announcementService.getFilteredAnnouncements(
    clubId: clubId,
    teamId: filters.teamId,
    startDate: startDate,
    endDate: endDate,
    searchQuery: filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
  );
});

/// Provider for filtered announcements count
final filteredAnnouncementsCountProvider = Provider.family<int, String>((ref, clubId) {
  final announcementsAsync = ref.watch(filteredAnnouncementsProvider(clubId));
  return announcementsAsync.when(
    data: (announcements) => announcements.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for announcement service
final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService();
});

/// Extension methods for easier filter updates
extension AnnouncementFiltersNotifierExtension on StateController<AnnouncementFilters> {
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateFilter(AnnouncementDateFilter filter) {
    state = state.copyWith(dateFilter: filter);
  }

  void setTeamFilter(String? teamId) {
    state = state.copyWith(teamId: teamId);
  }

  void reset() {
    state = AnnouncementFilters();
  }
}
