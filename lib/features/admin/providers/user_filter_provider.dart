import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/user_service.dart';
import '../../../core/models/filter_models.dart';
import '../../../models/user_model.dart';

/// Provider for user filter state
final userFiltersProvider = StateProvider<UserFilters>((ref) {
  return UserFilters();
});

/// Provider for filtered users
final filteredUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final userService = ref.watch(userServiceProvider);
  final filters = ref.watch(userFiltersProvider);

  // Determine role filter value
  String? roleFilter;
  switch (filters.roleFilter) {
    case UserRoleFilter.student:
      roleFilter = 'student';
      break;
    case UserRoleFilter.clubAdmin:
      roleFilter = 'club_admin';
      break;
    case UserRoleFilter.collegeAdmin:
      roleFilter = 'college_admin';
      break;
    case UserRoleFilter.all:
      roleFilter = null;
      break;
  }

  return userService.getFilteredUsers(
    searchQuery: filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
    role: roleFilter,
    clubId: filters.clubId,
  );
});

/// Provider for filtered users count
final filteredUsersCountProvider = Provider<int>((ref) {
  final usersAsync = ref.watch(filteredUsersProvider);
  return usersAsync.when(
    data: (users) => users.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for user service
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Extension methods for easier filter updates
extension UserFiltersNotifierExtension on StateController<UserFilters> {
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRoleFilter(UserRoleFilter filter) {
    state = state.copyWith(roleFilter: filter);
  }

  void setClubFilter(String? clubId) {
    state = state.copyWith(clubId: clubId);
  }

  void reset() {
    state = UserFilters();
  }
}
