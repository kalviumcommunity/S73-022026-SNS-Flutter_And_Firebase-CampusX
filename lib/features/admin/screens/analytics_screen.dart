import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

/// Provider for platform statistics
final platformStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  
  final usersCount = await firestore.collection('users').count().get();
  final clubsCount = await firestore.collection('clubs').count().get();
  final teamsCount = await firestore.collection('teams').count().get();
  final eventsCount = await firestore.collection('events').count().get();
  
  return {
    'users': usersCount.count ?? 0,
    'clubs': clubsCount.count ?? 0,
    'teams': teamsCount.count ?? 0,
    'events': eventsCount.count ?? 0,
  };
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(platformStatsProvider);
            },
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Statistics',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overview of your campus platform',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _StatCard(
                        title: 'Total Users',
                        count: stats['users'] ?? 0,
                        icon: Icons.people,
                        color: theme.colorScheme.primary,
                        subtitle: 'Registered users',
                      ),
                      _StatCard(
                        title: 'Active Clubs',
                        count: stats['clubs'] ?? 0,
                        icon: Icons.groups,
                        color: theme.colorScheme.secondary,
                        subtitle: 'Student organizations',
                      ),
                      _StatCard(
                        title: 'Teams',
                        count: stats['teams'] ?? 0,
                        icon: Icons.people_outline,
                        color: theme.colorScheme.tertiary,
                        subtitle: 'Club teams',
                      ),
                      _StatCard(
                        title: 'Events',
                        count: stats['events'] ?? 0,
                        icon: Icons.event,
                        color: Colors.orange,
                        subtitle: 'Total events',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity Section
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.people,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: const Text('View All Users'),
                          subtitle: Text('${stats['users']} registered users'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push('/admin/users');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.groups,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          title: const Text('Manage Clubs'),
                          subtitle: Text('${stats['clubs']} active clubs'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.push('/admin/manage-clubs');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(platformStatsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
