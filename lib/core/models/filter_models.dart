import 'package:equatable/equatable.dart';

/// Event filter options
enum EventTimeFilter {
  all,
  upcoming,
  past,
}

enum EventRegistrationFilter {
  all,
  registered,
  notRegistered,
  waitlisted,
}

/// Event filter state
class EventFilters extends Equatable {
  final EventTimeFilter timeFilter;
  final EventRegistrationFilter registrationFilter;
  final String? clubId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  const EventFilters({
    this.timeFilter = EventTimeFilter.all,
    this.registrationFilter = EventRegistrationFilter.all,
    this.clubId,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  EventFilters copyWith({
    EventTimeFilter? timeFilter,
    EventRegistrationFilter? registrationFilter,
    String? clubId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return EventFilters(
      timeFilter: timeFilter ?? this.timeFilter,
      registrationFilter: registrationFilter ?? this.registrationFilter,
      clubId: clubId ?? this.clubId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  EventFilters clearClubFilter() {
    return copyWith(clubId: '');
  }

  EventFilters clearDateRange() {
    return EventFilters(
      timeFilter: timeFilter,
      registrationFilter: registrationFilter,
      clubId: clubId,
      searchQuery: searchQuery,
    );
  }

  bool get hasActiveFilters {
    return timeFilter != EventTimeFilter.all ||
        registrationFilter != EventRegistrationFilter.all ||
        clubId != null ||
        startDate != null ||
        endDate != null ||
        searchQuery.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        timeFilter,
        registrationFilter,
        clubId,
        startDate,
        endDate,
        searchQuery,
      ];
}

/// Announcement filter options
enum AnnouncementDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
}

class AnnouncementFilters extends Equatable {
  final AnnouncementDateFilter dateFilter;
  final String? teamId;
  final String searchQuery;

  const AnnouncementFilters({
    this.dateFilter = AnnouncementDateFilter.all,
    this.teamId,
    this.searchQuery = '',
  });

  AnnouncementFilters copyWith({
    AnnouncementDateFilter? dateFilter,
    String? teamId,
    String? searchQuery,
  }) {
    return AnnouncementFilters(
      dateFilter: dateFilter ?? this.dateFilter,
      teamId: teamId ?? this.teamId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  AnnouncementFilters clearTeamFilter() {
    return copyWith(teamId: '');
  }

  bool get hasActiveFilters {
    return dateFilter != AnnouncementDateFilter.all ||
        teamId != null ||
        searchQuery.isNotEmpty;
  }

  @override
  List<Object?> get props => [dateFilter, teamId, searchQuery];
}

/// Team filter options
class TeamFilters extends Equatable {
  final String searchQuery;
  final String? clubId;

  const TeamFilters({
    this.searchQuery = '',
    this.clubId,
  });

  TeamFilters copyWith({
    String? searchQuery,
    String? clubId,
  }) {
    return TeamFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      clubId: clubId ?? this.clubId,
    );
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty || clubId != null;
  }

  @override
  List<Object?> get props => [searchQuery, clubId];
}

/// User search filters
enum UserRoleFilter {
  all,
  student,
  clubAdmin,
  collegeAdmin,
}

class UserFilters extends Equatable {
  final String searchQuery;
  final UserRoleFilter roleFilter;
  final String? clubId;

  const UserFilters({
    this.searchQuery = '',
    this.roleFilter = UserRoleFilter.all,
    this.clubId,
  });

  UserFilters copyWith({
    String? searchQuery,
    UserRoleFilter? roleFilter,
    String? clubId,
  }) {
    return UserFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      clubId: clubId ?? this.clubId,
    );
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        roleFilter != UserRoleFilter.all ||
        clubId != null;
  }

  @override
  List<Object?> get props => [searchQuery, roleFilter, clubId];
}
