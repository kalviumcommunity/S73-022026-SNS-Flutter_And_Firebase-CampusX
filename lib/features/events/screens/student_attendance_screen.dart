import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/services/event_service.dart';
import '../../../models/event_model.dart';
import '../providers/attendance_provider.dart';

/// Screen for viewing student's attendance history
class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Attendance',
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
        body: const Center(child: Text('Please log in to view attendance')),
      );
    }

    final attendancesAsync = ref.watch(attendancesByUserProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Attendance',
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
        elevation: 0,
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
      body: attendancesAsync.when(
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
                'Error loading attendance',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (attendances) {
          if (attendances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No attendance records yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your attendance for attended events will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Calculate stats
          final presentCount = attendances.where((a) => a.status == 'present').length;
          final totalCount = attendances.length;
          final attendanceRate = totalCount > 0 
              ? ((presentCount / totalCount) * 100).toStringAsFixed(1) 
              : '0.0';

          return Column(
            children: [
              // Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Attendance Rate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          attendanceRate,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(
                          'Total Events',
                          totalCount.toString(),
                          Icons.event,
                          theme,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                        ),
                        _buildStat(
                          'Present',
                          presentCount.toString(),
                          Icons.check_circle,
                          theme,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                        ),
                        _buildStat(
                          'Absent',
                          (totalCount - presentCount).toString(),
                          Icons.cancel,
                          theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Attendance List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendances.length,
                  itemBuilder: (context, index) {
                    final attendance = attendances[index];
                    return _AttendanceCard(attendance: attendance);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onPrimaryContainer,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Widget for individual attendance card
class _AttendanceCard extends ConsumerWidget {
  final dynamic attendance;

  const _AttendanceCard({required this.attendance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<EventModel?>(
      future: EventService().getEventById(attendance.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              title: const Text('Loading...'),
            ),
          );
        }

        final event = snapshot.data!;
        final isPresent = attendance.status == 'present';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Could navigate to event details
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPresent 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Event Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(event.date),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Chip(
                        label: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: isPresent 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Additional Info
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      if (attendance.markedAt != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Marked: ${_formatDateTime(attendance.markedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, hh:mm a').format(dateTime);
  }
}
