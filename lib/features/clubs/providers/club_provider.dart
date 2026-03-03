import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/club_service.dart';
import '../../../core/services/team_service.dart';
import '../../../models/club_model.dart';
import '../../../models/team_model.dart';
import '../../../models/team_membership_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for ClubService instance
final clubServiceProvider = Provider<ClubService>((ref) {
  return ClubService();
});

/// Provider for TeamService instance
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService();
});

/// StreamProvider for all active clubs
///
/// Provides real-time stream of all active clubs in the system
/// Automatically handles loading and error states
final activeClubsStreamProvider = StreamProvider<List<ClubModel>>((ref) {
  final clubService = ref.watch(clubServiceProvider);
  return clubService.getActiveClubs();
});

/// StreamProvider for user's approved team membership
///
/// Returns the user's approved team membership if they have one,
/// or null if they don't have an approved membership.
/// This determines if the user is a club member.
final userTeamMembershipProvider =
    StreamProvider<TeamMembershipModel?>((ref) {
  final authState = ref.watch(authProvider);
  final teamService = ref.watch(teamServiceProvider);

  final userId = authState.user?.uid;
  if (userId == null) {
    return Stream.value(null);
  }

  return teamService.getUserApprovedMembership(userId);
});

/// StreamProvider for user's pending or approved team membership
///
/// Returns the user's membership if they have a pending or approved one.
/// Use this to show application status including interview details.
final userMembershipWithStatusProvider =
    StreamProvider<TeamMembershipModel?>((ref) {
  final authState = ref.watch(authProvider);
  final teamService = ref.watch(teamServiceProvider);

  final userId = authState.user?.uid;
  if (userId == null) {
    return Stream.value(null);
  }

  return teamService.getUserPendingOrApprovedMembership(userId);
});

/// FutureProvider for user's club
///
/// Returns the club that the user is a member of based on their
/// approved team membership, or null if they don't have a membership.
final userClubProvider = FutureProvider<ClubModel?>((ref) async {
  final membershipAsync = ref.watch(userTeamMembershipProvider);

  return membershipAsync.when(
    data: (membership) async {
      if (membership == null) {
        return null;
      }

      final clubService = ref.read(clubServiceProvider);
      return await clubService.getClubById(membership.clubId);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Family StreamProvider for teams by club ID
///
/// Provides real-time stream of teams for a specific club
/// Usage: ref.watch(teamsByClubProvider('clubId123'))
final teamsByClubProvider =
    StreamProvider.family<List<dynamic>, String>((ref, clubId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamsByClub(clubId);
});

/// FutureProvider for user's team
///
/// Returns the team that the user is a member of based on their
/// approved team membership, or null if they don't have a membership.
final userTeamProvider = FutureProvider<TeamModel?>((ref) async {
  final membershipAsync = ref.watch(userTeamMembershipProvider);

  return membershipAsync.when(
    data: (membership) async {
      if (membership == null) {
        return null;
      }

      final teamService = ref.read(teamServiceProvider);
      return await teamService.getTeamById(membership.teamId);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
