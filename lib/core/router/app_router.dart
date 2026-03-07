import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/student_dashboard.dart';
import '../../features/dashboard/screens/club_dashboard.dart';
import '../../features/dashboard/screens/admin_dashboard.dart';
import '../../features/events/screens/enhanced_event_list_screen.dart';
import '../../features/events/screens/event_details_screen.dart';
import '../../features/events/screens/create_event_screen.dart';
import '../../features/events/screens/event_registration_screen.dart';
import '../../features/events/screens/calendar_screen.dart';
import '../../features/admin/screens/role_requests_screen.dart';
import '../../features/admin/screens/manage_clubs_screen.dart';
import '../../features/admin/screens/enhanced_user_management_screen.dart';
import '../../features/admin/screens/analytics_screen.dart';
import '../../features/admin/screens/system_settings_screen.dart';
import '../../features/clubs/screens/club_list_screen.dart';
import '../../features/clubs/screens/club_profile_screen.dart';
import '../../features/teams/screens/enhanced_manage_teams_screen.dart';
import '../../features/teams/screens/team_details_screen.dart';
import '../../features/announcements/screens/create_announcement_screen.dart';
import '../../features/announcements/screens/enhanced_announcements_list_screen.dart';
import '../../features/events/screens/scan_attendance_screen.dart';
import '../../features/events/screens/attendance_list_screen.dart';
import '../../features/events/screens/student_attendance_screen.dart';
import '../../features/events/widgets/event_qr_screen_wrapper.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/view_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';

      // If not authenticated and not on login/signup, redirect to login
      if (!isAuthenticated && !isLoggingIn && !isSigningUp) {
        return '/login';
      }

      // If authenticated and on login/signup, redirect to appropriate dashboard
      if (isAuthenticated && (isLoggingIn || isSigningUp)) {
        final role = authState.user?.role;
        return _getDashboardRouteForRole(role);
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/student-dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/club-dashboard',
        name: 'club-dashboard',
        builder: (context, state) => const ClubDashboard(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EnhancedEventListScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/create-event',
        name: 'create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/event-detail/:id',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/event-registrations/:id',
        name: 'event-registrations',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventRegistrationsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/role-requests',
        name: 'role-requests',
        builder: (context, state) => const RoleRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/manage-clubs',
        name: 'admin-manage-clubs',
        builder: (context, state) => const ManageClubsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const EnhancedUserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: '/clubs',
        name: 'clubs',
        builder: (context, state) => const ClubListScreen(),
      ),
      GoRoute(
        path: '/clubs/:id',
        name: 'club-profile',
        builder: (context, state) {
          final clubId = state.pathParameters['id']!;
          return ClubProfileScreen(clubId: clubId);
        },
      ),
      GoRoute(
        path: '/manage-teams',
        name: 'manage-teams',
        builder: (context, state) => const EnhancedManageTeamsScreen(),
      ),
      GoRoute(
        path: '/teams/:id',
        name: 'team-details',
        builder: (context, state) {
          final teamId = state.pathParameters['id']!;
          return TeamDetailsScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/create-announcement',
        name: 'create-announcement',
        builder: (context, state) => const CreateAnnouncementScreen(),
      ),
      GoRoute(
        path: '/announcements/:clubId',
        name: 'announcements',
        builder: (context, state) {
          final clubId = state.pathParameters['clubId']!;
          return EnhancedAnnouncementsListScreen(clubId: clubId);
        },
      ),
      GoRoute(
        path: '/event-qr/:id',
        name: 'event-qr',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventQRScreenWrapper(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/scan-attendance',
        name: 'scan-attendance',
        builder: (context, state) => const ScanAttendanceScreen(),
      ),
      GoRoute(
        path: '/attendance-list/:id',
        name: 'attendance-list',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final manualParam = state.uri.queryParameters['manual'];
          final showManual = manualParam == 'true';
          
          return AttendanceListScreen(
            eventId: eventId,
            showManualMark: showManual,
          );
        },
      ),
      GoRoute(
        path: '/my-attendance',
        name: 'my-attendance',
        builder: (context, state) => const StudentAttendanceScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/view-profile/:id',
        name: 'view-profile',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return ViewProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
    ],
  );
});

/// Helper function to get dashboard route based on user role
String _getDashboardRouteForRole(String? role) {
  switch (role) {
    case 'student':
      return '/student-dashboard';
    case 'club_admin':
      return '/club-dashboard';
    case 'college_admin':
      return '/admin-dashboard';
    default:
      return '/login';
  }
}

/// Provider to get current dashboard route for user's role
final dashboardRouteProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return _getDashboardRouteForRole(user?.role);
});
