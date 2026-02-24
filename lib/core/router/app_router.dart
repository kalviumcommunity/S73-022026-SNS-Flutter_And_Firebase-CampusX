import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/student_dashboard.dart';
import '../../features/dashboard/screens/club_dashboard.dart';
import '../../features/dashboard/screens/admin_dashboard.dart';
import '../../features/events/screens/event_list_screen.dart';
import '../../features/events/screens/event_details_screen.dart';
import '../../features/events/screens/create_event_screen.dart';
import '../../features/events/screens/event_registration_screen.dart';
import '../../features/admin/screens/role_requests_screen.dart';

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
        builder: (context, state) => const EventsListScreen(),
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
