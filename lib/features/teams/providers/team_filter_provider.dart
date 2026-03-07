import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/team_service.dart';
import '../../../core/models/filter_models.dart';
import '../../../models/team_model.dart';

/// Provider for team filter state
final teamFiltersProvider = StateProvider.family<TeamFilters, String>((ref, clubId) {
  return TeamFilters();
});

/// Provider for filtered teams
final filteredTeamsProvider = StreamProvider.family<List<TeamModel>, String>((ref, clubId) {
  final teamService = ref.watch(teamServiceProvider);
  final filters = ref.watch(teamFiltersProvider(clubId));

  return teamService.getFilteredTeams(
    clubId: clubId,
    searchQuery: filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
  );
});

/// Provider for filtered teams count
final filteredTeamsCountProvider = Provider.family<int, String>((ref, clubId) {
  final teamsAsync = ref.watch(filteredTeamsProvider(clubId));
  return teamsAsync.when(
    data: (teams) => teams.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for team service
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService();
});

/// Extension methods for easier filter updates
extension TeamFiltersNotifierExtension on StateController<TeamFilters> {
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = TeamFilters();
  }
}
