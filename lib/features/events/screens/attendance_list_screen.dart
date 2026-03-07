import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../models/registration_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/club_service.dart';
import '../providers/registration_provider.dart';
import '../providers/attendance_provider.dart';

/// Screen for viewing and managing event attendance
class AttendanceListScreen extends ConsumerStatefulWidget {
  final String eventId;
  final bool showManualMark;

  const AttendanceListScreen({
    super.key,
    required this.eventId,
    this.showManualMark = false,
  });

  @override
  ConsumerState<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all, present, absent, not_marked
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registrationsAsync = ref.watch(registrationsByEventProvider(widget.eventId));
    final attendancesAsync = ref.watch(attendancesByEventProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show QR Code',
            onPressed: () {
              context.pop(); // Go back to QR screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Present', 'present'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Absent', 'absent'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Not Marked', 'not_marked'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Attendance List
          Expanded(
            child: registrationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
                      'Error loading registrations',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              data: (registrations) {
                if (registrations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No registrations yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter confirmed registrations only
                final confirmedRegistrations = registrations
                    .where((r) => r.status == 'confirmed')
                    .toList();

                return attendancesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading attendance')),
                  data: (attendances) {
                    // Create a map of userId -> attendance status
                    final attendanceMap = {
                      for (var a in attendances) a.userId: a.status
                    };

                    // Filter registrations based on search and filter
                    var filteredRegistrations = confirmedRegistrations;

                    // Apply filter
                    if (_filter == 'present') {
                      filteredRegistrations = filteredRegistrations
                          .where((r) => attendanceMap[r.userId] == 'present')
                          .toList();
                    } else if (_filter == 'absent') {
                      filteredRegistrations = filteredRegistrations
                          .where((r) => attendanceMap[r.userId] == 'absent')
                          .toList();
                    } else if (_filter == 'not_marked') {
                      filteredRegistrations = filteredRegistrations
                          .where((r) => !attendanceMap.containsKey(r.userId))
                          .toList();
                    }

                    return Column(
                      children: [
                        // Stats Summary
                        _buildStatsSummary(
                          confirmedRegistrations.length,
                          attendances.where((a) => a.status == 'present').length,
                          attendances.where((a) => a.status == 'absent').length,
                          theme,
                        ),

                        // List
                        Expanded(
                          child: filteredRegistrations.isEmpty
                              ? Center(
                                  child: Text(
                                    'No students found',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredRegistrations.length,
                                  padding: const EdgeInsets.all(16),
                                  itemBuilder: (context, index) {
                                    final registration = filteredRegistrations[index];
                                    final attendanceStatus = attendanceMap[registration.userId];

                                    return _buildAttendanceItem(
                                      registration,
                                      attendanceStatus,
                                      theme,
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      showCheckmark: false,
    );
  }

  Widget _buildStatsSummary(int total, int present, int absent, ThemeData theme) {
    final notMarked = total - present - absent;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total, Icons.people, theme.colorScheme.primary),
          _buildStatItem('Present', present, Icons.check_circle, Colors.green),
          _buildStatItem('Absent', absent, Icons.cancel, Colors.red),
          _buildStatItem('Not Marked', notMarked, Icons.help_outline, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(
    RegistrationModel registration,
    String? attendanceStatus,
    ThemeData theme,
  ) {
    return FutureBuilder<UserModel?>(
      future: UserService().getUserById(registration.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Loading...'),
            ),
          );
        }

        final user = snapshot.data!;
        final userName = user.name.toLowerCase();

        // Apply search filter
        if (_searchQuery.isNotEmpty && !userName.contains(_searchQuery)) {
          return const SizedBox.shrink();
        }

        IconData statusIcon;
        Color statusColor;
        String statusText;

        if (attendanceStatus == 'present') {
          statusIcon = Icons.check_circle;
          statusColor = Colors.green;
          statusText = 'Present';
        } else if (attendanceStatus == 'absent') {
          statusIcon = Icons.cancel;
          statusColor = Colors.red;
          statusText = 'Absent';
        } else {
          statusIcon = Icons.help_outline;
          statusColor = Colors.orange;
          statusText = 'Not Marked';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  avatar: Icon(statusIcon, size: 16, color: statusColor),
                  label: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'present',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Mark Present'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'absent',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Mark Absent'),
                        ],
                      ),
                    ),
                    if (attendanceStatus != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Clear Status'),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    _handleAttendanceAction(value, registration, user);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAttendanceAction(
    String action,
    RegistrationModel registration,
    UserModel user,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Get club service to verify admin permissions
    final clubService = ClubService();
    final club = await clubService.getClubById(registration.clubId);
    
    if (club == null || !club.adminIds.contains(currentUser.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to mark attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (action == 'delete') {
        await ref.read(attendanceOperationsProvider.notifier).deleteAttendance(
          eventId: widget.eventId,
          userId: registration.userId,
        );
      } else {
        await ref.read(attendanceOperationsProvider.notifier).markAttendance(
          eventId: widget.eventId,
          userId: registration.userId,
          clubId: registration.clubId,
          adminId: currentUser.uid,
          isPresent: action == 'present',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'delete'
                  ? 'Attendance cleared for ${user.name}'
                  : 'Marked ${user.name} as $action',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
