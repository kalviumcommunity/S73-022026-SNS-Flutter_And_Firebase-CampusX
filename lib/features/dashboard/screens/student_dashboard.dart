import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../providers/role_request_provider.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final roleRequestState = ref.watch(roleRequestOperationsProvider);
    final membershipAsync = ref.watch(userTeamMembershipProvider);
    final userClubAsync = ref.watch(userClubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${user?.name ?? 'Student'}!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Student Dashboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Role: ${user?.role ?? 'N/A'}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('Browse Events'),
                        subtitle: const Text('Find and register for events'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/events');
                        },
                      ),
                      const Divider(),
                      // Show club section based on membership status
                      membershipAsync.when(
                        data: (membership) {
                          if (membership != null) {
                            // User has approved membership - show My Club
                            return userClubAsync.when(
                              data: (club) {
                                if (club == null) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.star),
                                      title: const Text('My Club'),
                                      subtitle: Text(club.name),
                                      trailing:
                                          const Icon(Icons.arrow_forward_ios),
                                      onTap: () {
                                        context.push('/clubs/${club.id}');
                                      },
                                    ),
                                    const Divider(),
                                  ],
                                );
                              },
                              loading: () => const ListTile(
                                leading: Icon(Icons.star),
                                title: Text('My Club'),
                                subtitle: Text('Loading...'),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          } else {
                            // User doesn't have membership - show Discover Clubs
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.explore),
                                  title: const Text('Discover Clubs'),
                                  subtitle: const Text(
                                      'Find and join clubs on campus'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    context.push('/clubs');
                                  },
                                ),
                                const Divider(),
                              ],
                            );
                          }
                        },
                        loading: () => const Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.groups),
                              title: Text('Clubs'),
                              subtitle: Text('Loading...'),
                            ),
                            Divider(),
                          ],
                        ),
                        error: (_, __) => const Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.groups),
                              title: Text('Clubs'),
                              subtitle: Text('Error loading club information'),
                            ),
                            Divider(),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Announcements'),
                        subtitle: const Text('View latest announcements'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navigate to announcements
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: roleRequestState.isLoading
                      ? null
                      : () => _requestClubAdminAccess(context, ref, user?.uid),
                  icon: roleRequestState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.admin_panel_settings),
                  label: Text(
                    roleRequestState.isLoading
                        ? 'Submitting Request...'
                        : 'Request Club Admin Access',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle club admin access request
  void _requestClubAdminAccess(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref
        .read(roleRequestOperationsProvider.notifier)
        .requestRoleUpgrade(userId);

    if (context.mounted) {
      final state = ref.read(roleRequestOperationsProvider);
      
      if (success && state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (!success && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Clear messages after showing
      ref.read(roleRequestOperationsProvider.notifier).clearMessages();
    }
  }
}
