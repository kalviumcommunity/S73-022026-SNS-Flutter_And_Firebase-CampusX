import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../core/models/filter_models.dart';
import '../providers/user_filter_provider.dart';

class EnhancedUserManagementScreen extends ConsumerStatefulWidget {
  const EnhancedUserManagementScreen({super.key});

  @override
  ConsumerState<EnhancedUserManagementScreen> createState() => _EnhancedUserManagementScreenState();
}

class _EnhancedUserManagementScreenState extends ConsumerState<EnhancedUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(userFiltersProvider);
    _searchController.text = currentFilters.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(userFiltersProvider.notifier).setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(filteredUsersProvider);
    final filters = ref.watch(userFiltersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black38,
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFF06B6D4),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filters.roleFilter == UserRoleFilter.all,
                  onSelected: (_) {
                    ref.read(userFiltersProvider.notifier).setRoleFilter(UserRoleFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Students'),
                  selected: filters.roleFilter == UserRoleFilter.student,
                  onSelected: (_) {
                    ref.read(userFiltersProvider.notifier).setRoleFilter(UserRoleFilter.student);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Club Admins'),
                  selected: filters.roleFilter == UserRoleFilter.clubAdmin,
                  onSelected: (_) {
                    ref.read(userFiltersProvider.notifier).setRoleFilter(UserRoleFilter.clubAdmin);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('College Admins'),
                  selected: filters.roleFilter == UserRoleFilter.collegeAdmin,
                  onSelected: (_) {
                    ref.read(userFiltersProvider.notifier).setRoleFilter(UserRoleFilter.collegeAdmin);
                  },
                ),
                if (filters.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    onPressed: () {
                      ref.read(userFiltersProvider.notifier).reset();
                      _searchController.clear();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Users List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filters.hasActiveFilters ? Icons.search_off : Icons.people_outline,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filters.hasActiveFilters ? 'No users found' : 'No Users Found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (filters.hasActiveFilters)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Try adjusting your search or filters',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // Group users by role for statistics
                final students = users.where((u) => u.role == 'student').toList();
                final clubAdmins = users.where((u) => u.role == 'club_admin').toList();
                final collegeAdmins = users.where((u) => u.role == 'college_admin').toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Statistics Cards
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Users',
                                count: users.length,
                                icon: Icons.people,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Students',
                                count: students.length,
                                icon: Icons.school,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // User List by Role
                      if (collegeAdmins.isNotEmpty) ...[
                        _RoleSection(
                          title: 'College Admins',
                          users: collegeAdmins,
                          icon: Icons.shield,
                          color: theme.colorScheme.error,
                        ),
                      ],
                      
                      if (clubAdmins.isNotEmpty) ...[
                        _RoleSection(
                          title: 'Club Admins',
                          users: clubAdmins,
                          icon: Icons.admin_panel_settings,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                      
                      if (students.isNotEmpty) ...[
                        _RoleSection(
                          title: 'Students',
                          users: students,
                          icon: Icons.school,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
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
                      'Error loading users',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSection extends ConsumerWidget {
  final String title;
  final List<UserModel> users;
  final IconData icon;
  final Color color;

  const _RoleSection({
    required this.title,
    required this.users,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                '$title (${users.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  backgroundImage: user.profilePhotoUrl != null 
                      ? NetworkImage(user.profilePhotoUrl!)
                      : null,
                  child: user.profilePhotoUrl == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.email),
                    if (user.adminClubs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Admin of ${user.adminClubs.length} club(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/view-profile/${user.uid}');
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
